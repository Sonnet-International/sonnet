import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
// ignore: implementation_imports
import 'package:intl/src/intl_helpers.dart';
import 'package:intl_generator/generate_localized.dart';
import 'package:sonnet/src/extensions.dart';
import 'package:sonnet/src/storage.dart';

import 'producer.dart';

class CustomLookup extends MessageLookupByLibrary {
  CustomLookup({
    required this.localeName,
    required this.defaultLocaleName,
  });

  @override
  final String localeName;
  final String defaultLocaleName;

  @override
  Map<String, dynamic> get messages => throw UnimplementedError();

  @override
  String? lookupMessage(
    String? messageText,
    String? locale,
    String? name,
    List<Object>? args,
    String? meaning, {
    MessageIfAbsent? ifAbsent,
  }) {
    // If passed null, use the default.
    final knownLocale = locale ?? localeName;

    final messages = Storage.instance.messages[knownLocale]!;
    final sentence = messages[name!];

    // sentence is not available in current locale, let's take the default one
    if (sentence == null) {
      final defaultMessages = Storage.instance.messages[defaultLocaleName]!;
      final defaultSentence = defaultMessages[name];

      if (defaultSentence == null) {
        log('no message found for $name, default to $messageText');
        return messageText;
      }

      return Producer.getString(
        knownLocale,
        name.toLowerCase(),
        defaultSentence.translated!,
        defaultSentence is BasicTranslatedMessage
            ? defaultSentence.metaData
            : null,
        (args?.firstOrNull as Map<String, Object>?) ?? {},
      );
    }

    return Producer.getString(
      knownLocale,
      name.toLowerCase(),
      sentence.translated!,
      sentence is BasicTranslatedMessage ? sentence.metaData : null,
      (args?.firstOrNull as Map<String, Object>?) ?? {},
    );
  }
}

/// Regenerate the original IntlMessage objects from the given [data]. For
/// things that are messages, we expect [id] not to start with "@" and
/// [data] to be a String. For metadata we expect [id] to start with "@"
/// and [data] to be a Map or null. For metadata we return null.
BasicTranslatedMessage? recreateIntlObjects(
  String id,
  dynamic data,
  Map<dynamic, dynamic> metaData,
) {
  if (id.startsWith('@')) return null;
  if (data == null) return null;
  final parts =
      IcuParser().interiorText.parse(data.toString()).value as List<Object>;
  final asMessages = parts.map<Message>((c) => Message.from(c, null));
  final parsed = CompositeMessage(asMessages.toList(), null);

  return BasicTranslatedMessage(id, parsed, metaData);
}

/// A TranslatedMessage that just uses the name as the id and knows how to look
/// up its original messages in our messages.
class BasicTranslatedMessage extends TranslatedMessage {
  BasicTranslatedMessage(super.name, super.translated, this.metaData);
  Map<dynamic, dynamic> metaData;

  @override
  List<MainMessage> get originalMessages => (super.originalMessages.isEmpty)
      ? _findOriginals()
      : super.originalMessages;

  // We know that our [id] is the name of the message, which is used as the
  //key in [messages].
  List<MainMessage> _findOriginals() => originalMessages = [];
}

/// This is a message lookup mechanism that delegates to one of a collection
/// of individual [MessageLookupByLibrary] instances.
class CustomCompositeMessageLookup implements MessageLookup {
  CustomCompositeMessageLookup({this.cacheLocale = true});

  final bool cacheLocale;

  /// A map from locale names to the corresponding lookups.
  final Map<String, MessageLookupByLibrary> availableMessages = {};

  /// Return true if we have a message lookup for [localeName].
  bool localeExists(dynamic localeName) =>
      availableMessages.containsKey(localeName);

  /// The last locale in which we looked up messages.
  ///
  ///  If this locale matches the new one then we can skip looking up the
  ///  messages and assume they will be the same as last time.
  String? _lastLocale;

  /// Caches the last messages that we found
  MessageLookupByLibrary? _lastLookup;

  static String? _language(String? locale) =>
      locale?.split(RegExp('[_-]')).firstOrNull;

  /// Look up the message with the given [name] and [locale] and return the
  /// translated version with the values in [args] interpolated.
  @override
  String? lookupMessage(
    String? messageText,
    String? locale,
    String? name,
    List<Object>? args,
    String? meaning, {
    MessageIfAbsent? ifAbsent,
  }) {
    final defaultLocale = Intl.defaultLocale;
    final currentLocale = Intl.getCurrentLocale();

    final supportedLocale = {
      locale,
      Intl.canonicalizedLocale(locale),
      _language(locale),
      currentLocale,
      Intl.canonicalizedLocale(currentLocale),
      _language(currentLocale),
      defaultLocale,
      Intl.canonicalizedLocale(defaultLocale),
      _language(defaultLocale),
    }.firstWhereOrNull((locale) {
      locale = locale.presence;
      final isPresent = locale != null;

      if (!isPresent) return false;

      if (localeExists(locale) &&
          Storage.instance.messages.containsKey(locale)) {
        _lastLocale = locale;
        _lastLookup = availableMessages[locale];

        return true;
      }

      return false;
    });

    if (supportedLocale == null) return messageText;

    final messages = (supportedLocale == _lastLocale && _lastLookup != null)
        ? _lastLookup
        : _lookupMessageCatalog(supportedLocale);
    if (messages == null) return messageText;

    return messages.lookupMessage(
      messageText,
      supportedLocale,
      name,
      args,
      meaning,
    );
  }

  MessageLookupByLibrary? _lookupMessageCatalog(String locale) {
    final verifiedLocale = Intl.verifiedLocale(
      locale,
      localeExists,
      onFailure: (locale) => locale,
    );
    _lastLocale = locale;
    return _lastLookup = availableMessages[verifiedLocale];
  }

  @override
  void addLocale(String localeName, Function findLocale) {
    if (localeExists(localeName) && cacheLocale) return;
    final canonical = Intl.canonicalizedLocale(localeName);
    // ignore: avoid_dynamic_calls
    final dynamic newLocale = findLocale(canonical);
    if (newLocale != null) {
      availableMessages[localeName] = newLocale as MessageLookupByLibrary;
      availableMessages[canonical] = newLocale;
      // If there was already a failed lookup for [newLocale], null the cache.
      // ignore: unrelated_type_equality_checks
      if (_lastLocale == newLocale) {
        _lastLocale = null;
        _lastLookup = null;
      }
    }
  }
}
