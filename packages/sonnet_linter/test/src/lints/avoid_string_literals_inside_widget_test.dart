// ignore_for_file: depend_on_referenced_packages
// ignore_for_file: invalid_use_of_internal_member

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:collection/collection.dart';
import 'package:sonnet_linter/src/fixes/add_to_arb.dart';
import 'package:sonnet_linter/src/lints/avoid_string_literals_inside_widget.dart';
import 'package:test/test.dart';

import '../../test_helpers/test_helpers.dart';

void main() {
  const lint = AvoidStringLiteralsInsideWidget();
  final addToArbFix = AddToArb();
  final testProject = TestProject.sonnet();

  tearDownAll(testProject.dispose);

  Future<ResolvedUnitResult> getResolvedUnit({required File file}) async {
    return (await testProject.session(file.path).getResolvedUnit(file.path))
        as ResolvedUnitResult;
  }

  Future<List<PrioritizedSourceChange>> getFixes(
    ResolvedUnitResult resolvedUnit,
    AnalysisError error,
  ) async {
    return addToArbFix.testRun(
      resolvedUnit,
      error,
      [],
      pubspec: testProject.pubspec,
    );
  }

  List<String> lintDescriptions(List<AnalysisError> lints) {
    final fileContents = testProject.file.readAsStringSync();
    return lints.map((lint) {
      return 'Lint: ${lint.errorCode}\n'
          '  ${fileContents.substring(lint.offset, lint.offset + lint.length)}';
    }).toList();
  }

  void expectNoLints(List<AnalysisError> lints) {
    if (lints.isNotEmpty) {
      fail(
        'Expected no lints, but found:\n${lintDescriptions(lints).join('\n')}',
      );
    }
  }

  group('ignored', () {
    test('ignores Sonnet.changeLocale param', () async {
      await testProject.writeDartFile(
        widgetFunctionBuilder(
          "Sonnet.changeLocale('pt')",
          imports: ['import "package:sonnet/sonnet.dart";'],
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores Exception messages', () async {
      await testProject.writeDartFile(
        widgetFunctionBuilder(
          "Exception('some exception message')",
          imports: ['import "package:sonnet/sonnet.dart";'],
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores Keys', () async {
      await testProject.writeDartFile(
        widgetListBuilder(
          [
            "Text('', key: ValueKey('key'))",
            "Text('', key: Key('key'))",
            "Text('', key: GlobalKey('key'))",
          ],
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores empty strings', () async {
      await testProject.writeDartFile(widgetTextBuilder(''));

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores blank strings', () async {
      await testProject.writeDartFile(widgetTextBuilder('   '));

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores strings with no alpha-numeric characters', () async {
      await testProject.writeDartFile(
        widgetListBuilder(
          [
            "Text('*')",
            r"Text(' *_!@@#\$%^&*)')",
            "Text('(^^) _-_ (^^)')",
          ],
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores urls', () async {
      await testProject.writeDartFile(
        widgetListBuilder(
          [
            "Text('http://www.example.com')",
            "Text('assets/images/foo.png')",
            "Text('/some-path/with/no/spaces')",
          ],
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores numbers', () async {
      await testProject.writeDartFile(
        widgetListBuilder(
          [
            "Text('1')",
            "Text('999999')",
          ],
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores asset strings', () async {
      await testProject.writeDartFile(
        widgetListBuilder(
          [
            "Text('no-spaces-ending-in.png')",
          ],
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores asset strings with interpolation', () async {
      await testProject.writeDartFile(
        widgetListBuilder(
          [
            r"Text('no-spaces-ending-in${1}.png')",
            r"Text('no-spaces-ending-in$foo.png')",
            r"Text('assets/images/${1}.png')",
            r"Text('/some-path/with/no/spaces/$foo')",
            r"Text('http://www.example.com/${foo}')",
          ],
          innerBuildSetup: 'int foo = 1;',
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores numbers with interpolation', () async {
      await testProject.writeDartFile(
        widgetListBuilder(
          [
            r"Text('123 ${1}')",
            r"Text('${1 + 1}')",
          ],
          innerBuildSetup: 'int foo = 1;',
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores strings outside of a class', () async {
      await testProject.writeDartFile(
        widgetBuilder(
          'Container()',
          outOfClassSetup: """
final String fooFinal = 'foo';
late final String fooLateFinal = 'foo';
const String fooConst = 'foo';
String get fooGetter => 'foo';
String fooMethod() => 'foo';
""",
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores strings in non-widget class', () async {
      await testProject.writeDartFile(
        widgetBuilder(
          'Container()',
          outOfClassSetup: """
class Foo {
  Foo([this.finalParam = 'foo']) : finalNullFoo = 'foo';
  
  final String finalNullFoo;
  final String finalParam;
  
  final String fooFinal = 'foo';
  late final String fooLateFinal = 'foo';
  String get fooGetter => 'foo';
  String fooMethod() => 'foo';
  
  static const String staticFooConst = 'foo';
  static String get staticFooGetter => 'foo';
  static String staticFooMethod() => 'foo';
}
""",
        ),
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores static strings in widget class', () async {
      await testProject.writeDartFile(
        """
class Foo extends StatelessWidget {
  Foo(super.key);
  
  static const String staticFooConst = 'foo';
  static const freeText = 'FREE';
  static String get staticFooGetter => 'foo';
  static String staticFooMethod() => 'foo';
  
  @override
  Widget build(BuildContext context) {
    return const Text(freeText);
  }
}
""",
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });

    test('ignores static string consts in widget class', () async {
      await testProject.writeDartFile(
        """
class Video extends StatelessWidget {
  const Video({
    super.key,
    required this.videoName,
    required this.price,
  });

  const Video.free({super.key, required this.videoName})
      : price = freeText;

  final String videoName;
  final String price;

  static const freeText = 'FREE';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {},
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                child: ListTile(
                  title: Text(videoName.toUpperCase()),
                  trailing: const Text(freeText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",
      );

      final lints = await lint.testRun(
        await getResolvedUnit(file: testProject.file),
        pubspec: testProject.pubspec,
      );
      expectNoLints(lints);
    });
  });

  group('match & fix', () {
    group('simple strings', () {
      test('matches plain text', () async {
        await testProject.writeDartFile(widgetTextBuilder('foo'));

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(dartEdit.singleReplacement, 'context.sonnet.foo');
        expect(arbEdit.singleReplacementArbMap, {'foo': 'foo'});
      });

      test('matches sentences', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            'There was an old lady who lived in a shoe',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.thereWasAnOldLadyWhoLivedInAShoe',
        );
        expect(arbEdit.singleReplacementArbMap, {
          'thereWasAnOldLadyWhoLivedInAShoe':
              'There was an old lady who lived in a shoe',
        });
      });

      test('adjacent strings', () async {
        await testProject.writeDartFile(
          widgetBuilder(
            '''
Text(
  "There was an old lady who lived in a shoe, "
    "She had so many children, she didn't know what to do."
)
''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.thereWasAnOldLadyWhoLivedInAShoeSheHad',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'thereWasAnOldLadyWhoLivedInAShoeSheHad':
                """There was an old lady who lived in a shoe, She had so many children, she didn't know what to do.""",
          },
        );
      });

      test('adjacent string using addition', () async {
        await testProject.writeDartFile(
          widgetBuilder(
            '''
Text(
  "There was an old lady who lived in a shoe, " +
    "She had so many children, she didn't know what to do."
)
''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.thereWasAnOldLadyWhoLivedInAShoeSheHad',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'thereWasAnOldLadyWhoLivedInAShoeSheHad':
                """There was an old lady who lived in a shoe, She had so many children, she didn't know what to do.""",
          },
        );
      });
    });

    group('interpolation', () {
      test('single int', () async {
        await testProject.writeDartFile(widgetTextBuilder(r'foo${1}'));

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(dartEdit.singleReplacement, 'context.sonnet.foo1(1)');
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'foo1': 'foo{one}',
            '@foo1': {
              'placeholders': {
                'one': {
                  'type': 'int',
                },
              },
            },
          },
        );
      });

      test('nullable String', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(r'foo${foo}', innerBuildSetup: 'String? foo;'),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(dartEdit.singleReplacement, 'context.sonnet.fooFoo(foo!)');
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('nullable String as property', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo().foo?.foo?.value}',
            outOfClassSetup: '''
class Foo {  
  final String? value; 
  late final Foo? foo = Foo(); 
}''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooValue((Foo().foo?.foo?.value)!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooValue': 'foo{value}',
            '@fooValue': {
              'placeholders': {
                'value': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('nullable String as function', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo().foo()}',
            outOfClassSetup: 'class Foo {  String? foo() => null; }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooFoo((Foo().foo())!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('nullable int', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(r'foo${foo}', innerBuildSetup: 'int? foo;'),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(dartEdit.singleReplacement, 'context.sonnet.fooFoo(foo!)');
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'int',
                },
              },
            },
          },
        );
      });

      test('nullable int asserted', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(r'foo${foo!}', innerBuildSetup: 'int? foo;'),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(dartEdit.singleReplacement, 'context.sonnet.fooFoo(foo!)');
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'int',
                },
              },
            },
          },
        );
      });

      test('toString() does not go to arb', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${foo.toString()}',
            innerBuildSetup: 'int? foo;',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooFoo(foo.toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('nullable int as property', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo().foo?.foo?.value}',
            outOfClassSetup: '''
class Foo {  
  final int? value; 
  late final Foo? foo = Foo(); 
}''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooValue((Foo().foo?.foo?.value)!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooValue': 'foo{value}',
            '@fooValue': {
              'placeholders': {
                'value': {
                  'type': 'int',
                },
              },
            },
          },
        );
      });

      test('nullable int as function', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo().foo()}',
            outOfClassSetup: 'class Foo {  int? foo() => null; }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooFoo((Foo().foo())!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'int',
                },
              },
            },
          },
        );
      });

      test('value in dart is different type than value in arb', () async {
        const initialL10n = {
          'foo': 'foo{foo}',
          '@foo': {
            'placeholders': {
              'foo': {
                'type': 'int',
              },
            },
          },
        };

        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${foo}',
            innerBuildSetup: 'String? foo;',
          ),
          l10n: initialL10n,
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.foo(int.parse(foo!))',
        );
        expect(arbEdit, null);
      });

      test('unknown type', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(r'foo${foo}', innerBuildSetup: 'dynamic foo;'),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooFoo(foo.toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('binary expression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${foo ?? bar ?? baz}',
            innerBuildSetup: 'String? foo;\nString? bar;\nString? baz;',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBaz((foo ?? bar ?? baz)!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBaz': 'foo{baz}',
            '@fooBaz': {
              'placeholders': {
                'baz': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('binary operator', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo().bar ? baz : buzz}',
            outOfClassSetup: 'class Foo { bool get bar => false; }',
            innerBuildSetup: 'String? foo;\nString? baz;\nString? buzz;',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar((Foo().bar ? baz : buzz)!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('nested binary operator', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo().bar ? (Foo().bar ? baz : buzz) : buzz}',
            outOfClassSetup: 'class Foo { bool get bar => true; }',
            innerBuildSetup: 'String? foo;\nString? baz;\nString? buzz;',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          '''context.sonnet.fooBar((Foo().bar ? (Foo().bar ? baz : buzz) : buzz)!)''',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('as Expression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${bar as String}',
            innerBuildSetup: 'String? bar;',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar(bar as String)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('Cascade Expression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${bar..baz()}',
            innerBuildSetup: 'String bar;',
            outOfClassSetup: 'extension on String { void baz() {} }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar(bar..baz())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('Index Expression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${bar[0]}',
            innerBuildSetup: 'String bar;',
            outOfClassSetup: 'extension on String { void baz() {} }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar(bar[0])',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('Is Expression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${bar is String}',
            innerBuildSetup: 'String bar;',
            outOfClassSetup: 'extension on String { void baz() {} }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar((bar is String).toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('Prefix Expression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${!bar}',
            innerBuildSetup: 'bool bar;',
            outOfClassSetup: 'extension on String { void baz() {} }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar((!bar).toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('Throw Expression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${throw Exception()}',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooException((throw Exception()).toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooException': 'foo{exception}',
            '@fooException': {
              'placeholders': {
                'exception': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('This Expression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${this.bar}',
            classSetup: 'final String bar = "";',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar(this.bar)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('ThisExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${this}',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooLinted(this.toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooLinted': 'foo{linted}',
            '@fooLinted': {
              'placeholders': {
                'linted': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('InstanceCreationExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo()}',
            outOfClassSetup: 'class Foo { Foo(); }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooFoo(Foo().toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('ConstructorReference', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo}',
            outOfClassSetup: 'class Foo { Foo(); }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooFoo(Foo.toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooFoo': 'foo{foo}',
            '@fooFoo': {
              'placeholders': {
                'foo': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('InvocationExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${Foo().bar()}',
            outOfClassSetup: 'class Foo { String bar() => ' '; }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar(Foo().bar())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('NullShortableExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${bar ?? baz}',
            innerBuildSetup: 'String? bar;\nString? baz;',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBaz((bar ?? baz)!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBaz': 'foo{baz}',
            '@fooBaz': {
              'placeholders': {
                'baz': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('ParenthesizedExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${(bar)}',
            innerBuildSetup: 'String bar;',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar((bar))',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('SwitchExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            // ignore: leading_newlines_in_multiline_strings
            r'''""foo${switch(bar) {
              Bar.bar => '',
              Bar.baz => '',
            }}""''',
            innerBuildSetup: 'Bar bar;',
            outOfClassSetup: 'enum Bar { bar, baz }',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          // ignore: leading_newlines_in_multiline_strings
          '''context.sonnet.fooBar(switch (bar) {Bar.bar => '', Bar.baz => ''})''',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('RethrowExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${rethrow}',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooRethrow(rethrow.toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooRethrow': 'foo{kRethrow}',
            '@fooRethrow': {
              'placeholders': {
                'kRethrow': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('SuperExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${super.build(context)}',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBuild((super.build(context)).toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBuild': 'foo{build}',
            '@fooBuild': {
              'placeholders': {
                'build': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('Naked SuperExpression', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${super}',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooSuper(super.toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooSuper': 'foo{kSuper}',
            '@fooSuper': {
              'placeholders': {
                'kSuper': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('TypeLiteral', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${String}',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooString(String.toString())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooString': 'foo{string}',
            '@fooString': {
              'placeholders': {
                'string': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('nullable method invocation', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${foo.bar()}',
            outOfClassSetup: '''
            class Foo { String? bar() => null; }
            final foo = Foo();
            ''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar((foo.bar())!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('non-null method invocation', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${foo.bar()}',
            outOfClassSetup: '''
            class Foo { String bar() => null; }
            final foo = Foo();
            ''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar(foo.bar())',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('nullable getter', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${foo.bar}',
            outOfClassSetup: '''
class Foo { 
  String? get bar => null; 
}

final foo = Foo();
            ''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBar((foo.bar)!)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBar': 'foo{bar}',
            '@fooBar': {
              'placeholders': {
                'bar': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('non-null getter', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'foo${bar.baz}',
            outOfClassSetup: '''
class Bar { 
  String get baz => null; 
}

final bar = Bar();
            ''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.fooBaz(bar.baz)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'fooBaz': 'foo{baz}',
            '@fooBaz': {
              'placeholders': {
                'baz': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });

      test('after operator', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(r'${[].length - 1} more'),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          'context.sonnet.nMore([].length - 1)',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'nMore': '{n} more',
            '@nMore': {
              'placeholders': {
                'n': {
                  'type': 'int',
                },
              },
            },
          },
        );
      });

      test('adjacent strings', () async {
        await testProject.writeDartFile(
          widgetBuilder(
            r'''
Text(
  "There was an old lady who lived in ${count} shoe, " +
    "She had ${children} children, she didn't know what to do."
)
''',
            innerBuildSetup: 'int count = 1; int children = 10;',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          '''context.sonnet.thereWasAnOldLadyWhoLivedInAShoeSheHad(count, children)''',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'thereWasAnOldLadyWhoLivedInAShoeSheHad':
            """There was an old lady who lived {count} shoe, She had {children}} children, she didn't know what to do.""",
            '@thereWasAnOldLadyWhoLivedInAShoeSheHad': {
              'placeholders': {
                'count': {
                  'type': 'int',
                },
                'children': {
                  'type': 'int',
                },
              },
            },
          },
        );
      });

      test('enum function, getter, and final variable', () async {
        await testProject.writeDartFile(
          widgetTextBuilder(
            r'''I have purchased ${item.name} for ${item.cost + item.price(tax)}''',
            innerBuildSetup: 'double tax = 0.1; Item item;',
            outOfClassSetup: '''
enum Item { 
  cheese('cheddar');
  
  Item(this.name);
  
  final String name;
  
  double get cost => 1.0;
  
  double price(double tax) => cost + tax;
}
''',
          ),
        );

        final lints = await lint.testRun(
          await getResolvedUnit(file: testProject.file),
          pubspec: testProject.pubspec,
        );
        expect(lints, hasLength(1), reason: lintDescriptions(lints).join('\n'));

        final fixes = await getFixes(
          await getResolvedUnit(file: testProject.file),
          lints.first,
        );
        final (dartEdit, arbEdit) = fixes.edits;

        expect(
          dartEdit.singleReplacement,
          '''context.sonnet.iHavePurchasedItemFor(item.name, (item.cost + item.price(tax)).toString())''',
        );
        expect(
          arbEdit.singleReplacementArbMap,
          {
            'iHavePurchasedItemFor': 'I have purchased {item} for {cost}',
            '@iHavePurchasedItemFor': {
              'placeholders': {
                'item': {
                  'type': 'String',
                },
                'cost': {
                  'type': 'String',
                },
              },
            },
          },
        );
      });
    });
  });
}

extension on SourceFileEdit? {
  Map<String, Object?>? get singleReplacementArbMap {
    if (this == null) return null;

    return json.decode(this!.singleReplacement.replaceFirst(',', '{'))
        as Map<String, Object?>;
  }
}

extension on SourceFileEdit {
  String get singleReplacement {
    return edits.single.replacement;
  }
}

extension on List<PrioritizedSourceChange> {
  (SourceFileEdit, SourceFileEdit?) get edits {
    return (
      last.change.edits.firstWhere((e) => e.file.endsWith('.dart')),
      first.change.edits.firstWhereOrNull((e) => e.file.endsWith('.arb')),
    );
  }
}
