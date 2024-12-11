import 'dart:async';

import 'package:intl_generator/generate_localized.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  Storage._() {
    SharedPreferences.getInstance().then((sharedPreferences) {
      this.sharedPreferences.complete(sharedPreferences);
    });
  }

  static Storage get instance => _instance;

  static final Storage _instance = Storage._();

  static const _sharedPrefsPrefix = 'sonnet_storage_';

  static Future<void> init(String publicKey) async {
    // TODO: load manifest from server
    instance.manifest.complete({});
  }

  final Map<String, List<Map<String, Object>>> metaData = {};
  final Map<String, Map<String, TranslatedMessage>> messages = {};
  final Completer<SharedPreferences> sharedPreferences = Completer();

  final Completer<Map<String, int>> manifest = Completer();

  Future<void> store(String locale, int version, String data) async {
    final s = await sharedPreferences.future;
    await s.setString(_sharedPrefsPrefix + locale, data);
    await s.setInt(versionKey(locale), version);
  }

  Future<String?> dataFor(String locale) async {
    final s = await SharedPreferences.getInstance();
    return s.getString(_sharedPrefsPrefix + locale);
  }

  Future<int?> storedVersion(String locale) async {
    final s = await sharedPreferences.future;
    return s.getInt(versionKey(locale));
  }

  String versionKey(String locale) => '$_sharedPrefsPrefix${locale}_version';
}
