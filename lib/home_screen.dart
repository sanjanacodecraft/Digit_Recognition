import 'dart:typed_data';
import 'dart:ui' as ui; // For UI image
import 'package:image/image.dart' as img; // For image processing
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String prediction = '';
  List<Offset?> points = []; // List to store drawing points
  Interpreter? interpreter;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  // Load TFLite model
  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('digit_recognition.tflite');
    setState(() {
      print("Model loaded successfully");
    });
  }

  // Method to run the model and get the prediction
  void runModel() async {
    if (interpreter != null) {
      // Convert the points to a black and white 28x28 image
      var image = await _drawToImage();
      var input = _imageToInput(image);

      // Prepare output tensor
      List<List<double>> output = List.filled(1, List.filled(10, 0.0));

      // Run the model
      interpreter?.run(input, output);
      var outputList = output[0];

      // Get the index of the max value as the predicted digit
      setState(() {
        prediction = "Predicted digit: ${outputList.indexWhere((val) => val == outputList.reduce((a, b) => max(a, b)))}";
      });
    } else {
      print("Interpreter is not initialized");
    }
  }

  // Convert the drawing points into a 28x28 image
  Future<img.Image> _drawToImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(const Offset(0, 0), const Offset(28.0, 28.0)));

    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final ui.Image uiImage = await picture.toImage(28, 28);
    final ByteData? byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception('Failed to convert image to byte data');
    }

    // Convert byte data to img.Image
    final img.Image imgImage = img.Image.fromBytes(
      28,
      28,
      byteData.buffer.asUint8List(),
      format: img.Format.rgba,
    );

    return imgImage;
  }

  // Convert image into a tensor input for the model
  List<List<List<List<double>>>> _imageToInput(img.Image image) {
    List<List<List<List<double>>>> input = List.generate(
        1, (_) => List.generate(28, (_) => List.generate(28, (_) => List.filled(1, 0.0))));

    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        int pixel = image.getPixel(x, y);
        var r = (pixel >> 16) & 0xFF;
        var g = (pixel >> 8) & 0xFF;
        var b = pixel & 0xFF;
        var grayscale = (r + g + b) / 3;
        input[0][y][x][0] = grayscale / 255.0;
      }
    }

    return input;
  }

  // Clear the drawing
  void clearDrawing() {
    setState(() {
      points.clear();
      prediction = '';
    });
  }

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digit Recognition')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 280,
              height: 280,
              color: Colors.grey[300],
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    points.add(details.localPosition);
                  });
                },
                onPanEnd: (_) {
                  points.add(null);
                },
                child: CustomPaint(
                  painter: MyPainter(points),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(prediction),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: runModel,
              child: const Text('Run Model'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: clearDrawing,
              child: const Text('Clear Drawing'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for drawing
class MyPainter extends CustomPainter {
  final List<Offset?> points;
  MyPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

