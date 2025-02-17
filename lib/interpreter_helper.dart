import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Interpreter? interpreter;

Future<String> downloadModel() async {
  // Replace this URL with your Google Drive direct download link
  const url = 'https://drive.google.com/uc?export=download&id=1M4F9VJluR0lWm04Qxb_TCxjmh2ise-9U';
  //https://drive.google.com/file/d/1M4F9VJluR0lWm04Qxb_TCxjmh2ise-9U/view?usp=sharing

  // Get the app's documents directory
  final directory = await getApplicationDocumentsDirectory();
  final modelPath = '${directory.path}/digit_recognition.tflite';
  final modelFile = File(modelPath);


  // Check if the model already exists in the app's local storage
  if (!await modelFile.exists()) {
    print("Downloading model from Google Drive...");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await modelFile.writeAsBytes(response.bodyBytes);
        print("Model downloaded successfully to: $modelPath");
      } else {
        print("Failed to download model. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error downloading model: $e");
      throw Exception("Model download failed");
    }
  } else {
    print("Model already exists at: $modelPath");
  }

  return modelPath;
}

Future<void> initializeInterpreter() async {
  try {

    bool useDownloadedModel = false;
    String modelPath;

    if (useDownloadedModel) {
      // Download the model from Google Drive
      modelPath = await downloadModel();
      interpreter = Interpreter.fromFile(File(modelPath));
      print("Interpreter loaded from downloaded model!");
    } else {
      // Load the model from assets folder
      interpreter = await Interpreter.fromAsset('digit_recognition.tflite');
      print("Interpreter loaded from bundled asset!");
    }
  } catch (e) {
    print("Error initializing interpreter: $e");
  }
}


