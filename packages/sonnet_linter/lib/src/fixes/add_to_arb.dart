// ignore_for_file: cascade_invocations, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:sonnet_generator/sonnet_generator.dart';
import 'package:sonnet_linter/src/fixes/testable_dart_fix.dart';
import 'package:sonnet_linter/src/utilities/arb_file_reader.dart';
import 'package:sonnet_linter/src/utilities/change_getter.dart';
import 'package:sonnet_linter/src/utilities/process_found_string.dart';
import 'package:yaml/yaml.dart';

class AddToArb extends DartFix with TestableDartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addStringLiteral((node) /* cannot be async */ {
      // Verify that the variable declaration is where our warning is located
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      // skip adjacent strings
      if (node.parent is AdjacentStrings) return;

      try {
        _processString(resolver, node, reporter);
      } catch (e) {
        print('error processing string literal: $e');
      }
    });

    context.registry.addStringInterpolation((node) /* cannot be async */ {
      // Verify that the variable declaration is where our warning is located
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      // skip adjacent strings
      if (node.elements.any((element) => element is AdjacentStrings)) return;

      try {
        _processString(resolver, node, reporter);
      } catch (e) {
        print('error processing string interpolation: $e');
      }
    });

    context.registry.addAdjacentStrings((node) /* cannot be async */ {
      // Verify that the variable declaration is where our warning is located
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      try {
        _processString(resolver, node, reporter);
      } catch (e) {
        print('error processing string interpolation: $e');
      }
    });

    context.addPostRunCallback(() async {
      try {
        print('re-generating l10n');

        SonnetGenerator.generate();
      } catch (e) {
        print('error generating l10n: $e');
      }
    });
  }

  static final _indentIdentifierRegExp = RegExp(r'^\s*{\n+(\s*)"');
  static const _defaultIndent = '  ';

  void _processString(
    CustomLintResolver resolver,
    StringLiteral node,
    ChangeReporter reporter,
  ) {
    final file = File(resolver.path);
    final root = _getRootPath(file);

    if (root == null) return;

    final l10nFile = File('${Directory.current.path}/l10n.yaml');
    final l10nConfig = L10nConfig.findOrCreateL10nFile(l10nFile);

    final (arb, arbFile) = ArbFileReader.read(l10nConfig);
    final origNode = node.thisOrAncestorMatching((n) => n is CompilationUnit);

    if (origNode is! CompilationUnit) return;

    final diagnostic = processFoundString(node, origNode);

    if (diagnostic == null) return;

    final arbChange = ChangeGetter.getDefault(diagnostic, arb: arb);

    if (arbChange != null) {
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Localize string',
        priority: 50,
      );

      changeBuilder.addDartFileEdit(
        (builder) {
          builder.addReplacement(
            node.sourceRange,
            (builder) {
              builder.addSimpleLinkedEdit(
                diagnostic.generatedAbbreviation,
                diagnostic.contextReplacement(arbChange),
              );
            },
          );
        },
      );

      // insert entries into arb file
      final fileContents = File(arbFile.path).readAsStringSync();
      final arbYamlContents = (loadYamlDocument(fileContents, recover: true)
              .contents
              .value as YamlMap)
          .nodes;

      // insert entries into arb file
      if (!arbYamlContents.containsKey(arbChange.chosenAbbreviation)) {
        changeBuilder.addGenericFileEdit(
          (builder) {
            // read indent from arb file
            final indent =
                _indentIdentifierRegExp.firstMatch(fileContents)?.group(1) ??
                    _defaultIndent;

            final encoder = JsonEncoder.withIndent(indent);
            final lastBracketPosition = fileContents.lastIndexOf('}');
            final asMap = diagnostic.toMap(arbChange);
            final formatted = encoder
                .convert(asMap)
                // remove first bracket and any leading spaces
                .replaceFirst('{', '')
                .trimLeft();

            builder.addReplacement(
              SourceRange(lastBracketPosition - 1, 2),
              (builder) {
                builder.addSimpleLinkedEdit(
                  diagnostic.generatedAbbreviation,
                  ',\n$indent$formatted',
                );
              },
            );
          },
          customPath: arbFile.path,
        );
      }
    }
  }

  Directory? _getRootPath(File file) {
    Directory? lib;
    Directory? prevDir;
    var i = 0;
    var exit = false;

    while (lib == null && !exit) {
      i++;
      final d = prevDir?.parent ?? file.parent;
      final segments = d.path.split(Platform.pathSeparator);
      if (segments.where((element) => element == 'lib').length == 1 &&
          segments.last == 'lib') {
        lib = d;
        exit = true;
        break;
      }
      if (i > 20 || d == prevDir) {
        exit = true;
        break;
      }

      prevDir = d;
    }

    return lib?.parent;
  }
}
