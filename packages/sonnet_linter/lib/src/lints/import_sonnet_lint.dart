import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:sonnet_linter/src/fixes/add_sonnet_import.dart';
import 'package:sonnet_linter/src/lints/testable_dart_rule.dart';

class ImportSonnetLint extends DartLintRule with TestableDartRule {
  const ImportSonnetLint() : super(code: _code);

  static const _code = LintCode(
    name: _name,
    problemMessage: 'Import sonnet package',
    errorSeverity: ErrorSeverity.ERROR,
    uniqueName: _name,
  );

  static const _name = 'import_sonnet';

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      if (node.staticType is InvalidType &&
          node.endToken.lexeme == 'sonnet' &&
          node.prefix.staticType?.element?.name == 'BuildContext') {
        reporter.reportErrorForNode(code, node);
      }
    });
  }

  @override
  List<Fix> getFixes() => [AddSonnetImport()];
}
