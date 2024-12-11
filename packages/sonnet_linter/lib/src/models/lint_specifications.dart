// ignore: implementation_imports
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:sonnet_linter/src/forks/ast_extensions.dart';
import 'package:source_gen/source_gen.dart';

sealed class LintSpecification {
  bool isSatisfiedBy(AstNode element);
}

class ImportSpecification extends LintSpecification {
  ImportSpecification();

  @override
  bool isSatisfiedBy(AstNode element) => element is Directive;
}

class WidgetConstructorSpecification extends LintSpecification {
  WidgetConstructorSpecification();

  @override
  bool isSatisfiedBy(AstNode element) => element.isWidgetConstructor;
}

class ClassSpecification extends LintSpecification {
  ClassSpecification();

  @override
  bool isSatisfiedBy(AstNode element) => element.isWidgetClass;
}

class InsideWidgetSpecification extends LintSpecification {
  InsideWidgetSpecification();

  @override
  bool isSatisfiedBy(AstNode element) => element.isWithinWidget;
}

class AssertionSpecification extends LintSpecification {
  AssertionSpecification();

  @override
  bool isSatisfiedBy(AstNode element) =>
      element is Assertion ||
      element.childEntities.any((e) => e is AstNode && isSatisfiedBy(e));
}

class IgnoredConstructorSpecification extends LintSpecification {
  IgnoredConstructorSpecification();

  static const _ignoredConstructorCalls = [
    TypeChecker.fromUrl(
      'package:flutter/src/painting/image_resolution.dart#AssetImage',
    ),
    TypeChecker.fromUrl(
      'package:flutter/src/widgets/navigator.dart#RouteSettings',
    ),
    TypeChecker.fromUrl(
      'package:flutter/src/services/platform_channel.dart#MethodChannel',
    ),
    TypeChecker.fromUrl('package:flutter/src/widgets/image.dart#Image'),
    TypeChecker.fromUrl('package:flutter/src/foundation/key.dart#Key'),
    TypeChecker.fromUrl('package:logging/src/logger.dart#Logger'),
    TypeChecker.fromUrl('package:sonnet/src/sonnet.dart#Sonnet'),
    TypeChecker.fromRuntime(Exception),
    TypeChecker.fromRuntime(Error),
  ];

  @override
  bool isSatisfiedBy(AstNode element) {
    return element is InstanceCreationExpression &&
        _ignoredConstructorCalls.any(
          (checker) => checker.isAssignableFromType(element.staticType!),
        );
  }
}

class IgnoredFunctionsSpecification extends LintSpecification {
  IgnoredFunctionsSpecification();

  static const _ignoredStaticMethods = [
    TypeChecker.fromUrl('package:sonnet/src/sonnet_base.dart#Sonnet'),
  ];

  @override
  bool isSatisfiedBy(AstNode element) {
    if (element is! MethodInvocation) return false;
    final target = element.target;

    if (target is! SimpleIdentifier) return false;

    final caller = target.staticElement;
    if (caller is! ClassElement) return false;

    return _ignoredStaticMethods
        .any((checker) => checker.isAssignableFrom(caller));
  }
}

class IgnoredTextSpecification extends LintSpecification {
  IgnoredTextSpecification();

  static final _ignoreMatchers = [
    // matches strings with no alpha-numerics
    RegExp(r'^[^a-zA-Z0-9]+$'),

    // ignore urls
    RegExp(
      r'''^(.*?)((https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,4}\b([-a-zA-Z0-9@:%_\+.~#?&//="'`]*))''',
      caseSensitive: false,
      dotAll: true,
    ),

    // ignore just numbers
    RegExp(r'^[\d\s]+$'),
  ];

  // when string is generally asset-like
  static final _assetCharactersRegExp = RegExp(r'^[a-zA-Z0-9\/\.\_\-]+$');

  static final _commonFileEndingsRegex = RegExp(
    r'\.(png|jpg|jpeg|svg|gif|webp|bmp|ico|pdf|doc|docx|xls|xlsx|ppt|pptx|zip|rar|tar|gz|mp3|mp4|wav|flac|avi|mkv|mov|wmv|txt|csv|json|xml|html|css|js|ts|dart|py|java|c|cpp|h|cs|php|rb|go|swift|kt|gradle|yml|yaml|toml|ini|md)$',
    caseSensitive: false,
  );

  @override
  bool isSatisfiedBy(AstNode element) {
    final buffer = StringBuffer();

    if (element is SimpleStringLiteral) {
      buffer.write(element.stringValue?.trim() ?? '');
    } else if (element is StringInterpolation) {
      for (final childEntity in element.childEntities) {
        if (childEntity is StringToken) {
          buffer.write(childEntity.value());
        } else if (childEntity is InterpolationString) {
          buffer.write(childEntity.value);
        }
      }
    } else {
      return false;
    }

    if (buffer.isEmpty) return true;

    final string = buffer.toString();

    return _ignoreMatchers.any((matcher) => matcher.hasMatch(string)) ||
        _isAsset(string);
  }

  static bool _isAsset(String text) {
    return _assetCharactersRegExp.hasMatch(text) &&
        (text.startsWith('/') ||
            text.startsWith('assets/') ||
            _commonFileEndingsRegex.hasMatch(text));
  }
}

class StringLiteralInsideWidgetSpecification extends LintSpecification {
  StringLiteralInsideWidgetSpecification();

  final _isImport = ImportSpecification();
  final _isAssertion = AssertionSpecification();
  final _isIgnorableText = IgnoredTextSpecification();
  final _isIgnoredConstructor = IgnoredConstructorSpecification();
  final _isIgnoredFunction = IgnoredFunctionsSpecification();

  final _isConstructor = WidgetConstructorSpecification();
  final _isClass = ClassSpecification();
  final _isCompilationUnit = InsideWidgetSpecification();

  late final _ignoreSpecifications = [
    _isImport,
    _isAssertion,
    _isIgnorableText,
    _isIgnoredFunction,
    _isIgnoredConstructor,
  ];

  late final _widgetSpecifications = [
    _isConstructor,
    _isClass,
    _isCompilationUnit,
  ];

  @override
  bool isSatisfiedBy(AstNode element) {
    if (element is! StringLiteral) return false;

    return !_matchesAnySpecification(element, _ignoreSpecifications) &&
        _matchesAnySpecification(element, _widgetSpecifications);
  }

  bool _matchesAnySpecification(
    AstNode element,
    List<LintSpecification> specifications,
  ) {
    return element.thisOrAncestorMatching((e) {
          return specifications.any((s) => s.isSatisfiedBy(e));
        }) !=
        null;
  }
}
