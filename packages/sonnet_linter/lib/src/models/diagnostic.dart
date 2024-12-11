// ignore: implementation_imports
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:sonnet_linter/src/forks/casing.dart';
import 'package:string_literal_finder/string_literal_finder.dart';

import 'arb_change.dart';
import 'interpolation.dart';

class Diagnostic {
  Diagnostic({
    required this.string,
    required this.lineInfo,
    required this.imports,
    required this.hasSonnetImport,
    required this.constAncestor,
  });

  final FoundStringLiteral string;
  final LineInfo lineInfo;
  final bool hasSonnetImport;
  final List<ImportDirective> imports;
  final AstNode? constAncestor;

  String get originalString {
    final buffer = StringBuffer();

    for (final childEntity in string.stringLiteral.childEntities) {
      if (childEntity is StringToken) {
        buffer.write(childEntity.value());
      } else if (childEntity is InterpolationString) {
        buffer.write(childEntity.value);
      } else if (childEntity is InterpolationExpression) {
        buffer.write(childEntity.toString());
      }
    }

    return buffer.toString();
  }

  String arbValue(ArbChange arbChange) {
    final buffer = StringBuffer();

    for (final childEntity in string.stringLiteral.childEntities) {
      if (childEntity is StringToken) {
        buffer.write(childEntity.value());
      } else if (childEntity is InterpolationString) {
        buffer.write(childEntity.value);
      } else if (childEntity is InterpolationExpression) {
        final param = arbChange.params.firstWhereOrNull((param) {
          return param.interpolation.originalCaller == childEntity.toString();
        });

        if (param != null) {
          buffer.write('{${param.name}}');
        }
      }
    }

    return buffer
        .toString()
        .replaceAll(RegExp("""^r?['"]+"""), '')
        .replaceAll(RegExp(r"""['"]+$"""), '');
  }

  RegExp get arbMatcher => RegExp('^${_subInterpolationForMatcher(false)}\$');

  RegExp get escapedArbMatcher =>
      RegExp('^${RegExp.escape(_subInterpolationForMatcher(false))}\$');

  RegExp arbMatcherWithNamedPlaceholders(List<String> orderedPlaceholderNames) {
    return RegExp(
      '^${_subInterpolationForMatcher(false, orderedPlaceholderNames)}\$',
    );
  }

  RegExp get originalCallerMatcher =>
      RegExp('^${_subInterpolationForMatcher(true)}\$');

  String _subInterpolationForMatcher(
    bool matchOriginalCaller, [
    List<String> orderedPlaceholderNames = const [],
  ]) {
    final buffer = StringBuffer();
    var usedPlaceholders = 0;

    for (final childEntity in string.stringLiteral.childEntities) {
      if (childEntity is StringToken) {
        buffer.write(RegExp.escape(childEntity.value()));
      } else if (childEntity is InterpolationString) {
        buffer.write(RegExp.escape(childEntity.value));
      } else if (childEntity is InterpolationExpression) {
        final placeholderName =
            orderedPlaceholderNames.elementAtOrNull(usedPlaceholders);

        if (placeholderName != null) {
          buffer.write('{${RegExp.escape(placeholderName)}}');
          usedPlaceholders++;
        } else if (matchOriginalCaller) {
          if (childEntity.rightBracket == null) {
            // ^^^ interpolation using $
            buffer.write(r'(\$.+)');
          } else {
            // interpolation using ${}
            buffer.write(r'(\${.+})');
          }
        } else {
          buffer.write('({[a-zA-Z0-9_]+})');
        }
      }
    }

    var result = buffer.toString();

    final literal = string.stringLiteral;
    if (literal is SingleStringLiteral) {
      if (literal.isRaw) {
        result = result.replaceAll(RegExp('^r'), '');
      }
    }

    return result
        .replaceAll(RegExp("""^['"]+"""), '')
        .replaceAll(RegExp(r"""['"]+$"""), '');
  }

  List<Interpolation> get interpolations {
    final interpolations = <Interpolation>[];

    for (final childEntity in string.stringLiteral.childEntities) {
      if (childEntity is InterpolationExpression) {
        late DartType type;
        final originalCaller = childEntity.toString();
        final buffer = StringBuffer();

        for (final childEntity in childEntity.childEntities) {
          if (childEntity is SimpleIdentifier) {
            type = childEntity.staticType!;
            buffer.write(childEntity.name);
          } else if (childEntity is BeginToken || childEntity is SimpleToken) {
            // noop for `$`, `${` and `}`
          } else if (childEntity is Expression) {
            type = childEntity.staticType!;
            buffer.write(childEntity.toString());
          } else if (childEntity is PropertyAccess) {
            buffer.write(childEntity.propertyName.name);
          }
        }

        interpolations.add(
          Interpolation(
            originalCaller: originalCaller,
            originalCallerContents: buffer.toString(),
            dartType: type,
            usesBrackets: childEntity.rightBracket != null,
            expression: childEntity,
          ),
        );
      }
    }

    return interpolations;
  }

  String get generatedAbbreviation {
    final buffer = StringBuffer();

    for (final childEntity in string.stringLiteral.childEntities) {
      if (childEntity is StringToken) {
        buffer.appendCamel(childEntity.value());
      } else if (childEntity is InterpolationString) {
        buffer.appendCamel(childEntity.value);
      } else if (childEntity is InterpolationExpression) {
        childEntity.expression.generateAbbreviation(buffer.appendCamel);
      }
    }

    var nameGuess = buffer.toString();

    final literal = string.stringLiteral;
    if (literal is SingleStringLiteral) {
      if (literal.isRaw) {
        nameGuess = nameGuess.replaceAll(RegExp('^r'), '');
      }
    }

    nameGuess = nameGuess
        .replaceAll(RegExp("""^['"]+"""), '')
        .replaceAll(RegExp(r"""['"]+$"""), '');

    final camelized = nameGuess.camelize;

    if (camelized.length > 50) {
      final shortenedLineSplit = originalString.substring(0, 55).split(' ');
      return shortenedLineSplit
          .sublist(0, shortenedLineSplit.length - 1)
          .join(' ')
          .camelize
          .replaceAll(
            RegExp(
              r'''(And|But|Or|With|As|Are|Was|May|Can|Will|They|Who|While|After|Because|For|At|SuchAs|Of|To|Be)$''',
            ),
            '',
          );
    } else {
      return keywordMapping[camelized] ?? camelized;
    }
  }

  @internal
  static final keywordMapping = Keyword.values.fold<Map<String, String>>(
    {},
    (acc, keyword) {
      acc[keyword.lexeme] =
          '''k${keyword.lexeme[0].toUpperCase()}${keyword.lexeme.substring(1).toLowerCase()}''';
      return acc;
    },
  );

  Map<String, dynamic> toMap(ArbChange arbChange) {
    final arbValue = this.arbValue(arbChange);

    final arbUpdate = <String, dynamic>{};
    arbUpdate[arbChange.chosenAbbreviation] = arbValue;
    for (final param in arbChange.params) {
      arbUpdate['@${arbChange.chosenAbbreviation}'] ??= <String, dynamic>{};
      (arbUpdate['@${arbChange.chosenAbbreviation}']
          as Map<String, dynamic>)['placeholders'] ??= <String, dynamic>{};
      ((arbUpdate['@${arbChange.chosenAbbreviation}']
              as Map<String, dynamic>)['placeholders']
          as Map<String, dynamic>)[param.name] = {
        'type': param.paramType?.knownType.asString ??
            KnownParamType.string.asString,
      };
    }

    return arbUpdate;
  }

  String contextReplacement(ArbChange arbChange) {
    final abbreviation = arbChange.chosenAbbreviation;
    final params = arbChange.params.map((param) {
      final dartType = param.interpolation.dartType;
      var originalCallerContents = param.interpolation.originalCallerContents;
      final existingParamTypeFromArb = param.paramType?.knownType;
      final expression = param.interpolation.expression.expression;

      // add null assertion for nullable types
      if (dartType.nullabilitySuffix == NullabilitySuffix.question) {
        originalCallerContents =
            '${_maybeAddParens(originalCallerContents, expression)}!';
      }

      // if type doesn't match, we need to modify the caller
      if (!dartType.matchesKnownType(existingParamTypeFromArb)) {
        switch (existingParamTypeFromArb) {
          case KnownParamType.string:
            return '$originalCallerContents.toString()';
          case KnownParamType.integer:
            return 'int.parse($originalCallerContents)';
          case null:
            if (!dartType.isValidType) {
              return '''${_maybeAddParens(originalCallerContents, expression)}.toString()''';
            }
        }
      }

      return originalCallerContents;
    });

    final p = params.isEmpty ? '' : '(${params.join(', ')})';
    return 'context.sonnet.$abbreviation$p';
  }

  String _maybeAddParens(
    String originalCallerContents,
    Expression expression,
  ) {
    if (expression is SimpleIdentifier ||
        expression is ParenthesizedExpression ||
        expression is ThisExpression ||
        expression is InstanceCreationExpression ||
        expression is SuperExpression) {
      return originalCallerContents;
    }

    return '($originalCallerContents)';
  }
}

extension on DartType {
  bool matchesKnownType(KnownParamType? knownType) {
    if (this is InterfaceType) {
      switch (knownType) {
        case KnownParamType.string:
          return isDartCoreString;
        case KnownParamType.integer:
          return isDartCoreInt;
        case null:
          break;
      }
    }

    return false;
  }

  bool get isValidType => KnownParamType.values.any(matchesKnownType);
}

extension ExpressionX on Expression {
  void generateAbbreviation(void Function(String) append) {
    final localThis = this;
    if (localThis is SimpleIdentifier) {
      append(localThis.name);
    } else if (localThis is PropertyAccess) {
      localThis.propertyName.generateAbbreviation(append);
    } else if (localThis is MethodInvocation) {
      final methodName = localThis.methodName;
      late final target = localThis.target;
      if (methodName.name == 'toString' && target != null) {
        target.generateAbbreviation(append);
      } else {
        append(localThis.methodName.name);
      }
    } else if (localThis is BinaryExpression) {
      final rightOperand = localThis.rightOperand;

      if (rightOperand is Literal && localThis.leftOperand is! Literal) {
        if (rightOperand is IntegerLiteral) {
          append('n');
        } else {
          localThis.leftOperand.generateAbbreviation(append);
        }
      } else {
        localThis.rightOperand.generateAbbreviation(append);
      }
    } else if (localThis is FunctionExpressionInvocation) {
      localThis.function.generateAbbreviation(append);
    } else if (localThis is PostfixExpression) {
      localThis.operand.generateAbbreviation(append);
    } else if (localThis is PrefixedIdentifier) {
      localThis.identifier.generateAbbreviation(append);
    } else if (localThis is ConditionalExpression) {
      localThis.condition.generateAbbreviation(append);
    } else if (localThis is AsExpression) {
      localThis.expression.generateAbbreviation(append);
    } else if (localThis is AwaitExpression) {
      localThis.expression.generateAbbreviation(append);
    } else if (localThis is CascadeExpression) {
      localThis.target.generateAbbreviation(append);
    } else if (localThis is IndexExpression) {
      final target = localThis.target;
      if (target == null) {
        append('index');
      } else {
        target.generateAbbreviation(append);
      }
    } else if (localThis is IsExpression) {
      localThis.expression.generateAbbreviation(append);
    } else if (localThis is PrefixExpression) {
      localThis.operand.generateAbbreviation(append);
    } else if (localThis is ThrowExpression) {
      localThis.expression.generateAbbreviation(append);
    } else if (localThis is ThisExpression) {
      final type =
          localThis.staticType?.getDisplayString(withNullability: true);
      append(type ?? 'this');
    } else if (localThis is InstanceCreationExpression) {
      append(
        localThis.constructorName.name?.name ??
            localThis.staticType?.getDisplayString(withNullability: false) ??
            '',
      );
    } else if (localThis is ConstructorReference) {
      append(localThis.constructorName.name?.name ?? '');
    } else if (localThis is InvocationExpression) {
      append(localThis.function.toString());
    } else if (localThis is NullShortableExpression) {
      localThis.nullShortingTermination.generateAbbreviation(append);
    } else if (localThis is ParenthesizedExpression) {
      localThis.expression.generateAbbreviation(append);
    } else if (localThis is SwitchExpression) {
      localThis.expression.generateAbbreviation(append);
    } else if (localThis is RethrowExpression) {
      append('rethrow');
    } else if (localThis is SuperExpression) {
      append('super');
    } else if (localThis is TypeLiteral) {
      append(localThis.type.toString());
    } else if (localThis is AssignmentExpression) {
      localThis.rightHandSide.generateAbbreviation(append);
    } else if (localThis is Literal) {
      append(localThis.toString());
    } else {
      append(localThis.toString());
    }
  }
}
