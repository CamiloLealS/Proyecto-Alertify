import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Asegúrate de tener esta dependencia
/*
// Función para calcular la distancia entre dos puntos usando la fórmula de Haversine
double haversineDistance(LatLng point1, LatLng point2) {
  const double R = 6371e3; // Radio de la Tierra en metros
  final double lat1 = point1.latitude * (pi / 180);
  final double lat2 = point2.latitude * (pi / 180);
  final double deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
  final double deltaLon = (point2.longitude - point1.longitude) * (pi / 180);

  final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final double distance = R * c; // Distancia en metros

  return distance;
}

// Función para obtener la elevación de una ubicación dada
Future<double> getElevation(LatLng location) async {
  final apiKey = 'AIzaSyAApzN7gbXptWtWl6WuZxxWovQWuTYVsTY'; // Reemplaza con tu clave API
  final url = 'https://maps.googleapis.com/maps/api/elevation/json?locations=${location.latitude},${location.longitude}&key=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['results'].isNotEmpty) {
      return data['results'][0]['elevation']; // Devuelve la elevación en metros
    } else {
      throw Exception('No se encontraron resultados de elevación');
    }
  } else {
    throw Exception('Error al obtener la elevación');
  }
}

double _userAltitude = 0.0; // Altitud del usuario
FlutterLocalNotificationsPlugin notificationService = FlutterLocalNotificationsPlugin(); // Inicializar el servicio de notificaciones

Future<void> evaluateDisaster(Disaster disaster) async {
  LatLng userLocation = await _getUserLocation(); // Suponiendo que tienes una función para obtener la ubicación del usuario
  double distance = haversineDistance(disaster.location, userLocation);
  
  if (disaster.type == "earthquake" && disaster.magnitude >= 7.0 && distance < 500000) {
    // Verifica la elevación del usuario
    _userAltitude = await getElevation(userLocation);
    bool isSafe = _userAltitude >= 30;

    if (isSafe) {
      // Ventana verde: seguro
      showSafeAlert(); // Implementar esta función para mostrar una ventana verde
    } else {
      // Ventana roja: peligro de tsunami
      showDangerAlert(); // Implementar esta función para mostrar una ventana roja
    }

    // Notificación si el usuario no está en la aplicación
    if (!isAppInForeground()) { // Implementa esta función para verificar si la app está en primer plano
      sendNotificationIfNotInApp(isSafe);
    }
  }
}

void showSafeAlert() {
  // Aquí va la lógica para mostrar la ventana verde
  // Ejemplo: mostrar un dialogo o snackbar que indica que el usuario está en un lugar seguro
}

void showDangerAlert() {
  // Aquí va la lógica para mostrar la ventana roja
  // Ejemplo: mostrar un dialogo o snackbar que indica que existe riesgo de tsunami
}

void sendNotificationIfNotInApp(bool isSafe) {
  String message = isSafe
      ? "Estás en un lugar seguro frente a tsunamis."
      : "¡Alerta de tsunami! Estás en riesgo debido a un terremoto cercano.";
  notificationService.show(0, "Alerta de Tsunami", message, NotificationDetails(
    android: AndroidNotificationDetails(
      'channel_id', 
      'channel_name', 
      importance: Importance.high,
      priority: Priority.high,
    )
  ));
}

// Implementa la lógica para determinar si la app está en primer plano
bool isAppInForeground() {
  // Este es un ejemplo. Implementa la lógica que necesites.
  return true; // Cambia esto según la lógica que implementes
}
*/