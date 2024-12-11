import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';

mixin TestableDartFix on DartFix {
  @visibleForTesting
  Future<List<PrioritizedSourceChange>> testFile(
    File file,
    AnalysisError error,
  ) {
    // ignore: invalid_use_of_visible_for_testing_member
    return testAnalyzeAndRun(file, error, []);
  }
}
