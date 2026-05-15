import 'dart:math';

import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';

class MockFaceIdentity {
  const MockFaceIdentity({
    required this.label,
    required this.confidence,
    this.localThumbnail,
    this.mockAssetPath,
    required this.fromDeviceLibrary,
  });

  final String label;
  final double confidence;
  final ThumbnailRef? localThumbnail;
  final String? mockAssetPath;
  final bool fromDeviceLibrary;
}

class MockFaceRecognitionService {
  static const List<String> _labels = <String>[
    'Mugil',
    'Asha',
    'Kavin',
    'Nila',
    'Arun',
    'Divya',
    'Ravi',
    'Meera',
  ];

  static const List<String> _sampleAssets = <String>[
    'assets/images/samples/sample_01.png',
    'assets/images/samples/sample_02.png',
    'assets/images/samples/sample_03.png',
    'assets/images/samples/sample_04.png',
    'assets/images/samples/sample_05.png',
    'assets/images/samples/sample_06.png',
    'assets/images/samples/sample_07.png',
    'assets/images/samples/sample_08.png',
    'assets/images/samples/sample_09.png',
    'assets/images/samples/sample_10.png',
    'assets/images/samples/sample_11.png',
    'assets/images/samples/sample_12.png',
  ];

  List<MockFaceIdentity> buildPeoplePreview(
    List<MediaItem> mediaItems, {
    int maxPeople = 8,
  }) {
    final int safeMaxPeople = maxPeople.clamp(1, 16);
    final List<MockFaceIdentity> output = <MockFaceIdentity>[];

    final int localSlots = mediaItems.isEmpty
        ? 0
        : min((safeMaxPeople * 0.7).ceil(), mediaItems.length);
    if (localSlots > 0) {
      final int stride = max(1, mediaItems.length ~/ localSlots);
      int labelIndex = 0;
      for (int i = 0; i < mediaItems.length && output.length < localSlots; i += stride) {
        final MediaItem media = mediaItems[i];
        output.add(
          MockFaceIdentity(
            label: _labels[labelIndex % _labels.length],
            confidence: _confidenceForSeed(media.id.hashCode),
            localThumbnail: media.thumbnail,
            fromDeviceLibrary: true,
          ),
        );
        labelIndex += 1;
      }
    }

    int sampleIndex = 0;
    while (output.length < safeMaxPeople) {
      output.add(
        MockFaceIdentity(
          label: _labels[output.length % _labels.length],
          confidence: _confidenceForSeed(output.length + sampleIndex + 31),
          mockAssetPath: _sampleAssets[sampleIndex % _sampleAssets.length],
          fromDeviceLibrary: false,
        ),
      );
      sampleIndex += 1;
    }

    return output;
  }

  double _confidenceForSeed(int seed) {
    final Random random = Random(seed.abs());
    return 0.72 + (random.nextDouble() * 0.26);
  }
}
