import 'dart:convert';
import 'dart:io';

import 'package:sonnet_generator/sonnet_generator.dart';

class ArbFileReader {
  static (Map<String, dynamic>, File) read(L10nConfig l10nFile) {
    final arbFile = File(l10nFile.templateFilePath);

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
