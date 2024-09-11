import 'package:flutter/material.dart';



class InfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Protocolos y Desastres'),
        backgroundColor: Color(0xFF007BFF), // Azul
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.warning, color: Color(0xFFFFD700)), // Amarillo
            title: Text('Terremoto'),
            subtitle: Text('Protocolo de evacuación en caso de terremoto.'),
          ),
          ListTile(
            leading: Icon(Icons.fire_extinguisher, color: Color(0xFFFFA500)), // Naranja
            title: Text('Incendio'),
            subtitle: Text('Medidas a seguir en caso de incendio.'),
          ),
          ListTile(
            leading: Icon(Icons.water_damage, color: Color(0xFFFF4C4C)), // Rojo
            title: Text('Inundación'),
            subtitle: Text('Instrucciones en caso de inundación.'),
          ),
        ],
      ),
    );
  }
}