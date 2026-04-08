import 'dart:math' as math;

class FaceMatchService {
  const FaceMatchService({this.defaultThreshold = 0.8});

  final double defaultThreshold;

  double calculateEuclideanDistance(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError(
        'Embeddings must have the same dimension '
        '(${embedding1.length} != ${embedding2.length}).',
      );
    }

    double sum = 0;
    for (int i = 0; i < embedding1.length; i++) {
      final double delta = embedding1[i] - embedding2[i];
      sum += delta * delta;
    }

    return math.sqrt(sum);
  }

  bool isSamePerson(
    List<double> embedding1,
    List<double> embedding2, {
    double? threshold,
  }) {
    final double distance = calculateEuclideanDistance(embedding1, embedding2);
    return distance < (threshold ?? defaultThreshold);
  }
}
