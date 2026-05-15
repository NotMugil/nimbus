import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_type.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';
import 'package:nimbus/services/mock_face_recognition_service.dart';

void main() {
  group('MockFaceRecognitionService', () {
    test('blends local thumbnails with mock assets', () {
      final MockFaceRecognitionService service = MockFaceRecognitionService();
      final List<MediaItem> media = <MediaItem>[
        MediaItem(
          id: 'asset-1',
          type: MediaType.image,
          createdAt: DateTime(2026),
          thumbnail: const PlaceholderThumbnailRef(color: Color(0xFF121212)),
          isSynced: false,
        ),
      ];

      final List<MockFaceIdentity> result = service.buildPeoplePreview(
        media,
        maxPeople: 4,
      );

      expect(result, hasLength(4));
      expect(result.any((MockFaceIdentity item) => item.localThumbnail != null), isTrue);
      expect(result.any((MockFaceIdentity item) => item.mockAssetPath != null), isTrue);
    });

    test('creates all-mock identities when local media is empty', () {
      final MockFaceRecognitionService service = MockFaceRecognitionService();
      final List<MockFaceIdentity> result = service.buildPeoplePreview(
        const <MediaItem>[],
        maxPeople: 3,
      );

      expect(result, hasLength(3));
      expect(
        result.every((MockFaceIdentity item) => item.mockAssetPath != null),
        isTrue,
      );
    });
  });
}
