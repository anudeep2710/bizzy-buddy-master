import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import '../../models/app_language.dart';
import '../../models/sale.dart';
import '../../app/providers/language_provider.dart';
import '../../utils/pdf_export.dart';
import '../../utils/pdf_translator.dart';
import 'package:hive/hive.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isExporting = false;
  String? _exportedFilePath;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(selectedLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Language: ${currentLanguage.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              icon: Icons.picture_as_pdf,
              title: 'PDF Report',
              subtitle: 'Export sales data as a PDF document',
              onTap: () => _exportAsPdf(currentLanguage),
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              icon: Icons.table_chart,
              title: 'Excel Spreadsheet',
              subtitle: 'Export data as an Excel spreadsheet',
              onTap: () {
                // Show dialog to warn user about Excel export issues
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Excel Export Not Available'),
                    content: const Text(
                        'Excel export functionality is currently being updated to '
                        'support the latest version of the Excel package. '
                        'Please use PDF export instead until this feature is fixed.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            if (_isExporting)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Exporting data...'),
                  ],
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            else if (_exportedFilePath != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Export completed successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'File saved to: $_exportedFilePath',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openExportedFile(),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open File'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportAsPdf(AppLanguage language) async {
    // Show language selection dialog
    final selectedLanguage = await _showLanguageSelectionDialog(language);
    if (selectedLanguage == null) return; // User cancelled

    setState(() {
      _isExporting = true;
      _error = null;
      _exportedFilePath = null;
    });

    try {
      debugPrint(
          'Exporting PDF in language: ${selectedLanguage.name} (${selectedLanguage.code})');

      // Get the PDF exporter for the selected language
      final pdfExporter = ref.read(pdfExportProvider(selectedLanguage.code));
      final pdfTranslator =
          ref.read(pdfTranslatorProvider(selectedLanguage.code));

      // Test translation to verify it's working
      final testTranslation = await pdfTranslator.translateText(
          'Sales Report', selectedLanguage.code);
      debugPrint('Test translation of "Sales Report": $testTranslation');

      // Get sales data from Hive
      final salesBox = Hive.box<Sale>('sales');
      final sales = salesBox.values.toList();

      debugPrint('Found ${sales.length} sales records to export');

      if (sales.isEmpty) {
        setState(() {
          _isExporting = false;
          _error = 'No sales data available to export';
        });
        return;
      }

      // Export the data to PDF
      final file =
          await pdfExporter.exportSalesData(sales, selectedLanguage.code);
      debugPrint('PDF saved to: ${file.path}');

      setState(() {
        _isExporting = false;
        _exportedFilePath = file.path;
      });

      // Try to open the PDF
      try {
        await _openExportedFile();
      } catch (e) {
        debugPrint('Error opening PDF: $e');
        // We don't want to set error state here as the export was successful
      }
    } catch (e, stackTrace) {
      debugPrint('Error exporting PDF: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        _isExporting = false;
        _error = e.toString();
      });
    }
  }

  Future<AppLanguage?> _showLanguageSelectionDialog(
      AppLanguage currentLanguage) async {
    final supportedLanguagesAsync = ref.watch(supportedLanguagesProvider);

    return supportedLanguagesAsync.when(
      data: (supportedLanguages) async {
        return showDialog<AppLanguage>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Export Language'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: supportedLanguages.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.value),
                      trailing: currentLanguage.code == entry.key
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        Navigator.of(context).pop(
                          AppLanguage(
                            code: entry.key,
                            name: entry.value,
                            isSelected: false,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
      loading: () async {
        // Show loading dialog and wait for data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading language options...')),
        );
        return currentLanguage; // Default to current language while loading
      },
      error: (error, stack) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading languages: $error')),
        );
        return currentLanguage; // Default to current language on error
      },
    );
  }

  Future<void> _openExportedFile() async {
    if (_exportedFilePath != null) {
      final result = await OpenFile.open(_exportedFilePath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: ${result.message}')),
          );
        }
      }
    }
  }
}
