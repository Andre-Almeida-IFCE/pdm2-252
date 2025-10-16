import 'dart:io';
import 'dart:async';
import 'dart:math';  // Para Random

void main() async {
  const String host = 'localhost';
  const int port = 8080;
  const Duration interval = Duration(seconds: 10);  // A cada 10 segundos
  const Duration totalDuration = Duration(seconds: 60);  // Simula por 1 minuto (ajuste se quiser infinito)

  print('Iniciando simulação de dispositivo IoT...');

  try {
    // Conecta ao servidor assincronamente
    final socket = await Socket.connect(host, port);
    print('Conectado ao servidor em $host:$port');

    final random = Random();
    Timer? timer;

    // Função para gerar e enviar temperatura
    void sendTemperature() {
      final double temperature = 20.0 + random.nextDouble() * 10.0;  // Aleatória entre 20.0 e 30.0°C
      final String message = 'Temperatura: ${temperature.toStringAsFixed(1)}°C\n';
      
      socket.write(message);  // Envia string como bytes
      socket.flush();  // Garante envio imediato
      print('Enviando: $message');
    }

    // Inicia o timer periódico assíncrono
    timer = Timer.periodic(interval, (Timer t) {
      sendTemperature();
    });

    // Envia a primeira leitura imediatamente
    sendTemperature();

    // Simula por um tempo finito (remova para infinito)
    await Future.delayed(totalDuration);
    timer?.cancel();
    print('Simulação finalizada após ${totalDuration.inSeconds} segundos.');

    // Fecha a conexão
    socket.destroy();
    print('Conexão fechada.');

  } catch (e) {
    print('Erro no dispositivo IoT: $e');
  }
}