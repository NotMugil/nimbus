import 'dart:convert';

class AppAlbum {
  const AppAlbum({
    required this.id,
    required this.name,
    required this.mediaIds,
    this.localMediaPaths = const <String>[],
    this.coverMediaId,
    this.coverLocalPath,
    required this.createdAt,
    this.faceRecognitionEnabled = true,
  });

  final String id;
  final String name;
  final List<String> mediaIds;
  final List<String> localMediaPaths;
  final String? coverMediaId;
  final String? coverLocalPath;
  final DateTime createdAt;
  final bool faceRecognitionEnabled;

  AppAlbum copyWith({
    String? id,
    String? name,
    List<String>? mediaIds,
    List<String>? localMediaPaths,
    String? coverMediaId,
    String? coverLocalPath,
    bool clearCoverMediaId = false,
    bool clearCoverLocalPath = false,
    DateTime? createdAt,
    bool? faceRecognitionEnabled,
  }) {
    return AppAlbum(
      id: id ?? this.id,
      name: name ?? this.name,
      mediaIds: mediaIds ?? this.mediaIds,
      localMediaPaths: localMediaPaths ?? this.localMediaPaths,
      coverMediaId: clearCoverMediaId
          ? null
          : (coverMediaId ?? this.coverMediaId),
      coverLocalPath: clearCoverLocalPath
          ? null
          : (coverLocalPath ?? this.coverLocalPath),
      createdAt: createdAt ?? this.createdAt,
      faceRecognitionEnabled:
          faceRecognitionEnabled ?? this.faceRecognitionEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'mediaIds': mediaIds,
      'localMediaPaths': localMediaPaths,
      'coverMediaId': coverMediaId,
      'coverLocalPath': coverLocalPath,
      'createdAt': createdAt.toIso8601String(),
      'faceRecognitionEnabled': faceRecognitionEnabled,
    };
  }

  static AppAlbum fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMediaIds =
        (json['mediaIds'] as List<dynamic>? ?? const <dynamic>[]);
    final List<dynamic> rawLocalPaths =
        (json['localMediaPaths'] as List<dynamic>? ?? const <dynamic>[]);

    return AppAlbum(
      id: json['id'] as String,
      name: json['name'] as String,
      mediaIds: rawMediaIds.cast<String>(),
      localMediaPaths: rawLocalPaths.cast<String>(),
      coverMediaId: json['coverMediaId'] as String?,
      coverLocalPath: json['coverLocalPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      faceRecognitionEnabled:
          (json['faceRecognitionEnabled'] as bool?) ?? true,
    );
  }

  static String encodeList(List<AppAlbum> albums) {
    final List<Map<String, dynamic>> payload = albums
        .map((AppAlbum album) => album.toJson())
        .toList(growable: false);
    return jsonEncode(payload);
  }

  static List<AppAlbum> decodeList(String raw) {
    if (raw.trim().isEmpty) {
      return const <AppAlbum>[];
    }
    final List<dynamic> payload = jsonDecode(raw) as List<dynamic>;
    return payload
        .map((dynamic item) => AppAlbum.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
