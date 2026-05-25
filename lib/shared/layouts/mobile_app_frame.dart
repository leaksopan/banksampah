import 'package:flutter/material.dart';

class MobileAppFrame extends StatelessWidget {
  const MobileAppFrame({super.key, required this.child});

  static const double maxPhoneWidth = 430;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideBrowser = constraints.maxWidth > maxPhoneWidth;

        return ColoredBox(
          color:
              isWideBrowser ? const Color(0xFF303030) : const Color(0xFFEAF7F8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxPhoneWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F8),
                  boxShadow:
                      isWideBrowser
                          ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ]
                          : null,
                ),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(
                      constraints.maxWidth > maxPhoneWidth
                          ? maxPhoneWidth
                          : constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
