import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/language_provider.dart';
import '../../models/app_language.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  @override
  void initState() {
    super.initState();
    _initializeLanguages();
  }

  Future<void> _initializeLanguages() async {
    final supportedLanguages =
        await ref.read(supportedLanguagesProvider.future);
    await ref
        .read(selectedLanguageProvider.notifier)
        .initializeLanguages(supportedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
      ),
      body: supportedLanguages.when(
        data: (languages) {
          return ListView.builder(
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final languageCode = languages.keys.elementAt(index);
              final languageName = languages[languageCode]!;
              final isSelected = selectedLanguage.code == languageCode;

              return ListTile(
                title: Text(languageName),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  ref.read(selectedLanguageProvider.notifier).setLanguage(
                        AppLanguage(
                          code: languageCode,
                          name: languageName,
                          isSelected: true,
                        ),
                      );
                  Navigator.pop(context);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading languages: $error'),
        ),
      ),
    );
  }
}
