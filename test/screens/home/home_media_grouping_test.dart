import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/core/media/day_group.dart';
import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_type.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';
import 'package:nimbus/screens/home/media_grouping.dart';

void main() {
  MediaItem mediaItem({
    required String id,
    required DateTime createdAt,
    required MediaType type,
  }) {
    return MediaItem(
      id: id,
      type: type,
      createdAt: createdAt,
      thumbnail: const PlaceholderThumbnailRef(color: Colors.black),
      isSynced: false,
    );
  }

  test('groups media by day and skips empty days by construction', () {
    final List<MediaItem> items = <MediaItem>[
      mediaItem(
        id: 'a',
        createdAt: DateTime(2026, 3, 6, 10, 0),
        type: MediaType.image,
      ),
      mediaItem(
        id: 'b',
        createdAt: DateTime(2026, 3, 6, 7, 0),
        type: MediaType.video,
      ),
      mediaItem(
        id: 'c',
        createdAt: DateTime(2026, 3, 4, 13, 0),
        type: MediaType.image,
      ),
    ];

    final groups = groupMediaItemsByDay(items);

    expect(groups.length, 2);
    expect(groups.first.dayLabel, '6 Mar');
    expect(groups.last.dayLabel, '4 Mar');
    expect(groups.first.items.length, 2);
    expect(groups.last.items.length, 1);
  });

  test('sorts newest day first and newest media first within each day', () {
    final List<MediaItem> items = <MediaItem>[
      mediaItem(
        id: 'older',
        createdAt: DateTime(2026, 3, 5, 8, 0),
        type: MediaType.image,
      ),
      mediaItem(
        id: 'newer',
        createdAt: DateTime(2026, 3, 6, 8, 0),
        type: MediaType.image,
      ),
      mediaItem(
        id: 'same-day-later',
        createdAt: DateTime(2026, 3, 6, 11, 0),
        type: MediaType.video,
      ),
    ];

    final groups = groupMediaItemsByDay(items);

    expect(groups.map((g) => g.dayLabel), <String>['6 Mar', '5 Mar']);
    expect(groups.first.items.map((i) => i.id), <String>[
      'same-day-later',
      'newer',
    ]);
  });

  test('groups previous years by month with MMM yyyy labels', () {
    final List<MediaItem> items = <MediaItem>[
      mediaItem(
        id: 'a',
        createdAt: DateTime(2025, 3, 18, 10, 0),
        type: MediaType.image,
      ),
      mediaItem(
        id: 'b',
        createdAt: DateTime(2025, 3, 2, 8, 0),
        type: MediaType.video,
      ),
      mediaItem(
        id: 'c',
        createdAt: DateTime(2025, 2, 12, 9, 0),
        type: MediaType.image,
      ),
    ];

    final groups = groupMediaItemsByDay(items);

    expect(groups.map((MediaDayGroup group) => group.dayLabel), <String>[
      'Mar 2025',
      'Feb 2025',
    ]);
    expect(groups.first.items.map((MediaItem item) => item.id), <String>[
      'a',
      'b',
    ]);
  });
}
