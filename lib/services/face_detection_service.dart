import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  FaceDetectionService({FaceDetectorOptions? options})
    : _faceDetector = FaceDetector(
        options:
            options ??
            FaceDetectorOptions(
              performanceMode: FaceDetectorMode.accurate,
              enableContours: false,
              enableLandmarks: false,
              enableTracking: false,
            ),
      );

  final FaceDetector _faceDetector;

  Future<List<Face>> detectFaces(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    return _faceDetector.processImage(inputImage);
  }

  Future<void> dispose() async {
    await _faceDetector.close();
  }
}
