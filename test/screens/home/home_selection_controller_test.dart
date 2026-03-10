import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/screens/home/selection_controller.dart';

void main() {
  test('enters selection on long-press start and can clear', () {
    final HomeSelectionController controller = HomeSelectionController();

    controller.startSelection('m1');

    expect(controller.isSelectionMode, isTrue);
    expect(controller.selectedCount, 1);
    expect(controller.isSelected('m1'), isTrue);

    controller.clear();

    expect(controller.isSelectionMode, isFalse);
    expect(controller.selectedCount, 0);
  });

  test('toggle selection selects, deselects and exits mode when empty', () {
    final HomeSelectionController controller = HomeSelectionController();

    controller.startSelection('m1');
    controller.toggleSelection('m2');

    expect(controller.selectedIds, containsAll(<String>{'m1', 'm2'}));
    expect(controller.selectedCount, 2);

    controller.toggleSelection('m1');
    expect(controller.isSelected('m1'), isFalse);
    expect(controller.isSelectionMode, isTrue);

    controller.toggleSelection('m2');
    expect(controller.selectedCount, 0);
    expect(controller.isSelectionMode, isFalse);
  });
}
