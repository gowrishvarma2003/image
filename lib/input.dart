import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Encryption',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  List<XFile>? _imageList = [];
  List<File?> decryptedImages = []; // Variable to hold decrypted images

  Future<void> encryptImages(List<File> images) async {
    print('Encrypting images...');
    try {
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      for (int i = 0; i < images.length; i++) {
        File imageFile = images[i];
        List<int> imageBytes = await imageFile.readAsBytes();
        String imageString = base64Encode(imageBytes);

        final encryptedImage = encrypter.encrypt(imageString, iv: iv);

        File encryptedFile = File(
            '$appDocPath/${DateTime.now().millisecondsSinceEpoch}_encrypted_$i.txt');
        await encryptedFile.writeAsString(encryptedImage.base64);
      }
      print('Images encrypted successfully!');
    } catch (e) {
      print('Error encrypting images: $e');
    }
  }

  Future<void> decryptImages() async {
    try {
      decryptedImages.clear();
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;

      List<FileSystemEntity> fileList = Directory(appDocPath).listSync();

      for (FileSystemEntity file in fileList) {
        if (file is File && file.path.contains("_encrypted_")) {
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

  void _encryptSelectedImages() async {
    if (_imageList != null && _imageList!.isNotEmpty) {
      List<File> selectedFiles = _imageList!.map((xFile) => File(xFile.path)).toList();
      await encryptImages(selectedFiles);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No Images Selected'),
          content: Text('Please select images first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _decryptAndDisplayImages() async {
    await decryptImages();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisplayImagesScreen(imageList: decryptedImages),
      ),
    );
  }

  Future<void> _pickImages() async {
    List<XFile>? pickedImages = await ImagePicker().pickMultiImage(
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    setState(() {
      _imageList = pickedImages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Encryption'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickImages,
              child: Text('Pick Images'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _encryptSelectedImages,
              child: Text('Encrypt Images'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _decryptAndDisplayImages,
              child: Text('Decrypt Images'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: _imageList?.length ?? 0,
                itemBuilder: (context, index) {
                  return Image.file(
                    File(_imageList![index].path),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayImagesScreen extends StatelessWidget {
  final List<File?> imageList;

  const DisplayImagesScreen({required this.imageList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Decrypted Images'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: imageList.length,
        itemBuilder: (context, index) {
          return Image.file(
            imageList[index]!,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
