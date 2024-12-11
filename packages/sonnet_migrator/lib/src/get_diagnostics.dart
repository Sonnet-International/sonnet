// ignore_for_file: avoid_print, depend_on_referenced_packages
// ignore_for_file: implementation_imports, unnecessary_library_directive

library sonnet_linter;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:meta/meta.dart';
import 'package:sonnet_linter/src/models/diagnostic.dart';
import 'package:sonnet_linter/src/utilities/string_literal_visitor.dart';


@internal
Future<(AnalysisContextCollection, Map<String, List<Diagnostic>>)>
    getDiagnostics(
  FileSystemEntity entity, [
  AnalysisContextCollection? collection,
]) async {
  final completer = Completer<void>();

  unawaited(() async {
    while (!completer.isCompleted) {
      await Future<void>.delayed(const Duration(milliseconds: 200));

      if (completer.isCompleted) break;

      stdout.write('.');
    }

    stdout.write('\n');
  }());

  final foundStringLiterals = <String, List<Diagnostic>>{};
  collection ??= AnalysisContextCollection(
    includedPaths: [entity.absolute.path],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  // Often one context is returned, but depending on the project structure we
  // can see multiple contexts.
  for (final context in collection.contexts) {
    print('Analyzing ${context.contextRoot.root.path} ...');

    for (final filePath in context.contextRoot.analyzedFiles()) {
      if (!filePath.endsWith('.dart')) continue;

      // single file is for re-analysis
      if (entity is File) {
        if (filePath != entity.path) continue;

        (context as DriverBasedAnalysisContext).driver.changeFile(filePath);
        await context.driver.applyPendingFileChanges();
      }

      final getResolvedUnit =
          await context.currentSession.getResolvedUnit(filePath);

      if (getResolvedUnit is ResolvedUnitResult) {
        final origNode = getResolvedUnit.unit;

        origNode.visitChildren(
          StringLiteralVisitor<dynamic>(
            origNode: origNode,
            onFound: (foundStringLiteral) {
              foundStringLiterals[filePath] ??= [];
              foundStringLiterals[filePath]!.add(foundStringLiteral);
            },
          ),
        );
      }
    }
  }

  completer.complete();
  return (collection, foundStringLiterals);
}
