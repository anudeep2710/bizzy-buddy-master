import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/app_language.dart';
import 'translator_provider.dart';

// Default supported Indian languages
const Map<String, String> defaultLanguages = {
  'en': 'English',
  'hi': 'Hindi',
  'ta': 'Tamil',
  'te': 'Telugu',
  'ml': 'Malayalam',
  'kn': 'Kannada',
  'bn': 'Bengali',
  'gu': 'Gujarati',
  'mr': 'Marathi',
  'pa': 'Punjabi',
  'ur': 'Urdu'
};

final supportedLanguagesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  try {
    final translator = ref.watch(translatorServiceProvider);
    final languagesMap = await translator.getSupportedLanguages();

    if (languagesMap.isEmpty) {
      return defaultLanguages;
    }

    // Prefer the returned languages but ensure we have at least the default ones
    return {...defaultLanguages, ...languagesMap};
  } catch (e) {
    // Fallback to default languages if API fails
    print('Error loading supported languages: $e');
    return defaultLanguages;
  }
});

final languageBoxProvider = Provider<Box<AppLanguage>>((ref) {
  return Hive.box<AppLanguage>('languages');
});

final selectedLanguageProvider =
    StateNotifierProvider<SelectedLanguageNotifier, AppLanguage>((ref) {
  final box = ref.watch(languageBoxProvider);
  return SelectedLanguageNotifier(box);
});

class SelectedLanguageNotifier extends StateNotifier<AppLanguage> {
  final Box<AppLanguage> _box;

  SelectedLanguageNotifier(this._box)
      : super(_box.values.firstWhere(
          (lang) => lang.isSelected,
          orElse: () =>
              AppLanguage(code: 'en', name: 'English', isSelected: true),
        ));

  Future<void> setLanguage(AppLanguage language) async {
    for (var lang in _box.values) {
      await _box.put(
        lang.code,
        lang.copyWith(isSelected: lang.code == language.code),
      );
    }
    if (!_box.containsKey(language.code)) {
      await _box.put(language.code, language);
    }
    state = language;
  }

  Future<void> initializeLanguages(
      Map<String, String> supportedLanguages) async {
    // Initialize with default languages first
    for (var entry in defaultLanguages.entries) {
      if (!_box.containsKey(entry.key)) {
        await _box.put(
          entry.key,
          AppLanguage(
            code: entry.key,
            name: entry.value,
            isSelected: entry.key == 'en', // English is selected by default
          ),
        );
      }
    }

    // Then add any additional languages from the API
    for (var entry in supportedLanguages.entries) {
      if (!_box.containsKey(entry.key)) {
        await _box.put(
          entry.key,
          AppLanguage(
            code: entry.key,
            name: entry.value,
            isSelected: false,
          ),
        );
      }
    }
  }
}

final translationProvider =
    FutureProvider.family<String, String>((ref, text) async {
  final translator = ref.watch(translatorServiceProvider);
  final selectedLang = ref.watch(selectedLanguageProvider);

  if (selectedLang.code == 'en') return text;

  try {
    final response = await translator.translate(
      text: text,
      targetLanguage: selectedLang.code,
    );
    return response['translated_text'] as String;
  } catch (e) {
    return text; // Fallback to original text if translation fails
  }
});
