import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

class SelectionActionButton extends StatelessWidget {
  const SelectionActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.width,
  });

  final String label;
  final String icon;
  final bool enabled;
  final Future<void> Function() onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final Widget button = SizedBox(
      height: 68,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 20,
              child: Center(
                child: Iconify(icon, size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 26,
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (width == null) {
      return button;
    }
    return SizedBox(width: width, child: button);
  }
}
