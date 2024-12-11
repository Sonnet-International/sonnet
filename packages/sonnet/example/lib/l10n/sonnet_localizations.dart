import 'dart:convert';

import 'app_localizations.dart';

import 'package:sonnet/sonnet.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

export 'package:flutter_localizations/flutter_localizations.dart';
export 'package:sonnet/sonnet.dart';

class SonnetLocalizations extends AppLocalizations {
  final AppLocalizations _fallbacks;
  
  SonnetLocalizations(String locale, AppLocalizations fallbackTexts) : _fallbacks = fallbackTexts, super(locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _SonnetLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <
      LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = AppLocalizations.supportedLocales;
 
	@override String get helloWorld => Sonnet.get(localeName, 'helloWorld', fallback: _fallbacks.helloWorld);
	@override String get changeLocale => Sonnet.get(localeName, 'changeLocale', fallback: _fallbacks.changeLocale);
	@override String get increment => Sonnet.get(localeName, 'increment', fallback: _fallbacks.increment);
	@override String get sonnetDemo => Sonnet.get(localeName, 'sonnetDemo', fallback: _fallbacks.sonnetDemo);
	@override String get foo => Sonnet.get(localeName, 'foo', fallback: _fallbacks.foo);
}

class _SonnetLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SonnetLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.delegate.load(locale)
          .then((fallback) { 
            Sonnet.initialLoad(locale);
            return SonnetLocalizations(locale.toString(), fallback);
          });

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.contains(locale);

  @override
  bool shouldReload(_SonnetLocalizationsDelegate old) => false;
}

extension SonnetBuildContextExt on BuildContext {
  AppLocalizations get sonnet => AppLocalizations.of(this)!;

  changeSonnetLocale(String locale) => Sonnet.changeLocale(locale);
}

