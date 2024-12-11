import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:sonnet_linter/src/fixes/add_to_arb.dart';
import 'package:sonnet_linter/src/lints/testable_dart_rule.dart';
import 'package:sonnet_linter/src/models/lint_specifications.dart';

class AvoidStringLiteralsInsideWidget extends DartLintRule
    with TestableDartRule {
  const AvoidStringLiteralsInsideWidget() : super(code: _code);

  static const _code = LintCode(
    name: _name,
    problemMessage:
        'String literals should not be declared inside a widget class.',
    errorSeverity: ErrorSeverity.WARNING,
    uniqueName: _name,
  );

  static const _name = 'avoid_string_literals_inside_widget';

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // must be flutter project
    if (!context.pubspec.dependencies.containsKey('flutter')) return;

    final specification = StringLiteralInsideWidgetSpecification();

    context.registry.addStringLiteral((node) {
      // skip adjacent strings
      if (node.parent is AdjacentStrings) return;

      if (specification.isSatisfiedBy(node)) {
        reporter.reportErrorForNode(code, node);
      }
    });

    context.registry.addStringInterpolation((node) {
      // skip adjacent strings
      if (node.elements.any((element) => element is AdjacentStrings)) return;

      if (specification.isSatisfiedBy(node)) {
        reporter.reportErrorForNode(code, node);
      }
    });

    context.registry.addAdjacentStrings((node) /* cannot be async */ {
      if (specification.isSatisfiedBy(node)) {
        reporter.reportErrorForNode(code, node);
      }
    });
  }

  @override
  List<Fix> getFixes() => [AddToArb()];
}
