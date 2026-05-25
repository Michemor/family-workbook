import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const PageIndicator(this.count, this.currentIndex, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stepLabels = ['Insights', 'Assessment', 'Activities'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 28 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 2),
                Text(stepLabels[i],
                    style: const TextStyle(
                        color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        );
      }),
    );
  }
}
