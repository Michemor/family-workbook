import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class EmptyContentState extends StatelessWidget {
  const EmptyContentState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.oceanBlue.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book_outlined, size: 48,
                  color: AppTheme.oceanBlue.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            const Text('Content Coming Soon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text('No content has been added for this week yet.\nCheck back soon!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
