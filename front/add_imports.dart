import 'dart:io';

void main() {
  final files = [
    'lib/screens/waste/waste_screen.dart',
    'lib/screens/suppliers/suppliers_screen.dart',
    'lib/screens/reserves/reserves_screen.dart',
    'lib/screens/debts/debts_screen.dart',
    'lib/screens/expenses/expenses_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    if (!content.contains('gradient_fab.dart')) {
      content = content.replaceFirst("import '../../theme/app_colors.dart';", 
          "import '../../theme/app_colors.dart';\nimport '../../widgets/gradient_fab.dart';\nimport 'package:lucide_icons/lucide_icons.dart';");
    }
    
    file.writeAsStringSync(content);
    print('Updated \$path');
  }
}
