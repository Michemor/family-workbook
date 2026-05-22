import 'package:flutter/material.dart';

/// Maps a Firestore icon-name string to a Flutter [IconData].
///
/// Add new entries here whenever a new game type is created.
IconData iconFromString(String name) {
  switch (name) {
    case 'quiz':
      return Icons.quiz_rounded;
    case 'grid_view':
      return Icons.grid_view_rounded;
    case 'forum':
      return Icons.forum_rounded;
    case 'psychology':
      return Icons.psychology_rounded;
    case 'extension':
      return Icons.extension_rounded;
    case 'emoji_events':
      return Icons.emoji_events_rounded;
    case 'family_restroom':
      return Icons.family_restroom_rounded;
    case 'draw':
      return Icons.draw_rounded;
    case 'casino':
      return Icons.casino_rounded;
    case 'sports_esports':
    default:
      return Icons.sports_esports_rounded;
  }
}
