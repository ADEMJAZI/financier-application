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

    // Pattern for FloatingActionButton.extended(...)
    final RegExp extRegExp = RegExp(r"FloatingActionButton\.extended\(\s*(?:heroTag:\s*null,\s*)?onPressed:\s*\(\)\s*=>\s*([^,]+),\s*icon:\s*const\s*Icon\(Icons\.[a-zA-Z_]+\),\s*label:\s*const\s*Text\('([^']+)'\),?\s*\)");
    
    content = content.replaceAllMapped(extRegExp, (match) {
      return "GradientFAB(icon: LucideIcons.plus, label: '${match.group(2)}', onPressed: () => ${match.group(1)})";
    });
    
    // Pattern for regular FloatingActionButton(...)
    final RegExp normalRegExp = RegExp(r"FloatingActionButton\(\s*(?:heroTag:\s*null,\s*)?onPressed:\s*\(\)\s*=>\s*([^,]+),\s*child:\s*const\s*Icon\(Icons\.[a-zA-Z_]+\),?\s*\)");
    
    content = content.replaceAllMapped(normalRegExp, (match) {
      return "GradientFAB(icon: LucideIcons.plus, onPressed: () => ${match.group(1)})";
    });
    
    file.writeAsStringSync(content);
    print('Updated \$path');
  }
}
