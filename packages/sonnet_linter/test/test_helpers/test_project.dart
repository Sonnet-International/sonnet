import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class TestProject {
  TestProject({
    Pubspec? pubspec,
    String? l10n,
  }) : directory = _newTmpDirectory() {
    this.pubspec = pubspec ?? materialPubspec;
    _resetL10n();

    file = File('${directory.path}/lib/main.dart')..createSync(recursive: true);
    File('${directory.path}/l10n.yaml').writeAsStringSync(l10n ?? _defaultL10n);

    contextCollection =
        AnalysisContextCollection(includedPaths: [directory.path]);
  }

  TestProject.sonnet() : this(pubspec: sonnetPubspec);

  late final Pubspec pubspec;
  late final File file;

  final Directory directory;
  late final AnalysisContextCollection contextCollection;

  static Directory _newTmpDirectory() {
    return Directory(
      '${Directory.current.path}/.temp/${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> writeDartFile(
    String content, {
    Map<String, dynamic> l10n = const {},
  }) async {
    _resetL10n(l10n);
    final file = File('${directory.path}/lib/main.dart')
      ..writeAsStringSync(content);

    final context =
        contextCollection.contextFor(file.path) as DriverBasedAnalysisContext;

    context.driver.changeFile(file.path);
    await context.driver.applyPendingFileChanges();
  }

  AnalysisSession session(String filePath) {
    return contextCollection.contextFor(filePath).currentSession;
  }

  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  void _resetL10n([Map<String, dynamic> json = const {}]) {
    File('${directory.path}/lib/l10n/app_en.arb')
      ..createSync(recursive: true)
      ..writeAsStringSync(_jsonEncoder.convert(json));
  }

  void dispose() {
    directory.delete(recursive: true);
  }
}

final materialPubspec = Pubspec.parse('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
''');

final sonnetPubspec = Pubspec.parse('''
name: test_project
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
  sonnet:
    path: ../../../dart_custom_lints/packages/sonnet
''');

const _defaultL10n = '''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
''';
