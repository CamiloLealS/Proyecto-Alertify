import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundCustomization extends StatefulWidget {
  @override
  _SoundCustomizationState createState() => _SoundCustomizationState();
}

class _SoundCustomizationState extends State<SoundCustomization> {
  String? selectedSound;

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
    _loadSelectedSound();
  }

  Future<void> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();

    if (!status.isGranted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permiso necesario'),
          content: Text(
              'Es necesario acceder a tu almacenamiento para personalizar los sonidos de alerta.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickSoundFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg'],
    );

    if (result != null) {
      String? filePath = result.files.single.path;

      if (filePath != null) {
        setState(() {
          selectedSound = filePath;
        });
        _saveSelectedSound(filePath); 
      }
    }
  }

  Future<void> _loadSelectedSound() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSound = prefs.getString('selectedSound');
    });
  }

  Future<void> _saveSelectedSound(String sound) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSound', sound);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personalización de Sonido'),
        backgroundColor: Color(0xFF007BFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecciona el sonido de alerta:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickSoundFile,
              child: Text('Elegir sonido desde dispositivo'),
            ),
            SizedBox(height: 20),
            if (selectedSound != null) ...[
              Text(
                'Sonido seleccionado: $selectedSound',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
            SizedBox(height: 20),
            Text(
              'O elige uno de los sonidos predeterminados:',
              style: TextStyle(fontSize: 18),
            ),
            ListTile(
              title: Text('Sonido 1'),
              onTap: () {
                setState(() {
                  selectedSound = 'default_sound_1';
                });
                _saveSelectedSound('default_sound_1');
              },
            ),
            ListTile(
              title: Text('Sonido 2'),
              onTap: () {
                setState(() {
                  selectedSound = 'default_sound_2';
                });
                _saveSelectedSound('default_sound_2');
              },
            ),
          ],
        ),
      ),
    );
  }
}