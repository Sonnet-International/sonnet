// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:sonnet_linter/src/forks/change_reporter.dart';
import 'package:sonnet_linter/src/models/arb_change.dart';
import 'package:sonnet_linter/src/models/diagnostic.dart';

class SourceReplacer {
  static Future<Map<String, dynamic>> addChangeToBuilder({
    required ChangeBuilderImpl? changeBuilder,
    required Diagnostic diagnostic,
    required ArbChange arbChange,
    required void Function() onError,
    required void Function() onModify,
  }) async {
    Future<void> addFileEdit(
      void Function(DartFileEditBuilder) adder, [
      int iterations = 0,
    ]) async {
      try {
        await changeBuilder!.addDartFileEdit((builder) {
          try {
            adder(builder);
            onModify();
          } on ConflictingEditException catch (_) {
            onError();
          } on InconsistentAnalysisException catch (_) {
            onError();
          }
        });
      } on InconsistentAnalysisException catch (_) {
        onError();
      }
    }

    final constAncestor = diagnostic.constAncestor;
    if (constAncestor != null) {
      await addFileEdit((builder) {
        builder.addDeletion(
          SourceRange(
            constAncestor.offset,
            Keyword.CONST.lexeme.length + 1,
          ),
        );
      });
    }

    await addFileEdit((builder) {
      builder.addSimpleReplacement(
        SourceRange(
          diagnostic.string.stringLiteral.offset,
          diagnostic.string.stringLiteral.length,
        ),
        diagnostic.contextReplacement(arbChange),
      );
    });

    return diagnostic.toMap(arbChange);
  }

  static const packageImport = 'package:sonnet/sonnet.dart';

  static Future<void> addImport({
    required ChangeBuilder changeBuilder,
    required List<ImportDirective> imports,
    required void Function() onError,
  }) async {
    try {
      return changeBuilder.addDartFileEdit((builder) {
        // insert before first import that is alphabetically later than the
        // import 'package:sonnet/sonnet.dart';
        final sortedImports = imports.sortedBy(
          (i) => i.uri.stringValue ?? '',
        );

        final offset = sortedImports
            .where((i) => i.uri.stringValue!.compareTo(packageImport) > 0)
            .firstOrNull
            ?.offset;

        if (offset == null && sortedImports.isNotEmpty) {
          // if no import is alphabetically later, insert at the end
          final lastImport = sortedImports.last;
          builder.addSimpleInsertion(
            lastImport.end,
            "\nimport '$packageImport';",
          );
        } else {
          builder.addSimpleInsertion(
            offset ?? 0,
            "import '$packageImport';\n",
          );
        }
      });
    } on ConflictingEditException catch (_) {
      onError();
    }
  }
}
