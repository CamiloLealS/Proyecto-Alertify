import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InfoSection extends StatelessWidget {
  // Método para obtener los datos de Firestore
  Stream<QuerySnapshot> _getDisasters() {
    return FirebaseFirestore.instance.collection('informacion_catastrofe').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Protocolos y Desastres'),
        backgroundColor: Color(0xFF007BFF), // Azul
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getDisasters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los datos.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay desastres registrados.'));
          }

          final disasters = snapshot.data!.docs;

          return ListView.builder(
            itemCount: disasters.length,
            itemBuilder: (context, index) {
              var disaster = disasters[index];
              String tipo = disaster['tipo']; // Campo tipo
              String descripcion = disaster['descripcion']; // Campo descripcion
              String recomendaciones = disaster['recomendaciones']; // Campo recomendaciones

              return Card(
                margin: EdgeInsets.all(10),
                elevation: 4,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Icon(
                    tipo == 'Terremoto' ? Icons.warning : Icons.fire_extinguisher,
                    color: tipo == 'Terremoto' ? Color(0xFFFFD700) : Color(0xFFFFA500),
                  ),
                  title: Text(tipo, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Ver más información sobre este desastre'),
                  onTap: () {
                    // Mostrar la información detallada del desastre
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tipo,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Descripción:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(descripcion),
                              SizedBox(height: 16),
                              Text(
                                'Recomendaciones:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(recomendaciones),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
