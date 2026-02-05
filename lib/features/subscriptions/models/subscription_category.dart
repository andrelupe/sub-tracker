import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'subscription_category.g.dart';

@HiveType(typeId: 2)
enum SubscriptionCategory {
  @HiveField(0)
  entertainment('Entertainment', Icons.movie_outlined, Color(0xFFE11D48)),
  @HiveField(1)
  music('Music', Icons.music_note_outlined, Color(0xFFF97316)),
  @HiveField(2)
  productivity('Productivity', Icons.work_outline, Color(0xFF3B82F6)),
  @HiveField(3)
  gaming('Gaming', Icons.sports_esports_outlined, Color(0xFF8B5CF6)),
  @HiveField(4)
  cloud('Cloud Storage', Icons.cloud_outlined, Color(0xFF06B6D4)),
  @HiveField(5)
  news('News & Media', Icons.newspaper_outlined, Color(0xFF84CC16)),
  @HiveField(6)
  fitness('Fitness', Icons.fitness_center_outlined, Color(0xFFEC4899)),
  @HiveField(7)
  education('Education', Icons.school_outlined, Color(0xFFF59E0B)),
  @HiveField(8)
  utilities('Utilities', Icons.settings_outlined, Color(0xFF6B7280)),
  @HiveField(9)
  other('Other', Icons.category_outlined, Color(0xFF64748B));

  const SubscriptionCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
