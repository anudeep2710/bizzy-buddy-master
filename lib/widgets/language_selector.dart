import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers/language_provider.dart';
import '../models/app_language.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);

    return supportedLanguages.when(
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => IconButton(
        icon: const Icon(Icons.error_outline, color: Colors.red),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading languages: $error')),
          );
        },
      ),
      data: (languages) {
        // Ensure the selected language exists in the available languages
        final currentValue = languages.containsKey(selectedLanguage.code)
            ? selectedLanguage.code
            : 'en'; // Fallback to English if selected language not available

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              icon: const Icon(Icons.language),
              isExpanded: true,
              items: languages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Text(
                        _getLanguageEmoji(entry.key),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  final newLanguage = AppLanguage(
                    code: newValue,
                    name: languages[newValue]!,
                    isSelected: true,
                  );
                  await ref
                      .read(selectedLanguageProvider.notifier)
                      .setLanguage(newLanguage);
                }
              },
            ),
          ),
        );
      },
    );
  }

  String _getLanguageEmoji(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'hi':
        return '🇮🇳';
      case 'ta':
        return '🇮🇳';
      case 'te':
        return '🇮🇳';
      case 'ml':
        return '🇮🇳';
      case 'kn':
        return '🇮🇳';
      case 'bn':
        return '🇮🇳';
      case 'gu':
        return '🇮🇳';
      case 'mr':
        return '🇮🇳';
      case 'pa':
        return '🇮🇳';
      case 'ur':
        return '🇵🇰';
      default:
        return '🌐';
    }
  }
}
