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
  File? _image;
  File? decryptedImageFile; // Variable to hold decrypted image
  List<File> encryptedImageFiles = [];
  List<File> decryptedImageFiles = [];

  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> encryptImage(File imageFile) async {
    print('Encrypting image...');
    List<int> imageBytes = await imageFile.readAsBytes();

    String imageString = base64Encode(imageBytes);

    final key = encrypt.Key.fromLength(32);

    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encryptedImage = encrypter.encrypt(imageString, iv: iv);

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    // Generate a unique identifier for the file name
    final uniqueId = UniqueKey().toString();

    File encryptedFile = File('$appDocPath/X_encrypted_$uniqueId.txt');
    encryptedFile.writeAsStringSync(encryptedImage.base64);

    // Save the encrypted file path to the list
    encryptedImageFiles.add(encryptedFile);

    print('Image encrypted successfully!');
  }

  Future<File?> decryptImage(File encryptedFile) async {
    try {
      String encryptedImageBase64 = await encryptedFile.readAsString();

      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decryptedImage = encrypter.decrypt64(encryptedImageBase64, iv: iv);

      List<int> decryptedBytes = base64Decode(decryptedImage);

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;

      File decryptedFile = File('$tempPath/decrypted_image_${UniqueKey()}.jpg');
      await decryptedFile.writeAsBytes(decryptedBytes);

      return decryptedFile;
    } catch (e) {
      print('Error decrypting image: $e');
      return null;
    }
  }

  Future<void> displayDecryptedImages() async {
    for (var file in encryptedImageFiles) {
      File? decryptedFile = await decryptImage(file);

      if (decryptedFile != null) {
        decryptedImageFiles.add(decryptedFile);
      }
    }
    setState(() {}); // Update the state to trigger a re-render
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
              if (_image != null) Image.file(_image!),
              TextButton(
                onPressed: () {
                  if (_image != null) {
                    encryptImage(_image!);
                  } else {
                    print('No image selected.');
                  }
                },
                child: Text('Encrypt Image'),
              ),
              TextButton(
                onPressed: () {
                  displayDecryptedImages(); // Update method call
                },
                child: Text('Decrypt Image'),
              ),
              if (decryptedImageFile != null)
                Image.file(decryptedImageFile!), // Display decrypted image
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
