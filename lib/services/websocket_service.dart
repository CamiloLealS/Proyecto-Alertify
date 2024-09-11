import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  final String url = 'ws://localhost:3030';
  late IOWebSocketChannel channel;

  void listen(Function(dynamic) onMessageReceived) {
    channel = IOWebSocketChannel.connect(url);

    // Listen for incoming messages
    channel.stream.listen((message) {
      var data = jsonDecode(message);
      onMessageReceived(data);
      print(data);
    }, onError: (error) {
      print("WebSocket error: $error");
    }, onDone: () {
      print("WebSocket closed");
    });
  }

  void disconnect() {
    channel.sink.close();
  }
}