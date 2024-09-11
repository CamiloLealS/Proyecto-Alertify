import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Alertify", style: TextStyle(fontSize: 30),), centerTitle: true, backgroundColor: Color(0xFF007BFF),),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(-33.036577, -71.486793),
          initialZoom: 16.7,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          PolygonLayer(
            polygons: [
              Polygon(
                points: [
                  LatLng(-33.036500, -71.489500), 
                  LatLng(-33.039200, -71.485200), 
                  LatLng(-33.035500, -71.485300),
                  LatLng(-33.034950, -71.488850),
                ],
                color: Color.fromARGB(28, 33, 149, 243),
                borderColor: Colors.blue,
                borderStrokeWidth: 3.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}