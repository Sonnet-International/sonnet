// ignore_for_file: avoid_print, depend_on_referenced_packages
// ignore_for_file: implementation_imports, unnecessary_library_directive

library sonnet_migrator;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:sonnet_generator/sonnet_generator.dart';
import 'package:sonnet_linter/src/forks/change_reporter.dart';
import 'package:sonnet_linter/src/models/arb_change.dart';
import 'package:sonnet_linter/src/models/diagnostic.dart';
import 'package:sonnet_linter/src/utilities/arb_file_reader.dart';
import 'package:sonnet_linter/src/utilities/change_getter.dart';
import 'package:sonnet_linter/src/utilities/source_replacer.dart';
import 'package:sonnet_migrator/src/get_diagnostics.dart';

typedef ReAnalyzeFile = Future<Iterable<Diagnostic>?> Function(String path);

// CLI interface for the sonnet migrator
Future<void> main(List<String> arguments) async {
  final argParser = ArgParser()
    ..addFlag(
      'auto',
      abbr: 'a',
      help: 'Automatically accept all changes',
      aliases: ['auto-accept', 'autoaccept'],
    )
    ..addOption(
      'max-iterations',
      abbr: 'm',
      help: 'Max iterations to run',
      defaultsTo: '5',
      aliases: ['max', 'iterations', 'i'],
    )
    ..addOption(
      'directory',
      abbr: 'd',
      help: 'Directory to analyze',
      defaultsTo: Directory.current.path,
      aliases: ['dir'],
    )
    ..addOption(
      'help',
      abbr: 'h',
      help: 'Print this help message',
    );

  final args = argParser.parse(arguments);
  final autoAccept = args['auto'] == true;
  final maxIterations = int.tryParse(args['max-iterations'].toString());
  final directory = Directory(
    args['directory']?.toString() ?? Directory.current.path,
  );

  final l10nFile = File('${Directory.current.path}/l10n.yaml');
  final l10nConfig = L10nConfig.findOrCreateL10nFile(l10nFile);

  // validate arguments
  if (maxIterations == null) {
    print('Invalid max iterations. Expecting an integer');
    exit(1);
  } else if (maxIterations < 1) {
    print('Max iterations exceeded');
    exit(1);
  } else if (!directory.existsSync()) {
    print('Invalid directory');
    exit(1);
  }

  // initialize migrator
  final (arbContentsAsJson, arbFile) = ArbFileReader.read(l10nConfig);
  final migrator = SonnetMigrator(
    initialArb: arbContentsAsJson,
    commitToFile: (ChangeBuilderImpl changeBuilder) async {
      final filePath = changeBuilder.path;
      final fileContent = File(filePath).readAsStringSync();

      File(filePath)
          .writeAsStringSync(await changeBuilder.applySequence(fileContent));
    },
    writeAllToArbToFile: (arb) {
      arbFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(arb),
      );
    },
    promptInput: (inputPrompt, diagnostic) async {
      if (autoAccept) return InputReceivedAccept();

      final description = switch (inputPrompt) {
        StringLiteralInputPrompt() => '''
Found string:
"${inputPrompt.originalString}"
${inputPrompt.generatedAbbreviation}
(a) Accept (s) Skip (r) Rename variable (q) Quit''',
        StringInterpolationVariablePrompt() => '''
Found parameter:
"${inputPrompt.originalString}"
${inputPrompt.generatedParamName}
(a) Accept (s) Skip (r) Rename parameter (q) Quit''',
        RenameVariableInputPrompt() =>
          'Enter a new variable name (${inputPrompt.currentName}):',
        RenameParamInputPrompt() =>
          'Enter a new parameter name (${inputPrompt.currentName}):',
      };

      print(description);
      final response = stdin.readLineSync(encoding: utf8)?.trim() ?? '';

      return switch (response) {
        'a' || 'y' => InputReceivedAccept(),
        's' => InputReceivedSkip(),
        'q' => InputReceivedQuit(),
        'r' => InputReceivedRequestRename(),
        _ => InputReceivedInvalid(),
      };
    },
  );

  final (collection, diagnostics) = await getDiagnostics(directory);
  final filesNeedingReAnalysis = <String>[];

  for (final fileDiagnostics in diagnostics.values) {
    if (fileDiagnostics.isEmpty) continue;

    final needsReAnalysis = await migrator.fileRunner(
      diagnostics: fileDiagnostics,
      reAnalyzeFile: (String path) async {
        final diagnostics = await getDiagnostics(File(path), collection);
        return diagnostics.$2.values.firstOrNull;
      },
      filePath: fileDiagnostics.first.string.filePath,
      currentSession: collection.contexts.first.currentSession,
      rootPath: directory.path,
    );

    if (needsReAnalysis) {
      filesNeedingReAnalysis.add(fileDiagnostics.first.string.filePath);
    }
  }

  if (filesNeedingReAnalysis.isNotEmpty) {
    final iterationsRemaining = maxIterations - 1;
    print('\n\n-------------------------------------------------------------');
    print(
      '''Re-analyzing files that had editing conflicts from last run (max iterations remaining $iterationsRemaining)''',
    );

    return main(
      {
        ...args.arguments,
        '--max-iterations',
        '$iterationsRemaining',
      }.toList(),
    );
  }

  SonnetGenerator.generate();
}

class SonnetMigrator {
  SonnetMigrator({
    required Map<String, dynamic> initialArb,
    required this.writeAllToArbToFile,
    required this.commitToFile,
    required this.promptInput,
  }) : arb = <String, dynamic>{...initialArb};

  final Map<String, dynamic> arb;
  final void Function(Map<String, dynamic>) writeAllToArbToFile;
  final Future<void> Function(ChangeBuilderImpl) commitToFile;
  final PromptInput promptInput;

  Future<bool> fileRunner({
    required Iterable<Diagnostic> diagnostics,
    required ReAnalyzeFile reAnalyzeFile,
    required AnalysisSession currentSession,
    required String filePath,
    required String rootPath,
    List<ArbChange> previouslySkippedAnswers = const [],
    int iteration = 0,
    bool isReAnalysis = false,
  }) async {
    if (diagnostics.isEmpty) return false;
    var changes = 0;

    final skippedAnswers = <ArbChange>[];
    var fileNeedsReAnalysis = false;
    final fileChangeBuilder = ChangeBuilderImpl(
      'SonnetChangeBuilder',
      path: filePath,
      priority: 0,
      id: Random().nextInt(5000).toString(),
      analysisSession: currentSession,
    );

    if (!isReAnalysis) {
      print('Analyzing ${filePath.replaceFirst(rootPath, '')}...');
    }

    for (final diagnostic in diagnostics) {
      final arbChange = await () async {
        if (previouslySkippedAnswers.isNotEmpty) {
          final arbChange = previouslySkippedAnswers.firstWhereOrNull((a) {
            return a.string == diagnostic.originalString;
          });

          if (arbChange != null) return arbChange;
        }

        return ChangeGetter.get(
          diagnostic,
          arb: arb,
          promptInput: promptInput,
          onExit: () async {
            SonnetGenerator.generate();
            exit(0);
          },
        );
      }();

      if (arbChange == null) continue;

      await SourceReplacer.addChangeToBuilder(
        changeBuilder: fileChangeBuilder,
        diagnostic: diagnostic,
        arbChange: arbChange,
        onModify: () => changes++,
        onError: () {
          skippedAnswers.add(arbChange);

          fileNeedsReAnalysis = true;
        },
      );

      arb.addAll(diagnostic.toMap(arbChange));
    }

    // add import if needed
    if (changes > 0 && diagnostics.any((d) => !d.hasSonnetImport)) {
      await SourceReplacer.addImport(
        changeBuilder: fileChangeBuilder,
        imports: diagnostics.first.imports,
        onError: () => fileNeedsReAnalysis = true,
      );
    }

    writeAllToArbToFile(arb);
    await commitToFile(fileChangeBuilder);

    return fileNeedsReAnalysis && changes > 0;
  }
}
