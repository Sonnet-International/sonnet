import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:sonnet/src/extensions.dart';

import 'l10n_loader.dart';

typedef OnError = void Function(dynamic error, dynamic stackTrace);

class Sonnet extends StatefulWidget {
  // ignore: always_put_required_named_parameters_first
  const Sonnet({super.key, required this.builder});

  static void init({
    required String publicKey,
    String? initialLocale,
    OnError? onError,
  }) {
    _publicKey = publicKey;
    _initialLocale = initialLocale.presence;
    _onError = onError;

    if (_initialLocale != null) {
      _localeStreamController.add(_initialLocale!);
    }
  }

  static String? _publicKey;
  static String? _initialLocale;
  static OnError? _onError;

  static final L10nLoader _loader = L10nLoader();
  static final StreamController<String> _localeStreamController =
      StreamController<String>.broadcast();
  static final Stream<String?> _localeStream =
      _localeStreamController.stream.distinct();

  static String _normalizedLocale(String? locale) =>
      Intl.canonicalizedLocale(locale);

  static String get(
    String localeName,
    String id, {
    Map<String, Object>? args,
    String fallback = '',
  }) {
    localeName = _normalizedLocale(localeName);
    return Intl.message(
      fallback,
      name: id,
      locale: localeName,
      args: args == null ? [] : [args],
    );
  }

  static Future<void> changeLocale(String locale) async {
    locale = _normalizedLocale(locale);

    await _loader.updateLocale(
      locale: locale,
      publicKey: _publicKey!,
      onError: _onError,
    );
    _localeStreamController.add(locale);
  }

  static Future<void> initialLoad(Locale locale) async {
    _initialLocale = _initialLocale.presence ?? locale.toString();
    final l = _normalizedLocale(_initialLocale);

    await _loader.initialLoad(l, _onError, _publicKey!);
    _localeStreamController.add(l);
  }

  final Widget Function(Locale? locale) builder;

  @override
  State<Sonnet> createState() => _SonnetState();
}

class _SonnetState extends State<Sonnet> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Locale?>(
      stream: Sonnet._localeStream
          .map((locale) => locale.presence == null ? null : Locale(locale!)),
      builder: (_, localeSnapshot) => widget.builder(localeSnapshot.data),
    );
  }
}
