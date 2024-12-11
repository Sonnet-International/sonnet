import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';

class Interpolation {
  Interpolation({
    required this.originalCaller,
    required this.originalCallerContents,
    required this.dartType,
    required this.usesBrackets,
    required this.expression,
  });

  final String originalCaller;
  final String originalCallerContents;
  final DartType dartType;
  final bool usesBrackets;
  final InterpolationExpression expression;
}
