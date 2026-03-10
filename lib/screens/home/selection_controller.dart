import 'dart:collection';

import 'package:flutter/foundation.dart';

class HomeSelectionController extends ChangeNotifier {
  final Set<String> _selectedIds = <String>{};
  bool _isSelectionMode = false;

  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedIds.length;
  UnmodifiableSetView<String> get selectedIds =>
      UnmodifiableSetView<String>(_selectedIds);

  bool isSelected(String mediaId) {
    return _selectedIds.contains(mediaId);
  }

  void startSelection(String mediaId) {
    _isSelectionMode = true;
    _selectedIds.add(mediaId);
    notifyListeners();
  }

  void toggleSelection(String mediaId) {
    if (!_isSelectionMode) {
      return;
    }

    if (_selectedIds.contains(mediaId)) {
      _selectedIds.remove(mediaId);
    } else {
      _selectedIds.add(mediaId);
    }

    if (_selectedIds.isEmpty) {
      _isSelectionMode = false;
    }

    notifyListeners();
  }

  void clear() {
    if (_selectedIds.isEmpty && !_isSelectionMode) {
      return;
    }

    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }
}
