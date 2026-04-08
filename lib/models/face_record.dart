import 'dart:convert';

class FaceRecord {
  const FaceRecord({
    required this.id,
    required this.personId,
    required this.imagePath,
    required this.embedding,
    required this.createdAt,
  });

  final String id;
  final String personId;
  final String imagePath;
  final List<double> embedding;
  final DateTime createdAt;

  FaceRecord copyWith({
    String? id,
    String? personId,
    String? imagePath,
    List<double>? embedding,
    DateTime? createdAt,
  }) {
    return FaceRecord(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      imagePath: imagePath ?? this.imagePath,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'personId': personId,
      'imagePath': imagePath,
      'embedding': embedding,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  static FaceRecord fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawEmbedding =
        json['embedding'] as List<dynamic>? ?? const <dynamic>[];
    return FaceRecord(
      id: json['id'] as String,
      personId: json['personId'] as String,
      imagePath: json['imagePath'] as String,
      embedding: rawEmbedding
          .map((dynamic value) => (value as num).toDouble())
          .toList(growable: false),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  static FaceRecord? tryDecode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
