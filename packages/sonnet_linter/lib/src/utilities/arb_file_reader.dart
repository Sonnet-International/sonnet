import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

class ArbFileReader {
  static (Map<String, dynamic>, File) read(File l10nFile) {
    // set up arb file
    final l10n = loadYaml(
      l10nFile.readAsStringSync(),
      recover: true,
    ) as YamlMap?;
    final arbDir = l10n?['arb-dir'] as String? ?? 'lib/l10n';
    final templateArbFile =
        l10n?['template-arb-file'] as String? ?? 'app_en.arb';
    final arbFile = File('${l10nFile.parent.path}/$arbDir/$templateArbFile');

    if (!arbFile.existsSync()) {
      arbFile
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
    }

    return (
      jsonDecode(arbFile.readAsStringSync()) as Map<String, dynamic>,
      arbFile,
    );
  }
}
