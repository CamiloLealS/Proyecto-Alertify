import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_alertify/services/firebase_service.dart';

class DisasterHistory extends StatelessWidget {
  final FirebaseService firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Desastres'),
        backgroundColor: Color(0xFF007BFF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firebaseService.getDisasterUpdates(),
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

          // Extraer los documentos
          final disasters = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          // Obtener la fecha límite (hace 5 días)
          DateTime now = DateTime.now();
          DateTime limitDate = now.subtract(Duration(days: 5));

          // Filtrar desastres en el rango de fechas
          List<Map<String, dynamic>> filteredDisasters = disasters.where((disaster) {
            if (disaster['time'] == null) return false;
            Timestamp timestamp = disaster['time'];
            DateTime disasterDate = timestamp.toDate();
            return disasterDate.isAfter(limitDate) && disasterDate.isBefore(now);
          }).toList();

          // Ordenar los desastres por fecha (más reciente primero)
          filteredDisasters.sort((a, b) {
            Timestamp aTimestamp = a['time'];
            Timestamp bTimestamp = b['time'];
            return bTimestamp.compareTo(aTimestamp);
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
                    tileColor = Colors.redAccent.shade100;
                  }
                }
                subtitle = 'Fecha: $formattedDate';
              } else if (disaster['type'] == 'incendio') {
                displayTitle = 'Incendio - $title';
                subtitle = 'Fecha: $formattedDate';
              } else {
                displayTitle = '${disaster['type']} - $title';
                subtitle = 'Fecha: $formattedDate';
              }

              return Container(
                color: tileColor,
                child: ListTile(
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
