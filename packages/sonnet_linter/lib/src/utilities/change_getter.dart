// ignore_for_file: avoid_print

import 'package:collection/collection.dart';
import 'package:sonnet_linter/src/forks/casing.dart';
import 'package:sonnet_linter/src/models/arb_change.dart';
import 'package:sonnet_linter/src/models/diagnostic.dart';

typedef PromptInput = Future<InputReceived> Function(InputPrompt, Diagnostic);

class ChangeGetter {
  // synchronous version of `get` where all defaults are accepted.
  static ArbChange? getDefault(
    Diagnostic diagnostic, {
    required Map<String, dynamic> arb,
  }) {
    final valueAlreadyInArb = arb.entries.firstWhereOrNull((v) {
      return v.value is String &&
          diagnostic.arbMatcher.hasMatch(v.value.toString());
    });

    if (valueAlreadyInArb != null) {
      return _fromValueAlreadyInArb(valueAlreadyInArb, arb, diagnostic);
    }

    final generatedAbbreviation = diagnostic.generatedAbbreviation;
    final string = diagnostic.originalString;
    if (generatedAbbreviation.isEmpty) return null;

    final uniqueKey = _uniqueKey(
      generatedAbbreviation,
      arb.keys,
      isRedundant: _isRedundant(diagnostic, arb),
    );

    final params = <Param>[];

    for (final interpolation in diagnostic.interpolations) {
      final buffer = StringBuffer();

      interpolation.expression.expression
          .generateAbbreviation(buffer.appendCamel);

      if (buffer.isEmpty) continue;

      final generatedParamName = buffer.toString().camelize;

      final paramUniqueKey = _uniqueKey(
        generatedParamName,
        params.map((p) => p.name),
        isRedundant: (_) => false,
      );

      if (paramUniqueKey.isEmpty) return null;

      params.add(
        Param(
          name: paramUniqueKey,
          paramType: DartParamType.fromType(interpolation.dartType),
          interpolation: interpolation,
        ),
      );
    }

    return ArbChange(
      string: string,
      chosenAbbreviation: uniqueKey,
      params: params,
    );
  }

  static Future<ArbChange?> get(
    Diagnostic diagnostic, {
    required Map<String, dynamic> arb,
    required PromptInput promptInput,
    required Future<void> Function() onExit,
  }) async {
    final valueAlreadyInArb = arb.entries.firstWhereOrNull((v) {
      return v.value is String &&
          diagnostic.arbMatcher.hasMatch(v.value.toString());
    });

    if (valueAlreadyInArb != null) {
      return _fromValueAlreadyInArb(valueAlreadyInArb, arb, diagnostic);
    }

    final generatedAbbreviation = diagnostic.generatedAbbreviation;
    if (generatedAbbreviation.isEmpty) return null;

    final uniqueKey = _uniqueKey(
      generatedAbbreviation,
      arb.keys,
      isRedundant: _isRedundant(diagnostic, arb),
    );

    final autoAccept = arb.containsKey(uniqueKey);

    final response = autoAccept
        ? InputReceivedAccept()
        : await promptInput(
            StringLiteralInputPrompt(
              originalString: diagnostic.originalString,
              generatedAbbreviation: uniqueKey,
            ),
            diagnostic,
          );

    switch (response) {
      case InputReceivedAccept():
        break;
      case InputReceivedSkip():
        return null;
      case InputReceivedQuit():
        await onExit();
        return null;
      case InputReceivedRequestRename():
        break;
      case InputReceivedInvalid():
        return get(
          diagnostic,
          arb: arb,
          promptInput: promptInput,
          onExit: onExit,
        );
      case InputReceivedRename():
        final newName = await _getNewVariableName(
          uniqueKey,
          promptInput: promptInput,
          diagnostic: diagnostic,
          onExit: onExit,
        );

        if (newName == null || newName.isEmpty) return null;

        return ArbChange(
          string: diagnostic.originalString,
          chosenAbbreviation: newName,
        );
    }

    final params = <Param>[];

    for (final interpolation in diagnostic.interpolations) {
      final buffer = StringBuffer();
      interpolation.expression.expression
          .generateAbbreviation(buffer.appendCamel);

      if (buffer.isEmpty) continue;

      final generatedParamName = buffer.toString().camelize;

      final paramUniqueKey = _uniqueKey(
        generatedParamName,
        params.map((p) => p.name),
        isRedundant: (_) => false,
      );

      final response = autoAccept
          ? InputReceivedAccept()
          : await promptInput(
              StringInterpolationVariablePrompt(
                originalString: interpolation.originalCallerContents,
                generatedParamName: paramUniqueKey,
              ),
              diagnostic,
            );

      String? chosenParamName = paramUniqueKey;
      switch (response) {
        case InputReceivedAccept():
          break;
        case InputReceivedSkip():
          return null;
        case InputReceivedQuit():
          await onExit();
          return null;
        case InputReceivedRequestRename():
          break;
        case InputReceivedInvalid():
          return get(
            diagnostic,
            arb: arb,
            promptInput: promptInput,
            onExit: onExit,
          );
        case InputReceivedRename():
          chosenParamName = await _getNewVariableName(
            paramUniqueKey,
            promptInput: promptInput,
            diagnostic: diagnostic,
            onExit: onExit,
          );
      }

      if (chosenParamName == null || chosenParamName.isEmpty) return null;

      params.add(
        Param(
          name: chosenParamName,
          paramType: DartParamType.fromType(interpolation.dartType),
          interpolation: interpolation,
        ),
      );
    }

    return ArbChange(
      string: diagnostic.originalString,
      chosenAbbreviation: uniqueKey,
      params: params,
    );
  }

  static bool Function(String) _isRedundant(
    Diagnostic diagnostic,
    Map<String, dynamic> arb,
  ) {
    return (String key) {
      return diagnostic.arbMatcher.hasMatch(arb[key].toString()) ||
          diagnostic.escapedArbMatcher.hasMatch(arb[key].toString()) ||
          diagnostic.escapedArbMatcher.hasMatch(
            RegExp.escape(arb[key].toString()),
          );
    };
  }

  static String _uniqueKey(
    String givenKey,
    Iterable<String> all, {
    required bool Function(String key) isRedundant,
    int iteration = 1,
  }) {
    var key = givenKey;
    final previousIteration = '${iteration - 1}';
    if (iteration > 2 && key.endsWith(previousIteration)) {
      key = key.replaceFirst(RegExp('$previousIteration\$'), '');
    }
    key = '$key${iteration == 1 ? '' : iteration}';

    if (all.contains(key)) {
      if (isRedundant(key)) return key;

      key = _uniqueKey(
        key,
        all,
        iteration: iteration + 1,
        isRedundant: isRedundant,
      );
    }

    return Diagnostic.keywordMapping[key] ?? key;
  }

  static Future<String?> _getNewVariableName(
    String currentName, {
    required PromptInput promptInput,
    required Diagnostic diagnostic,
    required Future<void> Function() onExit,
  }) async {
    final response = await promptInput(
      RenameVariableInputPrompt(currentName: currentName),
      diagnostic,
    );

    switch (response) {
      case InputReceivedQuit():
        await onExit();
        return null;
      case InputReceivedSkip():
      case InputReceivedAccept():
        return currentName;
      case InputReceivedInvalid():
      case InputReceivedRequestRename():
        return _getNewVariableName(
          currentName,
          promptInput: promptInput,
          diagnostic: diagnostic,
          onExit: onExit,
        );
      case InputReceivedRename():
        final newName = response.newName;
        if (newName?.isEmpty ?? true) {
          print('Invalid response');
          return _getNewVariableName(
            currentName,
            promptInput: promptInput,
            diagnostic: diagnostic,
            onExit: onExit,
          );
        } else if (newName?.camelize != response.newName) {
          print(
            '''Variable name must be in camelCase${(newName ?? '').isNotEmpty ? ' (expected ${response.newName!.camelize})' : ''}''',
          );
          return _getNewVariableName(
            currentName,
            promptInput: promptInput,
            diagnostic: diagnostic,
            onExit: onExit,
          );
        }
        return response.newName ?? currentName;
    }
  }

  static ArbChange? _fromValueAlreadyInArb(
    MapEntry<String, dynamic> valueAlreadyInArb,
    Map<String, dynamic> arb,
    Diagnostic diagnostic,
  ) {
    final params = <Param>[];
    final abbreviation = valueAlreadyInArb.key;

    final placeholders =
        ((arb['@${valueAlreadyInArb.key}'] as Map<String, dynamic>? ??
                {})['placeholders'] as Map<String, dynamic>?) ??
            <String, dynamic>{};

    for (final (i, placeholder) in placeholders.entries.indexed) {
      final interpolation = diagnostic.interpolations.elementAtOrNull(i);

      if (interpolation == null) return null;

      params.add(
        Param(
          name: placeholder.key,
          paramType: ArbParamType.fromString(
            (placeholder.value! as Map<String, Object?>)['type']! as String,
          ),
          interpolation: interpolation,
        ),
      );
    }

    return ArbChange(
      string: diagnostic.originalString,
      chosenAbbreviation: abbreviation,
      params: params,
    );
  }
}

sealed class InputPrompt {}

class StringLiteralInputPrompt extends InputPrompt {
  StringLiteralInputPrompt({
    required this.originalString,
    required this.generatedAbbreviation,
  });
  final String originalString;
  final String generatedAbbreviation;
}

class StringInterpolationVariablePrompt extends InputPrompt {
  StringInterpolationVariablePrompt({
    required this.originalString,
    required this.generatedParamName,
  });
  final String originalString;
  final String generatedParamName;
}

class RenameVariableInputPrompt extends InputPrompt {
  RenameVariableInputPrompt({
    required this.currentName,
  });
  final String currentName;
}

class RenameParamInputPrompt extends InputPrompt {
  RenameParamInputPrompt({
    required this.currentName,
  });
  final String currentName;
}

sealed class InputReceived {}

class InputReceivedAccept extends InputReceived {}

class InputReceivedSkip extends InputReceived {}

class InputReceivedQuit extends InputReceived {}

class InputReceivedRequestRename extends InputReceived {}

class InputReceivedRename extends InputReceived {
  InputReceivedRename([this.newName]);
  final String? newName;
}

class InputReceivedInvalid extends InputReceived {}
