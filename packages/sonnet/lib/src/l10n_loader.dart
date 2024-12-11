import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
// ignore: implementation_imports
import 'package:intl/src/intl_helpers.dart';
import 'package:intl_generator/generate_localized.dart';

import '../sonnet.dart';
import 'custom_lookup.dart';
import 'storage.dart';

class L10nLoader {
  static String? _currentLocale;

  static String _normalizedLocale(String? locale) =>
      Intl.canonicalizedLocale(locale);

  Future<void> initialLoad(
    String initialLocale,
    OnError? onError,
    String publicKey,
  ) async {
    final locale = _normalizedLocale(initialLocale);
    initializeInternalMessageLookup(CustomCompositeMessageLookup.new);
    await initializeDateFormatting();

    // load in-memory data, if exists
    try {
      final inMemoryData = await Storage.instance.dataFor(locale);
      if (inMemoryData != null) {
        _parseMetaData(inMemoryData);
        _loadLocale(locale, inMemoryData);
      }
    } catch (e, stack) {
      onError?.call(e, stack);
    }

    // get update from server, if needed
    try {
      final remoteData =
          await _fetchRemoteData(locale: locale, publicKey: publicKey);

      if (remoteData != null) {
        _parseMetaData(remoteData);
        _loadLocale(locale, remoteData);
      }
    } catch (e, stack) {
      onError?.call(e, stack);
    }

    messageLookup.addLocale(
      locale,
      (String locale) => CustomLookup(
        localeName: Intl.canonicalizedLocale(locale),
        defaultLocaleName: locale,
      ),
    );
  }

  void _parseMetaData(String arbContent) {
    (jsonDecode(arbContent) as Map<String, Map>)
        .forEach((String id, Map<dynamic, dynamic> messageData) {
      if (id.startsWith('@@')) {
        return;
      }
      if (id.startsWith('@')) {
        if (messageData.containsKey('placeholders')) {
          Storage.instance.metaData[id.substring(1).toLowerCase()] = [
            Map<String, Object>.from(messageData['placeholders']! as Map),
          ];
        }
      }
    });
  }

  void _loadLocale(String locale, String arbContent) {
    final arbData = jsonDecode(arbContent) as Map<String, dynamic>;

    final messages = <String, TranslatedMessage>{};

    arbData.forEach((id, messageData) {
      final TranslatedMessage? message = recreateIntlObjects(
        id,
        messageData,
        arbData['@$id'] as Map<String, dynamic>? ?? <String, dynamic>{},
      );
      if (message != null) {
        messages[message.id] = message;
      }
    });

    if (Storage.instance.messages.containsKey(locale)) {
      Storage.instance.messages[locale]!.addAll(messages);
    } else {
      Storage.instance.messages[locale] = messages;
    }
  }

  Future<bool> updateLocale({
    required String publicKey,
    required String locale,
    OnError? onError,
  }) async {
    locale = _normalizedLocale(locale);
    if (locale == _currentLocale) return false;

    // load in-memory data, if exists
    try {
      final inMemoryData = await Storage.instance.dataFor(locale);
      if (inMemoryData != null) {
        _parseMetaData(inMemoryData);
        _loadLocale(locale, inMemoryData);
        _currentLocale = locale;
      }
    } catch (e, stack) {
      onError?.call(e, stack);
    }

    // fetch data from server, if needed
    var updated = false;
    try {
      final data = await _fetchRemoteData(locale: locale, publicKey: publicKey);

      if (data != null) {
        _parseMetaData(data);
        _loadLocale(locale, data);
        updated = true;
        _currentLocale = locale;
      }
    } catch (e, stack) {
      onError?.call(e, stack);
    }

    return updated;
  }

  Future<String?> _fetchRemoteData({
    required String locale,
    required String publicKey,
  }) async {
    locale = _normalizedLocale(locale);

    try {
      final latestVersion =
          (await Storage.instance.manifest.future)[locale] ?? 0;
      final storedVersion = await Storage.instance.storedVersion(locale);

      if (storedVersion != null && storedVersion >= latestVersion) return null;

      // TODO: Get from server
      final data = await rootBundle.loadString('assets/$locale.arb');
      final version = DateTime.now().millisecondsSinceEpoch;

      await Storage.instance.store(locale, version, data);

      return data;
    } catch (e) {
      final justLanguage = locale.split(RegExp('_|-'))[0];

      if (justLanguage != locale) {
        log(
          'No data found for $locale. Attempting to fetch from $justLanguage',
        );

        return _fetchRemoteData(locale: justLanguage, publicKey: publicKey);
      } else {
        rethrow;
      }
    }
  }
}
