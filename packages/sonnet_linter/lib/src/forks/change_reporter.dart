import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart'
    as analyzer_plugin;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_yaml.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ChangeBuilderImpl implements ChangeBuilder {
  ChangeBuilderImpl(
    this._message, {
    required this.path,
    required this.priority,
    required this.id,
    required AnalysisSession analysisSession,
  }) : _innerChangeBuilder =
            analyzer_plugin.ChangeBuilder(session: analysisSession);

  final String _message;
  final int priority;
  final String path;
  final String? id;
  final analyzer_plugin.ChangeBuilder _innerChangeBuilder;
  final _operations = <Future<void>>[];

  @override
  Future<void> addDartFileEdit(
    void Function(DartFileEditBuilder builder) buildFileEdit, {
    ImportPrefixGenerator? importPrefixGenerator,
    String? customPath,
  }) async {
    _operations.add(
      importPrefixGenerator == null
          ? _innerChangeBuilder.addDartFileEdit(
              customPath ?? path,
              buildFileEdit,
            )
          : _innerChangeBuilder.addDartFileEdit(
              customPath ?? path,
              buildFileEdit,
              importPrefixGenerator: importPrefixGenerator,
            ),
    );

    await _waitForCompletion();
  }

  SourceChange get sourceChange => _innerChangeBuilder.sourceChange;

  Future<String> applySequence(String originalSource) async {
    return SourceEdit.applySequence(
      originalSource,
      sourceChange.edits.expand((element) => element.edits),
    );
  }

  @override
  void addGenericFileEdit(
    void Function(analyzer_plugin.FileEditBuilder builder) buildFileEdit, {
    String? customPath,
  }) {
    _operations.add(
      _innerChangeBuilder.addGenericFileEdit(customPath ?? path, buildFileEdit),
    );
  }

  @override
  void addYamlFileEdit(
    void Function(YamlFileEditBuilder builder) buildFileEdit,
    String? customPath,
  ) {
    _operations.add(
      _innerChangeBuilder.addYamlFileEdit(customPath ?? path, buildFileEdit),
    );
  }

  Future<PrioritizedSourceChange> _waitForCompletion() async {
    await Future.forEach(_operations, (element) => element);

    return PrioritizedSourceChange(
      priority,
      _innerChangeBuilder.sourceChange
        ..id = id
        ..message = _message,
    );
  }
}
