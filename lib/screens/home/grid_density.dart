import 'package:flutter/foundation.dart';

enum HomeGridDensity { three, five }

class HomeGridDensityController extends ChangeNotifier {
  HomeGridDensityController({
    HomeGridDensity initialDensity = HomeGridDensity.three,
    this.pinchOutThreshold = 1.08,
    this.pinchInThreshold = 0.92,
  }) : _density = initialDensity;

  final double pinchOutThreshold;
  final double pinchInThreshold;

  HomeGridDensity _density;
  bool _didSwitchInCurrentGesture = false;

  HomeGridDensity get density => _density;

  int get crossAxisCount => _density == HomeGridDensity.three ? 3 : 5;

  void toggle() {
    _density = _density == HomeGridDensity.three
        ? HomeGridDensity.five
        : HomeGridDensity.three;
    notifyListeners();
  }

  void onScaleStart() {
    _didSwitchInCurrentGesture = false;
  }

  void onScaleEnd() {
    _didSwitchInCurrentGesture = false;
  }

  void onScaleUpdate(double scale) {
    if (_didSwitchInCurrentGesture) {
      return;
    }

    if (scale >= pinchOutThreshold && _density != HomeGridDensity.three) {
      _density = HomeGridDensity.three;
      _didSwitchInCurrentGesture = true;
      notifyListeners();
      return;
    }

    if (scale <= pinchInThreshold && _density != HomeGridDensity.five) {
      _density = HomeGridDensity.five;
      _didSwitchInCurrentGesture = true;
      notifyListeners();
    }
  }
}
