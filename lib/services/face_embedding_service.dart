import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbeddingService {
  FaceEmbeddingService({this.modelAssetPath = 'assets/models/facenet.tflite'});

  final String modelAssetPath;
  Interpreter? _interpreter;

  bool get isModelLoaded => _interpreter != null;

  Future<void> loadModel() async {
    _interpreter ??= await Interpreter.fromAsset(modelAssetPath);
  }

  List<double> generateEmbedding(img.Image faceImage) {
    final Interpreter? interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Face model is not loaded. Call loadModel() first.');
    }

    final List<int> inputShape = interpreter.getInputTensor(0).shape;
    final List<int> outputShape = interpreter.getOutputTensor(0).shape;

    final int inputHeight = inputShape.length > 1 ? inputShape[1] : 160;
    final int inputWidth = inputShape.length > 2 ? inputShape[2] : 160;
    final int embeddingLength = outputShape.length > 1 ? outputShape[1] : 128;

    final img.Image resized = img.copyResize(
      faceImage,
      width: inputWidth,
      height: inputHeight,
      interpolation: img.Interpolation.average,
    );
    final List<List<List<List<double>>>> input = <List<List<List<double>>>>[
      List<List<List<double>>>.generate(inputHeight, (int y) {
        return List<List<double>>.generate(inputWidth, (int x) {
          final img.Pixel pixel = resized.getPixel(x, y);
          return <double>[
            (pixel.r - 127.5) / 128.0,
            (pixel.g - 127.5) / 128.0,
            (pixel.b - 127.5) / 128.0,
          ];
        }, growable: false);
      }, growable: false),
    ];

    final List<List<double>> output = <List<double>>[
      List<double>.filled(embeddingLength, 0),
    ];
    interpreter.run(input, output);

    return output.first;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
