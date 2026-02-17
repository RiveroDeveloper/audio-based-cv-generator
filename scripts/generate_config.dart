// Generates web/js/config.js from .env
// Run before: flutter build web
// Usage: dart run scripts/generate_config.dart

import 'dart:io';

void main() {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    stderr.writeln('Error: .env not found. Create it from .env.example');
    exit(1);
  }

  final env = <String, String>{};
  for (final line in envFile.readAsStringSync().split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq > 0) {
      final key = trimmed.substring(0, eq).trim();
      var value = trimmed.substring(eq + 1).trim();
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      } else if (value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }
      env[key] = value;
    }
  }

  const keys = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'ASSEMBLY_API_KEY',
    'OPENROUTER_API_KEY',
  ];

  final entries = keys.map((k) {
    final v = env[k] ?? '';
    final escaped = v.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    return "  $k: '$escaped'";
  });

  final js = '''// Auto-generated from .env - do not commit
window.ENV = {
${entries.join(',\n')}
};
''';

  final out = File('web/js/config.js');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(js);
  print('Generated web/js/config.js');
}
