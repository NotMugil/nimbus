import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/screens/home/grid_density.dart';

void main() {
  test(
    'scale down sets five-column density and scale up sets three-column',
    () {
      final HomeGridDensityController controller = HomeGridDensityController();

      expect(controller.density, HomeGridDensity.three);
      expect(controller.crossAxisCount, 3);

      controller.onScaleStart();
      controller.onScaleUpdate(0.85);

      expect(controller.density, HomeGridDensity.five);
      expect(controller.crossAxisCount, 5);

      controller.onScaleEnd();
      controller.onScaleStart();
      controller.onScaleUpdate(1.2);

      expect(controller.density, HomeGridDensity.three);
      expect(controller.crossAxisCount, 3);
    },
  );

  test('switches at most once per gesture to avoid jitter', () {
    final HomeGridDensityController controller = HomeGridDensityController();

    controller.onScaleStart();
    controller.onScaleUpdate(0.7);
    controller.onScaleUpdate(1.2);

    expect(controller.density, HomeGridDensity.five);

    controller.onScaleEnd();
    controller.onScaleStart();
    controller.onScaleUpdate(1.2);

    expect(controller.density, HomeGridDensity.three);
  });
}
