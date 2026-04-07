class FaceAlbum {
  const FaceAlbum({required this.personId, required this.imagePaths});

  final String personId;
  final List<String> imagePaths;

  int get photoCount => imagePaths.length;
  String? get coverImagePath => imagePaths.isEmpty ? null : imagePaths.first;
}
