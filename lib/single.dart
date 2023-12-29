import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class Single extends StatefulWidget {
  @override
  SingleState createState() => SingleState();
}

class SingleState extends State<Single> {
  List<File> _images = [];
  List<File?> decryptedImages = []; // Variable to hold decrypted images

  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _images.add(File(pickedFile.path));
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> encryptImages(List<File> images) async {
    print('Encrypting images...');
    for (File imageFile in images) {
      List<int> imageBytes = await imageFile.readAsBytes();
      String imageString = base64Encode(imageBytes);

      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encryptedImage = encrypter.encrypt(imageString, iv: iv);

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      File encryptedFile = File(
          '$appDocPath/${DateTime.now().millisecondsSinceEpoch}_encrypted.txt');
      encryptedFile.writeAsStringSync(encryptedImage.base64);
    }
    print('Images encrypted successfully!');
  }

  Future<void> decryptImages() async {
    try {
      decryptedImages.clear();
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      List<FileSystemEntity> fileList = Directory(appDocPath).listSync();

      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      for (FileSystemEntity file in fileList) {
        if (file is File && file.path.endsWith("_encrypted.txt")) {
          String encryptedImageBase64 = await file.readAsString();
          final decryptedImage =
          encrypter.decrypt64(encryptedImageBase64, iv: iv);
          List<int> decryptedBytes = base64Decode(decryptedImage);
          Directory tempDir = await getTemporaryDirectory();
          String tempPath = tempDir.path;
          File decryptedFile =
              File('$tempPath/${file.path.split('/').last}.jpg');
          await decryptedFile.writeAsBytes(decryptedBytes);
          decryptedImages.add(decryptedFile);
        }
      }
      setState(() {});
    } catch (e) {
      print('Error decrypting images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Picker Example'),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              for (File image in _images) Image.file(image),
              TextButton(
                onPressed: () {
                  if (_images.isNotEmpty) {
                    encryptImages(_images);
                  } else {
                    print('No images selected.');
                  }
                },
                child: Text('Encrypt Images'),
              ),
              TextButton(
                onPressed: () {
                  decryptImages();
                },
                child: Text('Decrypt Images'),
              ),
              if (decryptedImages.isNotEmpty)
                Column(
                  children: decryptedImages
                      .map((image) => Image.file(image!))
                      .toList(),
                ), // Display decrypted images
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Single(),
  ));
}
