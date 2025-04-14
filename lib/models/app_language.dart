import 'package:hive/hive.dart';

part 'app_language.g.dart';

@HiveType(typeId: 5)
class AppLanguage {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isSelected;

  AppLanguage({
    required this.code,
    required this.name,
    this.isSelected = false,
  });

  AppLanguage copyWith({
    String? code,
    String? name,
    bool? isSelected,
  }) {
    return AppLanguage(
      code: code ?? this.code,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
