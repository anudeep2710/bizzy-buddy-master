import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_language.dart';

/// Provider for the current app language
final appLanguageProvider = StateProvider<String>((ref) {
  // Get the language from Hive or default to English
  final languageBox = Hive.box<AppLanguage>('app_language');
  if (languageBox.isEmpty) {
    // Initialize with default language if not set
    final defaultLanguage = AppLanguage(
      code: 'en',
      name: 'English',
      isSelected: true,
    );
    languageBox.add(defaultLanguage);
    return 'en';
  }

  // Find the selected language
  final selectedLanguage = languageBox.values.firstWhere(
    (lang) => lang.isSelected,
    orElse: () => languageBox.values.first,
  );

  return selectedLanguage.code;
});
