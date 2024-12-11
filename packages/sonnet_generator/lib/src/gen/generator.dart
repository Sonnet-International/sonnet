import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'gen_l10n_types.dart';
import 'l10n_config.dart';

class SonnetGenerator {
  static Future<void> generate() async {
    final projectDirectory = Directory.current.path;

    final l10nConfig = await L10nConfig.getL10nConfig();
    final genFile = File(
      path.join(
        projectDirectory,
        l10nConfig.finalOutputDir,
        'sonnet_localizations.dart',
      ),
    );
    await genFile.create(recursive: true);

    final arbPath = path.join(l10nConfig.arbDir, l10nConfig.templateArbFile);
    final arbFile = File(arbPath);
    final arbStr = await arbFile.readAsString();
    final arbJson = jsonDecode(arbStr) as Map<String, Object?>;

    final keys = getKeys(arbJson);
    final content = generationContent(
      keys: keys,
      arbResource: arbJson,
      l10nConfig: l10nConfig,
    );
    await genFile.writeAsString(content, mode: FileMode.writeOnly, flush: true);
  }

  static List<String> getKeys(Map<String, Object?> arb) {
    final keys = arb.keys.where((element) => !element.startsWith('@')).toList();
    return keys;
  }
}

String generationContent({
  required List<String> keys,
  required Map<String, Object?> arbResource,
  required L10nConfig l10nConfig,
}) {
  final buffer = StringBuffer()
    ..writeln(
      '''
import 'dart:convert';

import '${l10nConfig.outputLocalizationFile}';

import 'package:sonnet/sonnet.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

export 'package:flutter_localizations/flutter_localizations.dart';
export 'package:sonnet/sonnet.dart';

class SonnetLocalizations extends ${l10nConfig.outputClass} {
  final ${l10nConfig.outputClass} _fallbacks;
  
  SonnetLocalizations(String locale, ${l10nConfig.outputClass} fallbackTexts) : _fallbacks = fallbackTexts, super(locale);

  static const LocalizationsDelegate<${l10nConfig.outputClass}> delegate = _SonnetLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <
      LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = ${l10nConfig.outputClass}.supportedLocales;
 ''',
    );

  final arb = AppResourceBundle(arbResource);
  final messages = arb.resourceIds
      .map((id) => Message(arb, id, false))
      .toList(growable: false);
  for (final message in messages) {
    final key = message.resourceId;
    final placeholders = message.placeholders.values;

    if (message.placeholders.isEmpty) {
      buffer.writeln(
        """\t@override String get $key => Sonnet.get(localeName, '$key', fallback: _fallbacks.$key);""",
      );
    } else {
      final params = generateMethodParameters(message).join(', ');
      final values =
          placeholders.map((placeholder) => placeholder.name).join(', ');
      final args = placeholders
          .map((placeholder) => "'${placeholder.name}':${placeholder.name}")
          .join(', ');
      buffer.writeln(
        """\t@override String $key($params) => Sonnet.get(localeName, '$key', args: {$args}, fallback: _fallbacks.$key($values));""",
      );
    }
  }

  buffer.writeln('''
}

class _SonnetLocalizationsDelegate extends LocalizationsDelegate<${l10nConfig.outputClass}> {
  const _SonnetLocalizationsDelegate();

  @override
  Future<${l10nConfig.outputClass}> load(Locale locale) =>
      ${l10nConfig.outputClass}.delegate.load(locale)
          .then((fallback) { 
            Sonnet.initialLoad(locale);
            return SonnetLocalizations(locale.toString(), fallback);
          });

  @override
  bool isSupported(Locale locale) => ${l10nConfig.outputClass}.supportedLocales.contains(locale);

  @override
  bool shouldReload(_SonnetLocalizationsDelegate old) => false;
}

extension SonnetBuildContextExt on BuildContext {
  AppLocalizations get sonnet => AppLocalizations.of(this)!;

  changeSonnetLocale(String locale) => Sonnet.changeLocale(locale);
}
''');

  return buffer.toString();
}

@visibleForTesting
List<String> generateMethodParameters(Message message) {
  assert(message.placeholders.isNotEmpty);
  final pluralPlaceholder =
      message.isPlural ? message.getCountPlaceholder() : null;
  return message.placeholders.values.map((Placeholder placeholder) {
    final type = placeholder.type == pluralPlaceholder?.type
        ? specifyPluralType(pluralPlaceholder?.type, Platform.version)
        : placeholder.type;
    return '${type ?? Object} ${placeholder.name}';
  }).toList();
}

//need specifying plural types since changes in gen_l10n from Flutter 3.7.0
//https://docs.flutter.dev/development/tools/sdk/release-notes/release-notes-3.7.0
@visibleForTesting
String? specifyPluralType(String? type, String dartVersion) {
  final dartVersionNumbers = dartVersion.split('.');
  final major = int.tryParse(dartVersionNumbers[0]);
  final minor = int.tryParse(dartVersionNumbers[1]);

  if (major == null || minor == null) {
    return type;
  }

  if (major > 2 || (major == 2 && minor >= 19)) {
    return type;
  } else {
    return 'num';
  }
}
