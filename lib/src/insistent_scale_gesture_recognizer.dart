import 'package:flutter/gestures.dart';

class InsistentScaleGestureRecognizer extends ScaleGestureRecognizer {
  final _pointers = <int>{};
  bool _isAccepted = false;

  @override
  void startTrackingPointer(int pointer, [Matrix4? transform]) {
    super.startTrackingPointer(pointer, transform);
    _pointers.add(pointer);
    _checkAcceptState(pointer);
  }

  @override
  void stopTrackingPointer(int pointer) {
    super.stopTrackingPointer(pointer);
    _pointers.remove(pointer);
    _checkAcceptState(pointer);
  }

  void _checkAcceptState(int pointer) {
    if (_pointers.length == 2) {
      if (!_isAccepted) {
        _isAccepted = true;
        acceptGesture(pointer);
      }
    } else {
      if (_isAccepted) {
        _isAccepted = false;
        rejectGesture(pointer);
      }
    }
  }
}
