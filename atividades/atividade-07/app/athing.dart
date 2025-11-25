import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

final _authorizationEndpoint =
    Uri.parse('https://github.com/login/oauth/authorize');
final _tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');

// For web platform, use a fixed callback URL
// You'll need to set this in your GitHub OAuth app settings
final _webRedirectUrl = Uri.parse('http://localhost:5000/auth');

class GithubLoginWidget extends StatefulWidget {
  const GithubLoginWidget({
    required this.builder,
    required this.githubClientId,
    required this.githubClientSecret,
    required this.githubScopes,
    super.key,
  });
  final AuthenticatedBuilder builder;
  final String githubClientId;
  final String githubClientSecret;
  final List<String> githubScopes;

  @override
  State<GithubLoginWidget> createState() => _GithubLoginState();
}

typedef AuthenticatedBuilder = Widget Function(
    BuildContext context, oauth2.Client client);

class _GithubLoginState extends State<GithubLoginWidget> {
  HttpServer? _redirectServer;
  oauth2.Client? _client;

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client != null) {
      return widget.builder(context, client);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Github Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  // Check if we're on web or native platform
                  bool isWeb = false;
                  try {
                    HttpServer.bind('localhost', 0);
                  } catch (e) {
                    isWeb = true;
                  }

                  if (isWeb) {
                    await _loginWeb();
                  } else {
                    await _loginNative();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Login to Github'),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'For Web: After authorizing on GitHub, you\'ll need to manually copy the authorization code from the URL and paste it here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginWeb() async {
    // For web, we can't bind to localhost
    // Instead, we just open the authorization URL
    var grant = oauth2.AuthorizationCodeGrant(
      widget.githubClientId,
      _authorizationEndpoint,
      _tokenEndpoint,
      secret: widget.githubClientSecret,
      httpClient: _JsonAcceptingHttpClient(),
    );
    
    var authorizationUrl =
        grant.getAuthorizationUrl(_webRedirectUrl, scopes: widget.githubScopes);

    print('DEBUG (Web): Authorization URL: $authorizationUrl');
    
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(authorizationUrl, mode: LaunchMode.externalApplication);
      
      // Show a dialog asking for the code
      if (mounted) {
        _showCodeInputDialog(grant);
      }
    } else {
      throw GithubLoginException('Could not launch $authorizationUrl');
    }
  }

  Future<void> _loginNative() async {
    await _redirectServer?.close();
    // Bind to an ephemeral port on localhost
    _redirectServer = await HttpServer.bind('localhost', 0);
    final redirectUrl = Uri.parse('http://localhost:${_redirectServer!.port}/auth');
    
    var authenticatedHttpClient = await _getOAuth2Client(redirectUrl);
    setState(() {
      _client = authenticatedHttpClient;
    });
  }

  void _showCodeInputDialog(oauth2.AuthorizationCodeGrant grant) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter GitHub Authorization Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'After authorizing GitHub you will be redirected to a URL like:\n'
              'http://localhost:5000/auth?code=...&state=...\n\n'
              'Copy the entire URL from the browser address bar and paste it here.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Paste full redirect URL here',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = codeController.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please paste the full redirect URL')),
                );
                return;
              }

              try {
                // If user pasted a full URL, parse out the query parameters
                Map<String, String> responseQueryParameters;
                if (input.startsWith('http')) {
                  final uri = Uri.parse(input);
                  responseQueryParameters = Map.from(uri.queryParameters);
                } else {
                  // If they pasted only a query string or code, try to handle it
                  if (input.contains('=')) {
                    // naive parse of key=val&...
                    responseQueryParameters = Map.fromEntries(input.split('&').map((p) {
                      final parts = p.split('=');
                      return MapEntry(parts[0], parts.length > 1 ? parts.sublist(1).join('=') : '');
                    }));
                  } else {
                    responseQueryParameters = {'code': input};
                  }
                }

                print('DEBUG: responseQueryParameters from dialog: $responseQueryParameters');

                var client = await grant.handleAuthorizationResponse(responseQueryParameters);

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _client = client;
                  });
                }
              } catch (e, st) {
                print('ERROR during handleAuthorizationResponse: $e');
                print(st);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error during token exchange: $e')),
                  );
                }
              }
            },
            child: const Text('Authorize'),
          ),
        ],
      ),
    );
  }

  Future<oauth2.Client> _getOAuth2Client(Uri redirectUrl) async {
    if (widget.githubClientId.isEmpty || widget.githubClientSecret.isEmpty) {
      throw const GithubLoginException(
          'githubClientId and githubClientSecret must be not empty. '
          'See `lib/github_oauth_credentials.dart` for more detail.');
    }
    print('DEBUG: Using redirect URL: $redirectUrl');
    print('DEBUG: Client ID: ${widget.githubClientId}');
    
    var grant = oauth2.AuthorizationCodeGrant(
      widget.githubClientId,
      _authorizationEndpoint,
      _tokenEndpoint,
      secret: widget.githubClientSecret,
      httpClient: _JsonAcceptingHttpClient(),
    );
    var authorizationUrl =
        grant.getAuthorizationUrl(redirectUrl, scopes: widget.githubScopes);

    print('DEBUG: Authorization URL: $authorizationUrl');
    await _redirect(authorizationUrl);
    var responseQueryParameters = await _listen();
    print('DEBUG: Response parameters: $responseQueryParameters');
    var client =
        await grant.handleAuthorizationResponse(responseQueryParameters);
    return client;
  }

  Future<void> _redirect(Uri authorizationUrl) async {
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(authorizationUrl);
    } else {
      throw GithubLoginException('Could not launch $authorizationUrl');
    }
  }

  Future<Map<String, String>> _listen() async {
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');
    request.response.writeln('Authenticated! You can close this tab.');
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;
    return params;
  }
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

class GithubLoginException implements Exception {
  const GithubLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}