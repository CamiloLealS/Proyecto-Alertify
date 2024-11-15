import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_alertify/main.dart';
import 'package:project_alertify/screens/sound_customization.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  LatLng _initialPosition = LatLng(-33.036855, -71.485898);
  late Position _currentPosition;
  double? _heading = 0;
  StreamSubscription? _compassSubscription;
  Set<Marker> _disasterMarkers = {};
  Set<Circle> _disasterCircles = {};
  double _userAltitude = 0.0;
  FlutterLocalNotificationsPlugin notificationService = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _listenToCompass();
    _subscribeToDisasters();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    if (await Permission.location.request().isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 100,
          ),
        );
        String userId = await getOrCreateUserId();
        await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
          'location': {
            'latitude': _currentPosition.latitude,
            'longitude': _currentPosition.longitude,
          }
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _initialPosition = LatLng(_currentPosition.latitude, _currentPosition.longitude);
            _mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition));
          });
        }
      } catch (e) {
        print('Error al obtener la ubicación: $e');
      }
    } else {
      print('Permiso de ubicación denegado');
    }
  }

  void _listenToCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading ?? 0;
      });
    });
  }

  void _subscribeToDisasters() {
    FirebaseFirestore.instance.collection('alertas').snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        print('el snapshot no esta vacio');
        Set<Marker> newMarkers = {};
        Set<Circle> newCircles = {};

        for (var doc in snapshot.docs) {
          var data = doc.data();
          print(data);
          var position= LatLng(data['puntos_evacuacion'][0]['latitude'], data['puntos_evacuacion'][0]['longitude']);
          var type = data['type'] ?? 'Desastre';
          bool isActive = data['activo'] ?? false;

          if (isActive) {
            if (type == 'earthquake') {
              newMarkers.add(Marker(
                markerId: MarkerId(doc.id),
                position: position,
                infoWindow: InfoWindow(
                  title: 'Terremoto',
                  snippet: 'Detalles del terremoto',
                ),
              ));
              newCircles.add(Circle(
                circleId: CircleId(doc.id),
                center: position,
                radius: 2000,
                strokeColor: Colors.redAccent.withOpacity(0.5),
                strokeWidth: 2,
                fillColor: Colors.redAccent.withOpacity(0.2),
              ));
            } else if (type == 'incendio') {
              newMarkers.add(Marker(
                markerId: MarkerId(doc.id),
                position: position,
                infoWindow: InfoWindow(
                  title: 'Incendio',
                  snippet: 'Punto inicial del incendio',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ));
              newCircles.add(Circle(
                circleId: CircleId(doc.id),
                center: position,
                radius: 200,
                strokeColor: Colors.orangeAccent.withOpacity(0.5),
                strokeWidth: 2,
                fillColor: Colors.orangeAccent.withOpacity(0.2),
              ));
              var puntos = data['puntos_evacuacion'] as List<dynamic>?;
              if (puntos != null) {
                for (int i = 1; i < puntos.length; i++) {
                  var puntoLatLng = LatLng(puntos[i]['latitude'], puntos[i]['longitude']);
                  print(puntoLatLng);
                  newCircles.add(Circle(
                    circleId: CircleId('${doc.id}_${i}}'),
                    center: puntoLatLng,
                    radius: 50,
                    strokeColor: Colors.orangeAccent.withOpacity(0.5),
                    strokeWidth: 2,
                    fillColor: Colors.orangeAccent.withOpacity(0.2),
                  ));
                }
              }
            } else {
              newMarkers.add(Marker(
                markerId: MarkerId(doc.id),
                position: position,
                infoWindow: InfoWindow(
                  title: type,
                  snippet: 'Detalles del desastre',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ));
            }
          }
        }

        setState(() {
          _disasterMarkers = newMarkers;
          _disasterCircles = newCircles;
        });
      }
    });
  }

  Future<void> evaluateDisaster(Map<String, dynamic> disasterData, LatLng disasterLocation) async {
    double distance = haversineDistance(disasterLocation, _initialPosition);

    if (disasterData['type'] == "earthquake" && disasterData['magnitude'] >= 7.0 && distance < 500000) {
      _userAltitude = await getElevation(_initialPosition);
      bool isSafe = _userAltitude >= 30;

      if (isSafe) {
        showSafeAlert();
      } else {
        showDangerAlert();
      }
    }
  }

  double haversineDistance(LatLng point1, LatLng point2) {
    const double R = 6371e3;
    final double lat1 = point1.latitude * (math.pi / 180);
    final double lat2 = point2.latitude * (math.pi / 180);
    final double deltaLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLon = (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  Future<double> getElevation(LatLng position) async {
    final response = await http.get(Uri.parse(
        'https://api.open-elevation.com/api/v1/lookup?locations=${position.latitude},${position.longitude}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'][0]['elevation'];
    } else {
      throw Exception('Error al obtener la elevación');
    }
  }

  Future<void> sendNotificationIfNotInApp(bool isSafe) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );
    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await notificationService.show(
      0,
      'Alerta de Desastre',
      isSafe ? 'Estás a salvo de este desastre.' : 'Peligro: ¡Tu ubicación está en riesgo!',
      platformChannelSpecifics,
    );
  }

  void showSafeAlert() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Estás a salvo del desastre.'),
      backgroundColor: Colors.green,
    ));
  }

  void showDangerAlert() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('¡Peligro! Tu ubicación está en riesgo.'),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Alertify",
          style: TextStyle(fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF007BFF),
        actions: [
          IconButton(
            icon: Icon(Icons.music_note),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SoundCustomization(),
                ),
              );
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 12),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: _disasterMarkers,
        circles: _disasterCircles,
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
      ),
    );
  }
}
