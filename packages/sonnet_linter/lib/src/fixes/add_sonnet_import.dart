import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:sonnet_linter/src/fixes/testable_dart_fix.dart';
import 'package:sonnet_linter/src/forks/ast_extensions.dart';
import 'package:sonnet_linter/src/utilities/source_replacer.dart';

class AddSonnetImport extends DartFix with TestableDartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      // Verify that the variable declaration is where our warning is located
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add sonnet import',
        priority: 0,
      );

      // add sonnet import
      SourceReplacer.addImport(
        changeBuilder: changeBuilder,
        imports: node.compilationUnit?.importDirectives() ?? [],
        onError: () {},
      );
    });
  }
}
