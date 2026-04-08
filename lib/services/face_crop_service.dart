import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceCropService {
  Future<img.Image?> cropFace(File imageFile, Face face) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? source = img.decodeImage(bytes);
    if (source == null) {
      return null;
    }

    final int x = face.boundingBox.left.floor().clamp(0, source.width - 1);
    final int y = face.boundingBox.top.floor().clamp(0, source.height - 1);
    final int maxWidth = source.width - x;
    final int maxHeight = source.height - y;
    final int width = face.boundingBox.width.ceil().clamp(1, maxWidth);
    final int height = face.boundingBox.height.ceil().clamp(1, maxHeight);

    if (width <= 0 || height <= 0) {
      return null;
    }

    return img.copyCrop(source, x: x, y: y, width: width, height: height);
  }
}
