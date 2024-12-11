import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:sonnet_linter/src/utilities/process_found_string.dart';

import '../models/diagnostic.dart';

class StringLiteralVisitor<R> extends GeneralizingAstVisitor<R> {
  StringLiteralVisitor({
    required this.origNode,
    required this.onFound,
  });

  final CompilationUnit origNode;
  final void Function(Diagnostic) onFound;

  @override
  R? visitStringLiteral(StringLiteral node) {
    // skip adjacent strings
    if (node.parent is! AdjacentStrings) {
      final diagnostic = processFoundString(node, origNode);

      if (diagnostic != null) onFound(diagnostic);
    }

    return super.visitStringLiteral(node);
  }

  @override
  R? visitStringInterpolation(StringInterpolation node) {
    // skip adjacent strings
    if (node.elements.any((element) => element is AdjacentStrings)) {
      final diagnostic = processFoundString(node, origNode);

      if (diagnostic != null) onFound(diagnostic);
    }


    return super.visitStringInterpolation(node);
  }

  @override
  R? visitAdjacentStrings(AdjacentStrings node) {
    final diagnostic = processFoundString(node, origNode);

    if (diagnostic != null) onFound(diagnostic);

    return super.visitAdjacentStrings(node);
  }
}
