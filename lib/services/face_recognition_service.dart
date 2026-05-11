import 'dart:io';

import 'package:nimbus/models/face_record.dart';
import 'package:nimbus/services/face_crop_service.dart';
import 'package:nimbus/services/face_detection_service.dart';
import 'package:nimbus/services/face_embedding_service.dart';
import 'package:nimbus/services/hive_face_service.dart';

class FaceRecognitionService {
  FaceRecognitionService({
    FaceDetectionService? detector,
    FaceCropService? cropper,
    FaceEmbeddingService? embedder,
    HiveFaceService? storage,
  }) : _detector = detector ?? FaceDetectionService(),
       _cropper = cropper ?? FaceCropService(),
       _embedder = embedder ?? FaceEmbeddingService(),
       _storage = storage ?? HiveFaceService();

  final FaceDetectionService _detector;
  final FaceCropService _cropper;
  final FaceEmbeddingService _embedder;
  final HiveFaceService _storage;

  Future<List<FaceRecord>> processImage(
    File imageFile, {
    double threshold = 0.8,
  }) async {
    if (!_embedder.isModelLoaded) {
      await _embedder.loadModel();
    }

    final List<FaceRecord> savedRecords = <FaceRecord>[];
    final faces = await _detector.detectFaces(imageFile);
    for (final face in faces) {
      final croppedFace = await _cropper.cropFace(imageFile, face);
      if (croppedFace == null) {
        continue;
      }

      final List<double> embedding = _embedder.generateEmbedding(croppedFace);
      final FaceRecord saved = await _storage.saveFaceWithAutoPersonMatch(
        imagePath: imageFile.path,
        embedding: embedding,
        threshold: threshold,
      );
      savedRecords.add(saved);
    }

    return savedRecords;
  }

  Future<void> dispose() async {
    await _detector.dispose();
    _embedder.dispose();
  }
}
