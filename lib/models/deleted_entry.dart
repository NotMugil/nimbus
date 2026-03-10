class RecentlyDeletedEntry {
  const RecentlyDeletedEntry({required this.mediaId, required this.deletedAt});

  final String mediaId;
  final DateTime deletedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mediaId': mediaId,
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  static RecentlyDeletedEntry fromJson(Map<String, dynamic> json) {
    return RecentlyDeletedEntry(
      mediaId: json['mediaId'] as String,
      deletedAt:
          DateTime.tryParse(json['deletedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now().toLocal(),
    );
  }
}
