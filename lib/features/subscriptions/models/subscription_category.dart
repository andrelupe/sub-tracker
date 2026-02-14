import 'package:flutter/material.dart';

enum SubscriptionCategory {
  entertainment('Entertainment', Icons.movie_outlined, Color(0xFFE11D48)),
  music('Music', Icons.music_note_outlined, Color(0xFFF97316)),
  productivity('Productivity', Icons.work_outline, Color(0xFF3B82F6)),
  gaming('Gaming', Icons.sports_esports_outlined, Color(0xFF8B5CF6)),
  cloud('Cloud Storage', Icons.cloud_outlined, Color(0xFF0891B2)),
  news('News & Media', Icons.newspaper_outlined, Color(0xFF65A30D)),
  fitness('Fitness', Icons.fitness_center_outlined, Color(0xFFEC4899)),
  education('Education', Icons.school_outlined, Color(0xFFD97706)),
  utilities('Utilities', Icons.settings_outlined, Color(0xFF6B7280)),
  other('Other', Icons.category_outlined, Color(0xFF64748B));

  const SubscriptionCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static SubscriptionCategory fromJson(int index) {
    return SubscriptionCategory.values[index];
  }

  int toJson() => index;
}
