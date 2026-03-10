import 'package:nimbus/core/media/media_item.dart';

class MediaDayGroup {
  const MediaDayGroup({
    required this.dayLabel,
    required this.day,
    required this.items,
  });

  final String dayLabel;
  final DateTime day;
  final List<MediaItem> items;
}
