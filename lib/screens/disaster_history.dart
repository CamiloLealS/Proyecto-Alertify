import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DisasterHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Desastres'),
        backgroundColor: Color(0xFF007BFF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('alertas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los desastres'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay desastres disponibles'));
          }

          final disasters = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          DateTime now = DateTime.now();
          DateTime limitDate = now.subtract(Duration(days: 5));

          // Filtrar desastres en los últimos 5 días
          List<Map<String, dynamic>> filteredDisasters = disasters.where((disaster) {
            if (disaster['time'] == null) return false;
            Timestamp timestamp = disaster['time'];
            DateTime disasterDate = timestamp.toDate();
            return disasterDate.isAfter(limitDate) && disasterDate.isBefore(now);
          }).toList();

          filteredDisasters.sort((a, b) {
            Timestamp aTimestamp = a['time'];
            Timestamp bTimestamp = b['time'];
            return bTimestamp.compareTo(aTimestamp);  // Ordenar por fecha
          });

          return ListView.builder(
            itemCount: filteredDisasters.length,
            itemBuilder: (context, index) {
              final disaster = filteredDisasters[index];

              if (!disaster.containsKey('type') || !disaster.containsKey('title') || !disaster.containsKey('time')) {
                return ListTile(
                  title: Text('Datos incompletos'),
                  subtitle: Text('Faltan campos requeridos'),
                );
              }

              String title = disaster['title'];
              Timestamp timestamp = disaster['time'];
              DateTime dateTime = timestamp.toDate();
              String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);

              String displayTitle = '';
              String subtitle = '';
              Widget? trailing;
              Color tileColor = Colors.white;
              IconData disasterIcon = Icons.warning;

              // Definir título y color de fondo según el tipo de desastre
              if (disaster['type'] == 'earthquake') {
                displayTitle = 'Terremoto - $title';
                if (disaster.containsKey('magnitude')) {
                  double magnitude = disaster['magnitude'] is double
                      ? disaster['magnitude']
                      : double.parse(disaster['magnitude'].toString());

                  trailing = Text(
                    'Magnitud: $magnitude',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  );

                  if (magnitude >= 7) {
                    tileColor = Colors.redAccent.shade100;  // Color rojo para terremotos grandes
                  }
                }
                subtitle = 'Fecha: $formattedDate';
                disasterIcon = Icons.warning;
              } else if (disaster['type'] == 'incendio') {
                displayTitle = 'Incendio - $title';
                subtitle = 'Fecha: $formattedDate';
                disasterIcon = Icons.local_fire_department;
              } else {
                displayTitle = '${disaster['type']} - $title';
                subtitle = 'Fecha: $formattedDate';
                disasterIcon = Icons.info;
              }

              return Container(
                color: tileColor,
                child: ListTile(
                  leading: Icon(
                    disasterIcon,
                    color: tileColor == Colors.white ? Colors.black : Colors.white,
                  ),
                  title: Text(displayTitle),
                  subtitle: Text(subtitle),
                  trailing: trailing,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
