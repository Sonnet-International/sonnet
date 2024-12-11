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

  static Future<L10nConfig> getL10nConfig() async {
    if (File('l10n.yaml').existsSync()) {
      final l10nFile = File('l10n.yaml');
      final l10nFileString = await l10nFile.readAsString();

      final yamlGenConfig = yaml.loadYamlDocument(l10nFileString, recover: true)
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
}
