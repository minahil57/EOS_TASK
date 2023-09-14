import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  Uint8List? _displayedImage;
  Map<String, dynamic>? _imageDimensions;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      await _convertTo3D();
    }
  }

  String getImageFormat(Uint8List headerBytes) {
    if (headerBytes[0] == 0x89 && headerBytes[1] == 0x50 && headerBytes[2] == 0x4E &&
        headerBytes[3] == 0x47 && headerBytes[4] == 0x0D && headerBytes[5] == 0x0A &&
        headerBytes[6] == 0x1A && headerBytes[7] == 0x0A) {
      return 'PNG';
    } else if (headerBytes[0] == 0xFF && headerBytes[1] == 0xD8) {
      return 'JPEG';
    } else if ((headerBytes[0] == 0x47 && headerBytes[1] == 0x49 &&
        headerBytes[2] == 0x46 && headerBytes[3] == 0x38 && headerBytes[4] == 0x37 &&
        headerBytes[5] == 0x61) ||
        (headerBytes[0] == 0x47 && headerBytes[1] == 0x49 &&
            headerBytes[2] == 0x46 && headerBytes[3] == 0x38 && headerBytes[4] == 0x39 &&
            headerBytes[5] == 0x61)) {
      return 'GIF';
    } else {
      return 'Unknown';
    }
  }

  Future<void> _convertTo3D() async {
    if (_image != null) {
      final uri = Uri.parse('http://192.168.130.190:5000/convert_to_3d');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath('image', _image!.path),
        );

      try {
        final response = await request.send();
        final responseBody = await response.stream.toBytes();
        final parsedResponse = json.decode(utf8.decode(responseBody));

        if (parsedResponse['result'] == 'success') {
          final base64Image = parsedResponse['image'];
          final decodedImage = base64.decode(base64Image);

          setState(() {
            _displayedImage = Uint8List.fromList(decodedImage);
            _imageDimensions = parsedResponse['dimensions'];
          });
        } else {
          // Handle error
          print(parsedResponse['message']);
        }
      }
      catch (e) {
        print(e.toString());
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('3D Image Converter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Image'),
            if (_image != null)
              Image.file(
                _image!,
                width: 200,
                height: 200,
              ),
            Text('3D Image'),
            if (_displayedImage != null)
              Image.memory(
                _displayedImage!,
                width: 200,
                height: 200,
              ),
            if (_imageDimensions != null)
              Text(
                "Image Dimensions\nWidth: ${_imageDimensions!['width']}, Height: ${_imageDimensions!['height']}",
                style: TextStyle(fontSize: 16),
              ),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick an Image'),
            ),
            ElevatedButton(
              onPressed: _convertTo3D,
              child: Text('Convert to 3D'),
            ),
          ],
        ),
      ),
    );
  }
}
