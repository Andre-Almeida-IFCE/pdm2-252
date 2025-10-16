import 'dart:io';
import 'dart:convert';  // Para utf8.decode()

void main() async {
  const int port = 8080;
  const String host = 'localhost';  // Para escuta local

  print('Iniciando servidor na porta $port...');

  try {
    // Cria o ServerSocket assíncrono
    final server = await ServerSocket.bind(host, port);
    print('Servidor escutando em $host:$port');

    // Escuta conexões indefinidamente
    await for (final socket in server) {
      print('Cliente conectado: ${socket.remoteAddress.address}:${socket.remotePort}');

      // Escuta dados assincronamente do socket
      socket.listen(
        (List<int> data) {
          final message = utf8.decode(data).trim();  // Decodifica bytes para string
          if (message.isNotEmpty) {
            print('Temperatura recebida: $message');
          }
        },
        onError: (error) {
          print('Erro na conexão: $error');
          socket.destroy();
        },
        onDone: () {
          print('Cliente desconectado.');
          socket.destroy();
        },
      );
    }
  } catch (e) {
    print('Erro ao iniciar servidor: $e');
  }
}