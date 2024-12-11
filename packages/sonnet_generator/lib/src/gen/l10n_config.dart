import 'dart:io';
import 'package:yaml/yaml.dart' as yaml;

//possible configuration from l10n.yaml
//https://docs.google.com/document/d/10e0saTfAv32OZLRmONy866vnaw0I2jwL8zukykpgWBc/edit#heading=h.upij01jgi58m

class L10nConfig {
  L10nConfig({
    required this.arbDir,
    required this.templateArbFile,
    required this.outputLocalizationFile,
    required this.outputDir,
    required this.outputClass,
    this.syntheticPackage = true,
  });

  String arbDir;
  String? outputDir;
  String outputLocalizationFile;
  String templateArbFile;
  String outputClass;
  bool syntheticPackage;

  String get finalOutputDir => syntheticPackage
      ? '.dart_tool/flutter_gen/gen_l10n'
      : outputDir ?? arbDir;

  String get packageImport {
    return syntheticPackage
        ? 'package:flutter_gen/gen_l10n/sonnet_localizations.dart'
        : 'package:$_currentPackageName/$finalOutputDir/sonnet_localizations.dart';
  }

  String get _currentPackageName {
    final pubspec = File('pubspec.yaml');
    final pubspecString = pubspec.readAsStringSync();
    final pubspecYaml =
        yaml.loadYamlDocument(pubspecString).contents.value as yaml.YamlMap;
    return pubspecYaml['name'] as String;
  }

  String get templateFilePath => '$finalOutputDir/$templateArbFile';

  static L10nConfig getL10nConfig([File? file]) {
    if ((file ?? File('l10n.yaml')).existsSync()) {
      final l10nFile = File('l10n.yaml');
      final l10nFileString = l10nFile.readAsStringSync();

      final yamlGenConfig = yaml
          .loadYamlDocument(l10nFileString, recover: true)
          .contents
          .value as yaml.YamlMap;
      final arbDir = yamlGenConfig['arb-dir'] as String? ?? 'lib/l10n';
      final templateArbFile = yamlGenConfig['template-arb-file']! as String;

      final outputLocalizationFile =
          yamlGenConfig['output-localization-file'] as String? ??
              'app_localizations.dart';

      final outputDir = yamlGenConfig['output-dir'] as String?;

      final outputClass =
          yamlGenConfig['output-class'] as String? ?? 'AppLocalizations';

      final syntheticPackage =
          yamlGenConfig['synthetic-package'] as bool? ?? true;

      return L10nConfig(
        arbDir: arbDir,
        templateArbFile: templateArbFile,
        outputClass: outputClass,
        outputDir: outputDir,
        syntheticPackage: syntheticPackage,
        outputLocalizationFile: outputLocalizationFile,
      );
    } else {
      throw Exception('No l10n.yaml file');
    }
  }

  static const _defaultL10n = '''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
''';

  static L10nConfig findOrCreateL10nFile(File l10nFile) {
    if (!l10nFile.existsSync() || l10nFile.readAsStringSync().isEmpty) {
      l10nFile
        ..createSync(recursive: true)
        ..writeAsStringSync(_defaultL10n);
    }

    return L10nConfig.getL10nConfig(l10nFile);
  }
}
