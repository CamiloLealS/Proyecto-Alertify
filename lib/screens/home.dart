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
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:project_alertify/widgets/consts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  LatLng _initialPosition = LatLng(-33.036855, -71.485898);
  late Position _currentPosition;
  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  double? _heading = 0;
  List<LatLng> polylineCoordinates = [];
  Set<Marker> _disasterMarkers = {};
  Set<Circle> _disasterCircles = {};
  Set<Polygon> _setSafeZones = {};
  StreamSubscription? _compassSubscription;
  double _userAltitude = 0.0;
  FlutterLocalNotificationsPlugin notificationService = FlutterLocalNotificationsPlugin();
  List<LatLng> plazaCivica = [
    LatLng(-33.036080, -71.487968), 
    LatLng(-33.035944, -71.487917), // Coordenada 2
    LatLng(-33.036152, -71.487230), // Coordenada 3
    LatLng(-33.036278, -71.487302), // Coordenada 4
  ];
  List<LatLng> casa = [
    LatLng(-33.050476, -71.434954), 
    LatLng(-33.050905, -71.434828), // Coordenada 2
    LatLng(-33.050928, -71.435343), // Coordenada 3
    LatLng(-33.050456, -71.435332), // Coordenada 4
  ];
  List<LatLng> cancha = [
    LatLng(-33.035755, -71.488105), 
    LatLng(-33.036167, -71.488295), // Coordenada 2
    LatLng(-33.036070, -71.488657), // Coordenada 3
    LatLng(-33.035710, -71.488459), // Coordenada 4
  ];
  String _alertMessage = '';
  Color _alertColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _subscribeToDisasters();
    _listenToCompass();
    notificationStreamController.stream.listen((notificationData) {
      print('AQUI DEBERIAN APARECER LOS DATOS QUE VIENEN EN LA NOTIFICACIÓN');
      print(notificationData['evacuar']);
      print(notificationData['tipoDesastre']);
      handleNotification(notificationData);
    });
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
        setState(() {
          _initialPosition = LatLng(_currentPosition.latitude, _currentPosition.longitude);
          _mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition));
        });
      } catch (e) {
        print('Error al obtener la ubicación: $e');
      }
    } else {
      print('Permiso de ubicación denegado');
    }
  }

  Future<void> _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    // Initializing PolylinePoints
    polylinePoints = PolylinePoints();

    // Generating the list of coordinates to be used for
    // drawing the polylines
    PolylineRequest request = PolylineRequest(// Google Maps API Key
      origin: PointLatLng(startLatitude, startLongitude),
      destination: PointLatLng(destinationLatitude, destinationLongitude),
      mode: TravelMode.transit
    );

    // Adding the coordinates to the list
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(request: request, googleApiKey: API_KEY);

    // Manejar los puntos devueltos por el resultado
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      print('Error al generar las coordenadas: ${result.errorMessage}');
    }

    // Defining an ID
    PolylineId id = PolylineId('poly');

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );

    // Adding the polyline to the map
    polylines[id] = polyline;
  }

  void _listenToCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading ?? 0;
      });
    });
  }

  void handleNotification(Map<String, dynamic> notificationData) {
    final String tipoDesastre = notificationData['data']['type'] ?? '';
    int tipo = 0;

    if (tipoDesastre == 'incendio'){
      setState(() {
        tipo = 1;
        _setSafeZones = {
          Polygon(
            polygonId: PolygonId('zona_segura_1'),
            points: plazaCivica,
            strokeColor: Colors.green,
            strokeWidth: 2,
            fillColor: Colors.green.withOpacity(0.2),
          ),
        };
      });
    } else if (tipoDesastre == 'earthquake'){
      setState(() {
        tipo = 2;
        _setSafeZones = {
          Polygon(polygonId: PolygonId('zona_segura_3'),
            points: cancha,
            strokeColor: Colors.green,
            strokeWidth: 2,
            fillColor: Colors.green.withOpacity(0.2))
        };
      });
    } else {
      setState(() {
        tipo = 3;
        _setSafeZones = {
          Polygon(
            polygonId: PolygonId('zona_segura_1'),
            points: plazaCivica,
            strokeColor: Colors.green,
            strokeWidth: 2,
            fillColor: Colors.green.withOpacity(0.2),
          ),
          Polygon(polygonId: PolygonId('zona_segura_3'),
            points: cancha,
            strokeColor: Colors.green,
            strokeWidth: 2,
            fillColor: Colors.green.withOpacity(0.2))
        };
      });
    }

    _checkUserInSafeZone(tipo);
  }


  void _checkUserInSafeZone(int tipo) async {
    double positionSafe0 = 0;
    double positionSafe1 = 0;
    if (tipo == 1){
      var snapshot = await FirebaseFirestore.instance.collection('zonas_seguras_incendio').get();
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        var data = doc['coordenadas'];
        positionSafe0 = data['latitude'];
        positionSafe1 = data['longitude'];
      } else {
        throw Exception("No se encontró una zona segura en la colección Zona Segura Incendio");
      }
    } else if (tipo == 2){
      var snapshot = await FirebaseFirestore.instance.collection('zonas_segura_terremoto').get();
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        var data = doc['coordenadas'];
        positionSafe0 = data['latitude'];
        positionSafe1 = data['longitude'];
      } else {
        throw Exception("No se encontró una zona segura en la colección Zona Segura Incendio");
      }
    }else if (tipo == 3) {
      positionSafe0 = -33.036080;
      positionSafe1 = -71.487968;
    }
    Set<Marker> newMarkers = {};
    bool isInSafeZone = false;

    for (var polygon in _setSafeZones) {
      if (_isPointInPolygon(_currentPosition, polygon.points)) {
        isInSafeZone = true;
        break;
      }
    }

    setState(() {
      if (isInSafeZone) {
        _alertMessage = 'Estás a salvo del desastre.';
        _alertColor = Colors.green;
      } else {
        _alertMessage = '¡Peligro! Tu ubicación está en riesgo.';
        _alertColor = Colors.red;
        newMarkers.add(Marker(
                markerId: MarkerId('userLocation'),
                position: LatLng(_currentPosition.latitude, _currentPosition.longitude),
                infoWindow: InfoWindow(
                  title: 'Tu Ubicación',
                ),
              ));
        newMarkers.add(Marker(
                markerId: MarkerId('userLocation'),
                position: LatLng(positionSafe0, positionSafe1),
                infoWindow: InfoWindow(
                  title: 'Zona Segura',
                ),
              ));
        _createPolylines(_currentPosition.latitude, _currentPosition.longitude, positionSafe0, positionSafe1);
      }
    });
  }

  bool _isPointInPolygon(Position position, List<LatLng> polygonPoints) {
    int intersectCount = 0;
    for (int j = 0; j < polygonPoints.length - 1; j++) {
      if (_rayCastIntersect(
        position,
        polygonPoints[j],
        polygonPoints[j + 1],
      )) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  bool _rayCastIntersect(Position point, LatLng vertA, LatLng vertB) {
    double px = point.longitude;
    double py = point.latitude;
    double ax = vertA.longitude;
    double ay = vertA.latitude;
    double bx = vertB.longitude;
    double by = vertB.latitude;

    if ((ay > py) != (by > py) &&
        (px < (bx - ax) * (py - ay) / (by - ay) + ax)) {
      return true;
    }
    return false;
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
                radius: 500000,
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
                radius: 50,
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
                    radius: 20,
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
          }else{
            _setSafeZones = {};
            _alertColor = Colors.transparent;
            _alertMessage = '';
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
      
      setState(() {
        if (isSafe) {
          _alertMessage = 'Estás a salvo del desastre.';
          _alertColor = Colors.green;
        } else {
          _alertMessage = '¡Peligro! Tu ubicación está en riesgo.';
          _alertColor = Colors.red;
        }
      });
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
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 12),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: _disasterMarkers,
            circles: _disasterCircles,
            polygons: _setSafeZones,
            polylines: Set<Polyline>.of(polylines.values),
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(10),
              color: _alertColor,
              child: Text(
                _alertMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
