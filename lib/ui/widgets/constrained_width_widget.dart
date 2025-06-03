import 'package:flutter/material.dart';

class ConstrainedWidthWidget extends StatelessWidget {
  /// [ConstrainedWidthWidget] used consistently to limit the width of widgets
  /// regardless of the screen width
  final Widget? child; // Any widget
  const ConstrainedWidthWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    /// [mediaWidth] is the width of the screen
    final mediaWidth = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500), // max 500 pixels
      // 80% screen width when screen is less than 500 pixels
      child: SizedBox(width: mediaWidth * 0.8, child: child),
    );
  }
}
