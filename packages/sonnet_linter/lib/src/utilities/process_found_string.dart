import 'dart:io';

// ignore: implementation_imports
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';
import 'package:sonnet_linter/src/forks/ignore_info.dart';
import 'package:sonnet_linter/src/models/diagnostic.dart';
import 'package:sonnet_linter/src/models/lint_specifications.dart';
import 'package:string_literal_finder/string_literal_finder.dart';

final _stringLiteralSpecification = StringLiteralInsideWidgetSpecification();

@internal
Diagnostic? processFoundString(
  StringLiteral node,
  CompilationUnit origNode,
) {
  final match =
      node.thisOrAncestorMatching(_stringLiteralSpecification.isSatisfiedBy);

  if (match == null) return null;

  final filePath = origNode.declaredElement?.source.fullName ?? '';
  final ignoreInfo =
      IgnoreInfo.forDart(origNode, File(filePath).readAsStringSync());
  final lineInfo = origNode.lineInfo;
  final begin = node.beginToken.charOffset;
  final end = node.endToken.charEnd;
  final loc = lineInfo.getLocation(begin);
  final locEnd = lineInfo.getLocation(end);
  // determine if in const. if true, guaranteed to have a const keyword
  final constAncestor = node.thisOrAncestorMatching((node) {
    return (node is InstanceCreationExpression &&
            node.keyword?.type == Keyword.CONST) ||
        (node is DeclaredIdentifier && node.keyword?.type == Keyword.CONST) ||
        (node is VariableDeclarationList &&
            node.keyword?.type == Keyword.CONST) ||
        (node is SuperFormalParameter && node.keyword?.type == Keyword.CONST) ||
        (node is SimpleFormalParameter &&
            node.keyword?.type == Keyword.CONST) ||
        (node is TypedLiteral && node.constKeyword != null) ||
        (node is RecordLiteral && node.constKeyword != null) ||
        (node is ListLiteral && node.constKeyword != null) ||
        (node is FieldFormalParameter && node.keyword?.type == Keyword.CONST);
  });

  final isIgnoredInComments = ignoreInfo.ignoredAt(
    const LintCode(
      name: 'avoid_string_literals_inside_widget',
      problemMessage: 'Avoid using string literals inside widgets',
    ),
    loc.lineNumber,
  );

  if (isIgnoredInComments) return null;

  return Diagnostic(
    string: FoundStringLiteral(
      filePath: filePath,
      loc: loc,
      locEnd: locEnd,
      stringValue: node.stringValue,
      stringLiteral: node,
    ),
    imports: origNode.directives.whereType<ImportDirective>().toList(),
    lineInfo: lineInfo,
    hasSonnetImport: origNode.hasSonnetImport,
    constAncestor: constAncestor,
  );
}

extension on CompilationUnit {
  bool get hasSonnetImport {
    return directives.whereType<ImportDirective>().any((e) {
      return e.uri.stringValue == 'package:sonnet/sonnet.dart';
    });
  }
}
