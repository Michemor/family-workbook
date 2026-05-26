import 'package:flutter/material.dart';

IconData iconFromString(String? iconName) {
  switch (iconName?.toLowerCase()) {
    case 'school':
    case 'school_rounded':
      return Icons.school_rounded;
    case 'people':
    case 'people_rounded':
      return Icons.people_rounded;
    case 'emoji_events':
    case 'emoji_events_rounded':
      return Icons.emoji_events_rounded;
    case 'chat':
    case 'chat_rounded':
      return Icons.chat_rounded;
    case 'verified_user':
    case 'verified_user_rounded':
      return Icons.verified_user_rounded;
    case 'lock':
    case 'lock_outline':
      return Icons.lock_outline;
    case 'article':
    case 'article_outlined':
      return Icons.article_outlined;
    case 'stars':
    case 'stars_rounded':
      return Icons.stars_rounded;
    case 'assessment':
    case 'assessment_rounded':
      return Icons.assessment_rounded;
    case 'psychology':
    case 'psychology_rounded':
      return Icons.psychology_rounded;
    case 'groups':
    case 'groups_rounded':
      return Icons.groups_rounded;
    case 'favorite':
    case 'favorite_rounded':
      return Icons.favorite_rounded;
    case 'check_circle':
    case 'check_circle_rounded':
      return Icons.check_circle_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}
