enum CloudSyncStatus { unsynced, uploading, synced, failed }

class CloudSyncRecord {
  const CloudSyncRecord({
    required this.mediaId,
    required this.status,
    required this.progress,
    required this.updatedAt,
  });

  final String mediaId;
  final CloudSyncStatus status;
  final double progress;
  final DateTime updatedAt;

  bool get isSynced => status == CloudSyncStatus.synced;

  CloudSyncRecord copyWith({
    String? mediaId,
    CloudSyncStatus? status,
    double? progress,
    DateTime? updatedAt,
  }) {
    return CloudSyncRecord(
      mediaId: mediaId ?? this.mediaId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mediaId': mediaId,
      'status': status.name,
      'progress': progress,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static CloudSyncRecord fromJson(Map<String, dynamic> json) {
    final String rawStatus = (json['status'] as String? ?? 'unsynced')
        .toLowerCase();
    final CloudSyncStatus status = CloudSyncStatus.values.firstWhere(
      (CloudSyncStatus candidate) => candidate.name == rawStatus,
      orElse: () => CloudSyncStatus.unsynced,
    );
    final double parsedProgress = (json['progress'] as num?)?.toDouble() ?? 0;
    final DateTime updatedAt =
        DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now().toLocal();

    return CloudSyncRecord(
      mediaId: json['mediaId'] as String,
      status: status,
      progress: parsedProgress.clamp(0, 1),
      updatedAt: updatedAt,
    );
  }
}
