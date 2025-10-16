import 'dart:io';  // Para saída no console
import 'package:http/http.dart' as http;  // Biblioteca para requisições HTTP

void main() async {
  // URL do site a ser acessado (exemplo simples)
  const String url = 'https://example.com';

  try {
    // Faz a requisição GET
    final response = await http.get(Uri.parse(url));

    // Verifica se a requisição foi bem-sucedida (código 200)
    if (response.statusCode == 200) {
      print('Site acessado com sucesso!');
      print('Código de status: ${response.statusCode}');
      print('Corpo da resposta:');
      print(response.body);  // Imprime o HTML ou conteúdo do site
    } else {
      print('Erro ao acessar o site. Código de status: ${response.statusCode}');
    }
  } catch (e) {
    print('Exceção ao fazer a requisição: $e');
  }
}