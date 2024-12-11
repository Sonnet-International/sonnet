import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:sonnet_linter/src/fixes/add_sonnet_import.dart';
import 'package:sonnet_linter/src/lints/import_sonnet_lint.dart';
import 'package:test/test.dart';

import '../../test_helpers/test_helpers.dart';

void main() {
  test('adds import when needed', () async {
    const lint = ImportSonnetLint();
    final fix = AddSonnetImport();
    final testProject = TestProject();
    addTearDown(testProject.dispose);

    await testProject.writeDartFile(widgetBuilder('context.sonnet.foo'));

    final lints = await lint.testFile(testProject.file);
    expect(lints, hasLength(1));

    final changes = await fix.testFile(testProject.file, lints.first);
    expect(changes, hasLength(1));

    final edit = changes.first.change.edits.first;
    expect(
      edit,
      SourceEdit(39, 0, "\nimport 'package:sonnet/sonnet.dart';"),
    );
  });

  test('adds no import when it already is there', () async {
    const lint = ImportSonnetLint();
    final testProject = TestProject.sonnet();
    addTearDown(testProject.dispose);

    await testProject.writeDartFile(
      widgetBuilder(
        'context.sonnet.foo',
        imports: ['import "package:sonnet/sonnet.dart";'],
      ),
    );

    final lints = await lint.testFile(testProject.file);
    expect(lints, isEmpty);
  });
}
