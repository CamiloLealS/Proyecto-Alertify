import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; //Paw
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_alertify/consts.dart';
import 'package:project_alertify/main.dart';
import 'package:project_alertify/screens/sound_customization.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Asegúrate de tener esta dependencia


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //Position _locationController = new Position(); // Paw
  //LatLng? currentP = null;
  //final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
   
  late GoogleMapController _mapController;
  LatLng _initialPosition = LatLng(0, 0); // Ubicación inicial
  late Position _currentPosition;
  double? _heading = 0; // Orientación inicial del dispositivo
  StreamSubscription? _compassSubscription;
  Set<Marker> _disasterMarkers = {}; // Set de marcadores de desastres
  Set<Circle> _disasterCircles = {}; // Set de círculos de ondas para terremotos

  double _userAltitude = 0.0; // Altitud del usuario
  FlutterLocalNotificationsPlugin notificationService = FlutterLocalNotificationsPlugin(); // Inicializar el servicio de notificaciones
  //Paw
  Set<Polyline> _polylines =Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  //PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    //_getUserLocation(); // Obtener la ubicación del usuario al iniciar 
    _listenToCompass(); // Escuchar los cambios en la orientación
    _subscribeToDisasters(); // Escuchar los cambios de desastres en tiempo real desde Firebase
    //pAW
    polylinePoints = PolylinePoints();
    /*_getUserLocation().then(
      (_) => {
      getPolylinePoints().then((coordinates) => {
        generatePolylineFromPoints(coordinates),
      }), 
    },
    );*/
  }

  @override
  void dispose() {
    _compassSubscription?.cancel(); // Cancelar la suscripción al compás
    super.dispose();
  }

  // Método para obtener la ubicación actual del usuario
  Future<void> _getUserLocation() async {
    if (await Permission.location.request().isGranted) {
      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
        String userId = await getOrCreateUserId();

        await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
          'location':{
            'latitude': _currentPosition.latitude,
            'longitude': _currentPosition.longitude
          }
        }, SetOptions(merge: true)
        );

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

  // Método para escuchar los cambios en la orientación del dispositivo
  void _listenToCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading ?? 0;
      });
    });
  }

  // Suscribirse a la colección de desastres en Firebase  
  void _subscribeToDisasters() {
    FirebaseFirestore.instance.collection('alertas').snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        Set<Marker> newMarkers = {};
        Set<Circle> newCircles = {}; // Set para los nuevos círculos

        for (var doc in snapshot.docs) {
          var data = doc.data();
          var position = LatLng(data['latitude'], data['longitude']);
          var type = data['type'] ?? 'Desastre';
          bool isActive = data['activo'] ?? false;

          if (isActive) {
            // Añadir el marcador y círculo solo si está activo
            if (type == 'earthquake') {
              newMarkers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: position,
                  infoWindow: InfoWindow(
                    title: 'Terremoto',
                    snippet: 'Detalles del terremoto',
                  ),
                ),
              );
              newCircles.add(
                Circle(
                  circleId: CircleId(doc.id),
                  center: position,
                  radius: 2000,
                  strokeColor: Colors.redAccent.withOpacity(0.5),
                  strokeWidth: 2,
                  fillColor: Colors.redAccent.withOpacity(0.2),
                ),
              );
            } else if (type == 'incendio') {
              // Agregar un marcador en el punto inicial del incendio
              newMarkers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: position,
                  infoWindow: InfoWindow(
                    title: 'Incendio',
                    snippet: 'Punto inicial del incendio',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                ),
              );

              // Círculo en el punto inicial del incendio con un radio constante
              newCircles.add(
                Circle(
                  circleId: CircleId(doc.id),
                  center: position,
                  radius: 200,
                  strokeColor: Colors.orangeAccent.withOpacity(0.5),
                  strokeWidth: 2,
                  fillColor: Colors.orangeAccent.withOpacity(0.2),
                ),
              );

              // Dibujar círculos adicionales para los demás puntos en `puntos`
              var puntos = data['puntos'] as List<dynamic>?;
              if (puntos != null) {
                for (var punto in puntos) {
                  var puntoLatLng = LatLng(punto['latitude'], punto['longitude']);
                  newCircles.add(
                    Circle(
                      circleId: CircleId('${doc.id}_${punto['latitude']}_${punto['longitude']}'),
                      center: puntoLatLng,
                      radius: 50, // Misma distancia para todos los puntos
                      strokeColor: Colors.orangeAccent.withOpacity(0.5),
                      strokeWidth: 2,
                      fillColor: Colors.orangeAccent.withOpacity(0.2),
                    ),
                  );
                }
              }
            } else {
              newMarkers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: position,
                  infoWindow: InfoWindow(
                    title: type,
                    snippet: 'Detalles del desastre',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              );
            }
          }
        }

        // Actualizar el estado solo una vez después de procesar todos los desastres
        setState(() {
          _disasterMarkers = newMarkers;
          _disasterCircles = newCircles;
        });
      }
    });
  }



  // Función para calcular el ángulo en radianes
  double _calculateMarkerRotation() {
    return ((_heading ?? 0) * (math.pi / 180)); // Convertir de grados a radianes
  }

  // Función para evaluar el desastre
  Future<void> evaluateDisaster(Map<String, dynamic> disasterData, LatLng disasterLocation) async {
    double distance = haversineDistance(disasterLocation, _initialPosition);

    if (disasterData['type'] == "earthquake" && disasterData['magnitude'] >= 7.0 && distance < 500000) {
      // Verifica la elevación del usuario
      _userAltitude = await getElevation(_initialPosition);
      bool isSafe = _userAltitude >= 30;
      print('altitud del usuario: ${_userAltitude}');

      if (isSafe) {
        showSafeAlert(); // Implementar esta función para mostrar una ventana verde
      } else {
        showDangerAlert(); // Implementar esta función para mostrar una ventana roja
      }


      
    }
  }

  // Función para calcular la distancia entre dos puntos usando la fórmula de Haversine
  double haversineDistance(LatLng point1, LatLng point2) {
    const double R = 6371e3; // Radio de la Tierra en metros
    final double lat1 = point1.latitude * (math.pi / 180);
    final double lat2 = point2.latitude * (math.pi / 180);
    final double deltaLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLon = (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c; // Distancia en metros
  }

  // Método para obtener la elevación del usuario
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

  // Función para enviar notificación si el usuario no está en la aplicación
  Future<void> sendNotificationIfNotInApp(bool isSafe) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      playSound: true,
      styleInformation: BigTextStyleInformation('')
    );
    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await notificationService.show(
      0,
      'Alerta de Desastre',
      isSafe ? 'Estás a salvo de este desastre.' : 'Peligro: ¡Tu ubicación está en riesgo!',
      platformChannelSpecifics,
      payload: 'data', // Puedes añadir más datos aquí si es necesario
    );
  }

  // Método para mostrar alerta de seguridad
  void showSafeAlert() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Estás a salvo del desastre.'),
      backgroundColor: Colors.green,
    ));
  }

  // Método para mostrar alerta de peligro
  void showDangerAlert() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('¡Peligro! Tu ubicación está en riesgo.'),
      backgroundColor: Colors.red,
    ));
  }

  // Método para verificar si la aplicación está en primer plano
  bool isAppInForeground() {
    // Implementar lógica para verificar si la app está en primer plano
    return true; // Esto es un placeholder
  }
//Paw
/*
getDirections(List<Marker> markers,newSetState) async {
    List<LatLng> polylineCoordinates = [];
    List<PolylineWayPoint> polylineWayPoints = [];
    for(var i = 0; i<markers.length;i++){
      polylineWayPoints.add(PolylineWayPoint(location: "${markers[i].position.latitude.toString()},${markers[i].position.longitude.toString()}",stopOver: true));
    }// result gets little bit late as soon as in video, because package // send http request for getting real road routes    
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates( 
        googleApiKey: "AIzaSyAApzN7gbXptWtWl6WuZxxWovQWuTYVsTY", //GoogleMap ApiKey
        PointLatLng(markers.first.position.latitude, markers.first.position.longitude), //first added marker
        PointLatLng(markers.last.position.latitude, markers.last.position.longitude), //last added marker
        travelMode: TravelMode.driving ); // Sometimes There is no result for example you can put maker to the // ocean, if results not empty adding to polylineCoordinates
if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }

    newSetState(() {});

    addPolyLine(polylineCoordinates,newSetState);

  }

  addPolyLine(List<LatLng> polylineCoordinates,newSetState) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 4,
    );
    polylines[id] = polyline;

    newSetState(() {});
  }

*/

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
          setPolylines(); //PAw
        },
        markers: _disasterMarkers,
        circles: _disasterCircles,
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        polylines: _polylines,//Set<Polyline>.of(polylines.values),
      ),
    );
  }
  //Paw
  void setPolylines() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: GOOGLE_MAPS_API_KEY, 
      PointLatLng(
        _currentPosition.latitude, 
        _currentPosition.longitude),
      PointLatLng(
        _currentPosition.latitude, 
        _currentPosition.longitude),
      TravelMode.walking,);
      if (result.status == 'OK') {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }); 
      setState(() {
        PolylineId id = PolylineId("poly");
        _polylines.add(
          Polyline(
            width: 10,
            polylineId: PolylineId('polyline'),
            color: Colors.black45,
            points: polylineCoordinates)
        );
      });
    } 


  }
  /*Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: GOOGLE_MAPS_API_KEY, 
      _initialPosition.latitude, _initialPosition.longitude, 
      _currentPosition.latitude, _currentPosition.longitude, 
      TravelMode.walking,);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }); 
    } else{
      print(result.errorMessage);
    }
    return polylineCoordinates;

  }*/
/*
 Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled =await _locationController._serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled =await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted =await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted == PermissionStatus.granted) {
        return;
      }
    }
*/

  /*void generatePolylineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(polylineId: id, color: Colors.cyan, points: polylineCoordinates, width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }
*/
}
