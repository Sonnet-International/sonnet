// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:sonnet_linter/src/forks/change_reporter.dart';
import 'package:sonnet_linter/src/models/diagnostic.dart';
import 'package:sonnet_linter/src/utilities/change_getter.dart';
import 'package:sonnet_migrator/src/get_diagnostics.dart';
import 'package:test/test.dart';

import '../../bin/sonnet_migrator.dart';

const reGenerateFiles = true;

void main() {
  test(
    'runner',
    () async {
      final testDir = Directory('${Directory.current.path}/test/bin/widgets');
      final testFile = File('${testDir.path}/widget.dart');
      final arbFile = File('${testDir.path}/app_en.arb');

      final originalFileContents = testFile.readAsStringSync();

      try {
        final arb = <String, dynamic>{};

        final (collection, diagnostics) = await getDiagnostics(testDir);

        final linter = SonnetMigrator(
          initialArb: arb,
          writeAllToArbToFile: arb.addAll,
          commitToFile: (ChangeBuilderImpl changeBuilder) async {
            testFile.writeAsStringSync(
              await changeBuilder.applySequence(
                testFile.readAsStringSync(),
              ),
            );
          },
          promptInput: expectAsync2(
            (InputPrompt inputPrompt, Diagnostic diagnostic) async {
              return InputReceivedAccept();
            },
            max: 500,
          ),
        );

        var revisions = 0;

        Future<void> lint(Map<String, List<Diagnostic>> diagnostics) async {
          final needsReLint = await linter.fileRunner(
            diagnostics: diagnostics[testFile.path] ?? [],
            reAnalyzeFile: expectAsync1(
              (String path) async => [],
              max: 3,
            ),
            currentSession: collection.contexts.first.currentSession,
            filePath: testFile.path,
            rootPath: testDir.path,
          );

          if (needsReLint) {
            revisions++;
            print('needs re-lint (iteration $revisions)');
            final revision =
                File('${testDir.path}/widget_linted_$revisions.dart');

            if (reGenerateFiles) {
              revision.writeAsStringSync(testFile.readAsStringSync());
            } else {
              expect(
                testFile.readAsStringSync(),
                revision.readAsStringSync(),
              );
            }

            final (_, diagnostics) = await getDiagnostics(testFile, collection);

            return lint(diagnostics);
          }
        }

        await lint(diagnostics);

        final finalFile = File('${testDir.path}/widget_linted_final.dart');

        if (reGenerateFiles) {
          finalFile.writeAsStringSync(testFile.readAsStringSync());
          arbFile.writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(arb),
          );
        } else {
          expect(
            jsonDecode(arbFile.readAsStringSync()).toString(),
            arb.toString(),
          );
        }
      } finally {
        testFile.writeAsStringSync(originalFileContents);
      }
    },
    timeout: const Timeout(Duration(minutes: 100)),
  );
}
