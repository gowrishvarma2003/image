import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? decryptedImagePath;

  void encryptImage() async {
    print('Encrypting image...');
    ByteData imageData = await rootBundle.load('assets/123.jpg');
    Uint8List imageBytes = imageData.buffer.asUint8List();

    // Convert the bytes to a Base64-encoded string
    String imageString = base64Encode(imageBytes);

    // Encryption key and IV (Initialization Vector)
    final key = encrypt.Key.fromLength(32); // 256-bit key
    final iv = encrypt.IV.fromLength(16); // 128-bit IV

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Encrypt the image string
    final encryptedImage = encrypter.encrypt(imageString, iv: iv);

    // Get the app's documents directory
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    print(appDocPath);

    // Save the encrypted image to a new file in the documents directory
    File encryptedFile = File('$appDocPath/X_encrypted.txt');
    encryptedFile.writeAsStringSync(encryptedImage.base64);

    print('Image encrypted successfully!');
  }

  Future<void> decryptImage() async {
    print('Decrypting image...');
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    // Read the encrypted image from the file
    File encryptedFile = File('$appDocPath/X_encrypted.txt');
    String encryptedImageString = encryptedFile.readAsStringSync();
    final encryptedImage = encrypt.Encrypted.fromBase64(encryptedImageString);

    // Encryption key and IV (Initialization Vector)
    final key = encrypt.Key.fromLength(32); // 256-bit key
    final iv = encrypt.IV.fromLength(16); // 128-bit IV

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Decrypt the image
    final decryptedImageString = encrypter.decrypt(encryptedImage, iv: iv);
    Uint8List decryptedImageBytes = base64Decode(decryptedImageString);

    // Write the decrypted image to a new file in the documents directory
    File decryptedFile = File('$appDocPath/decrypted_image.jpg');
    await decryptedFile.writeAsBytes(decryptedImageBytes);

    setState(() {
      decryptedImagePath = decryptedFile.path;
    });

    print('Image decrypted successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: encryptImage,
              child: const Text('Encrypt Image'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: decryptImage,
              child: const Text('Decrypt Image'),
            ),
            SizedBox(height: 20),
            if (decryptedImagePath != null)
              Image.file(
                File(decryptedImagePath!),
                width: 500,
                height: 500,
              ),
          ],
        ),
      ),
    );
  }
}
