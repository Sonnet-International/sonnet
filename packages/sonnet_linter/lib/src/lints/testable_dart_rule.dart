import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

mixin TestableDartRule on DartLintRule {
  @visibleForTesting
  Future<List<AnalysisError>> testFile(File file, [Pubspec? pubspec]) async {
    final result = await resolveFile2(path: file.path);
    result as ResolvedUnitResult;
    // ignore: invalid_use_of_visible_for_testing_member
    return testRun(result, pubspec: pubspec);
  }
}
