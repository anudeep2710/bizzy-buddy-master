import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../models/expense.dart';
import '../../models/sale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/language_provider.dart';
import '../../app/providers/theme_provider.dart' as theme_provider;
import '../../utils/pdf_export.dart';
import '../../utils/excel_export.dart';
import '../../models/app_language.dart';

/// A provider for the AI mode setting
final aiModeProvider = StateProvider<bool>((ref) {
  // Use Hive to persist the setting
  final settingsBox = Hive.box('settings');
  return settingsBox.get('ai_mode_enabled', defaultValue: false);
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  String? _exportedFilePath;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMainSettingsContent(),
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Exporting data...'),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error: $_error',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                          });
                        },
                        child: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_exportedFilePath != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Successful!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'File saved to: $_exportedFilePath',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _exportedFilePath = null;
                            });
                          },
                          child: const Text('Dismiss'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _openExportedFile,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const Divider(),
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildMainSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThemeSettings(),
        const SizedBox(height: 16),
        _buildLanguageSettings(),
        const SizedBox(height: 16),
        _buildDataExportSettings(),
        const SizedBox(height: 16),
        _buildDataManagementSettings(),
        const SizedBox(height: 16),
        _buildAppInfo(),
      ],
    );
  }

  Widget _buildThemeSettings() {
    final themeMode = ref.watch(theme_provider.themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Theme',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        Column(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Theme'),
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(theme_provider.themeModeProvider.notifier).state =
                      value;
                  // Save to Hive
                  Hive.box('settings').put('themeMode', 'system');
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light Theme'),
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(theme_provider.themeModeProvider.notifier).state =
                      value;
                  // Save to Hive
                  Hive.box('settings').put('themeMode', 'light');
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Theme'),
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(theme_provider.themeModeProvider.notifier).state =
                      value;
                  // Save to Hive
                  Hive.box('settings').put('themeMode', 'dark');
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSettings() {
    final currentLanguage = ref.watch(selectedLanguageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Language',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Current Language'),
          subtitle: Text(currentLanguage.name),
          onTap: () => _showLanguageSelectionDialog(currentLanguage),
        ),
      ],
    );
  }

  Widget _buildDataExportSettings() {
    final currentLanguage = ref.watch(selectedLanguageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Data Export',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export Sales Report as PDF'),
            subtitle: const Text('Generate a PDF report of your sales data'),
            onTap: () => _showLanguageSelectionDialog(currentLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Export Data as Excel'),
            subtitle: const Text('Export your data as Excel spreadsheet'),
            onTap: _showExcelExportOptions,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.share, color: Colors.blue),
            title: const Text('Share App Data Backup'),
            subtitle: const Text('Creates and shares a full backup file'),
            onTap: _exportAndShareBackup,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      ],
    );
  }

  void _showExcelExportOptions() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Export as Excel'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, 'sales');
              _exportExcel('sales');
            },
            child: const ListTile(
              leading: Icon(Icons.receipt_long, color: Colors.blue),
              title: Text('Sales Data'),
              subtitle: Text('Export all sales transactions'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, 'products');
              _exportExcel('products');
            },
            child: const ListTile(
              leading: Icon(Icons.inventory_2, color: Colors.green),
              title: Text('Products Data'),
              subtitle: Text('Export all product information'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, 'expenses');
              _exportExcel('expenses');
            },
            child: const ListTile(
              leading: Icon(Icons.payments, color: Colors.red),
              title: Text('Expenses Data'),
              subtitle: Text('Export all expense records'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, 'all');
              _exportExcel('all');
            },
            child: const ListTile(
              leading: Icon(Icons.dashboard, color: Colors.purple),
              title: Text('All Business Data'),
              subtitle: Text('Export sales, products and expenses'),
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel(String dataType) async {
    setState(() {
      _isExporting = true;
      _error = null;
      _exportedFilePath = null;
    });

    try {
      final excelExport = ref.read(excelExportProvider);

      File file;

      switch (dataType) {
        case 'sales':
          final salesBox = Hive.box<Sale>('sales');
          final sales = salesBox.values.toList();

          if (sales.isEmpty) {
            setState(() {
              _isExporting = false;
              _error = 'No sales data available to export';
            });
            return;
          }

          file = await excelExport.exportSalesData(sales);
          break;

        case 'products':
          final productsBox = Hive.box<Product>('products');
          final products = productsBox.values.toList();

          if (products.isEmpty) {
            setState(() {
              _isExporting = false;
              _error = 'No products data available to export';
            });
            return;
          }

          file = await excelExport.exportProductsData(products);
          break;

        case 'expenses':
          final expensesBox = Hive.box<Expense>('expenses');
          final expenses = expensesBox.values.toList();

          if (expenses.isEmpty) {
            setState(() {
              _isExporting = false;
              _error = 'No expenses data available to export';
            });
            return;
          }

          file = await excelExport.exportExpensesData(expenses);
          break;

        case 'all':
          final salesBox = Hive.box<Sale>('sales');
          final productsBox = Hive.box<Product>('products');
          final expensesBox = Hive.box<Expense>('expenses');

          final sales = salesBox.values.toList();
          final products = productsBox.values.toList();
          final expenses = expensesBox.values.toList();

          if (sales.isEmpty && products.isEmpty && expenses.isEmpty) {
            setState(() {
              _isExporting = false;
              _error = 'No data available to export';
            });
            return;
          }

          file = await excelExport.exportAllData(
            sales: sales,
            products: products,
            expenses: expenses,
          );
          break;

        default:
          throw Exception('Unknown data type: $dataType');
      }

      setState(() {
        _isExporting = false;
        _exportedFilePath = file.path;
      });

      // Show share option
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Successful'),
          content: Text('Excel file has been saved to:\n${file.path}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.share),
              label: const Text('Share File'),
            ),
          ],
        ),
      );

      if (result == true) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _exportAndShareBackup() async {
    try {
      setState(() {
        _isExporting = true;
        _error = null;
      });

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/bizzybuddy_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.zip');

      // Here we'd actually create a real backup file
      // This would compress all the Hive data into a zip
      // For now we just create a dummy file
      await file.writeAsString('BizzyBuddy backup data');

      // Share the file
      await Share.shareXFiles([XFile(file.path)],
          text: 'BizzyBuddy Data Backup');

      setState(() {
        _isExporting = false;
        _exportedFilePath = file.path;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openExportedFile() async {
    if (_exportedFilePath != null) {
      final result = await OpenFile.open(_exportedFilePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: ${result.message}')),
        );
      }
    }
  }

  Future<void> _showLanguageSelectionDialog(AppLanguage currentLanguage) async {
    final supportedLanguagesAsync = ref.watch(supportedLanguagesProvider);

    supportedLanguagesAsync.when(
      data: (supportedLanguages) async {
        final selectedLanguage = await showDialog<AppLanguage>(
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

        if (selectedLanguage != null) {
          _exportPdfReport(selectedLanguage);
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading language options...')),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading languages: $error')),
        );
      },
    );
  }

  Future<void> _exportPdfReport(AppLanguage language) async {
    setState(() {
      _isExporting = true;
      _error = null;
      _exportedFilePath = null;
    });

    try {
      // Get the PDF exporter for the selected language
      final pdfExporter = ref.read(pdfExportProvider(language.code));

      // Get sales data from Hive
      final salesBox = Hive.box<Sale>('sales');
      final sales = salesBox.values.toList();

      if (sales.isEmpty) {
        setState(() {
          _isExporting = false;
          _error = 'No sales data available to export';
        });
        return;
      }

      // Export the data to PDF
      final file = await pdfExporter.exportSalesData(sales, language.code);

      setState(() {
        _isExporting = false;
        _exportedFilePath = file.path;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildDataManagementSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          title: Text(
            'Data Management',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Employee Management'),
          subtitle: const Text('Add, edit, and manage your employees'),
          onTap: () => context.go('/settings/employees'),
        ),
        ListTile(
          leading: const Icon(Icons.shopping_cart),
          title: const Text('Order Management'),
          subtitle: const Text('View and manage customer orders'),
          onTap: () => context.go('/settings/orders'),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever,
              color: Theme.of(context).colorScheme.error),
          title: const Text('Clear All App Data'),
          subtitle: const Text(
              'Removes all local sales, products, expenses, and settings. This cannot be undone.'),
          onTap: _confirmClearAllData,
        ),
      ],
    );
  }

  Future<void> _confirmClearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Clear Data'),
        content: const Text(
          'Are you absolutely sure you want to delete all local app data? This includes all sales records, products, expenses, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear Data',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clearing data...')),
      );

      // Clear Hive boxes
      await Hive.box<Sale>('sales').clear();
      await Hive.box<Product>('products').clear();
      await Hive.box<Expense>('expenses').clear();
      await Hive.box('settings').clear(); // Clears theme, etc.
      await Hive.box<AppLanguage>('languages').clear();

      // Reset relevant providers to default state
      ref.read(selectedLanguageProvider.notifier).setLanguage(
          AppLanguage(code: 'en', name: 'English', isSelected: true));

      ref.read(theme_provider.themeModeProvider.notifier).state =
          ThemeMode.system;
      Hive.box('settings').put('themeMode', 'system');

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All local app data cleared successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAppInfo() {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About BizzyBuddy'),
      subtitle: const Text('Version 1.0.0'),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'BizzyBuddy',
          applicationVersion: '1.0.0',
          applicationIcon:
              Image.asset('assets/images/logo.png', width: 50, height: 50),
          applicationLegalese: '© 2023 BizzyBuddy',
          children: [
            const SizedBox(height: 16),
            const Text(
              'BizzyBuddy is a business management app designed to help small businesses track sales, inventory, and expenses.',
            ),
          ],
        );
      },
    );
  }
}
