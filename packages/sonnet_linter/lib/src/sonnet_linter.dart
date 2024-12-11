import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:sonnet_linter/src/lints/avoid_string_literals_inside_widget.dart';
import 'package:sonnet_linter/src/lints/import_sonnet_lint.dart';

/// create plugin to analyze dart files and raise warning on string literals
/// declared inside a class that extends Widget or State
PluginBase createPlugin() => _SonnetLinterPlugin();

class _SonnetLinterPlugin extends PluginBase {
  _SonnetLinterPlugin();

  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    final enabled = configs.enableAllLintRules ?? true;
    if (!enabled) return [];

    return [
      const AvoidStringLiteralsInsideWidget(),
      const ImportSonnetLint(),
    ];
  }
}
