import 'package:intl/intl.dart';
import 'package:nimbus/core/media/day_group.dart';
import 'package:nimbus/core/media/media_item.dart';

List<MediaDayGroup> groupMediaItemsByDay(List<MediaItem> items) {
  final DateFormat dayLabelFormatter = DateFormat('d MMM', 'en_US');
  final DateFormat monthLabelFormatter = DateFormat('MMM yyyy', 'en_US');
  final int currentYear = DateTime.now().year;
  final List<MediaItem> sortedItems = List<MediaItem>.from(items)
    ..sort((MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt));

  final Map<DateTime, List<MediaItem>> groups = <DateTime, List<MediaItem>>{};
  for (final MediaItem item in sortedItems) {
    final DateTime localDate = item.createdAt.toLocal();
    final bool shouldGroupByMonth = localDate.year < currentYear;
    final DateTime key = shouldGroupByMonth
        ? DateTime(localDate.year, localDate.month)
        : DateTime(localDate.year, localDate.month, localDate.day);
    groups.putIfAbsent(key, () => <MediaItem>[]).add(item);
  }

  final List<DateTime> sortedDays = groups.keys.toList()
    ..sort((DateTime a, DateTime b) => b.compareTo(a));

  return sortedDays
      .map((DateTime day) {
        final List<MediaItem> dayItems = groups[day]!
          ..sort(
            (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
          );
        final bool isMonthlyGroup = day.year < currentYear;
        return MediaDayGroup(
          dayLabel: isMonthlyGroup
              ? monthLabelFormatter.format(day)
              : dayLabelFormatter.format(day),
          day: day,
          items: List<MediaItem>.unmodifiable(dayItems),
        );
      })
      .toList(growable: false);
}
