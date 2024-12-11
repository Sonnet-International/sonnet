import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonnet/sonnet.dart';

void main() {
  group('en arb', () {
    const locale = Locale('en', 'US');

    setUpAll(() async {
      // ignore: avoid_init_to_null
      String? error = null;

      Sonnet.init(
        initialLocale: locale.languageCode,
        publicKey: '<PUBLIC KEY>',
        onError: (dynamic flavor, dynamic error) {
          error = error.toString();
        },
      );

      if (error != null) {
        throw Exception(error);
      }
    });

    test('text', () async {
      expect(
        Sonnet.get('helloWorld', 'en'),
        equals('Hello World!'),
      );
    });

    test('select', () async {
      expect(
        Sonnet.get('colors', 'en', args: {'color': 'blue'}),
        equals('Blue'),
      );

      expect(
        Sonnet.get('colors', 'en', args: {'color': 'green'}),
        equals('Green'),
      );

      expect(
        Sonnet.get('colors', 'en', args: {'color': 'red'}),
        equals('Red'),
      );

      expect(
        Sonnet.get('colors', 'en', args: {'color': 'yellow'}),
        equals('Something else'),
      );
    });

    test('gender', () async {
      expect(
        Sonnet.get('genderPossessive', 'en', args: {'sex': 'male'}),
        equals('His birthday'),
      );

      expect(
        Sonnet.get('genderPossessive', 'en', args: {'sex': 'female'}),
        equals('Her birthday'),
      );

      expect(
        Sonnet.get('genderPossessive', 'en', args: {'sex': 'zir'}),
        equals('Their birthday'),
      );
    });

    test('plural', () async {
      expect(
        Sonnet.get('newMessages', 'en', args: {'count': 0}),
        equals('You have no new messages'),
      );

      expect(
        Sonnet.get('newMessages', 'en', args: {'count': 1}),
        equals('You have a new message'),
      );

      expect(
        Sonnet.get('newMessages', 'en', args: {'count': 2}),
        equals('You have 2 new messages'),
      );

      expect(
        Sonnet.get('newMessages', 'en', args: {'count': 12}),
        equals('You have 12 new messages'),
      );

      expect(
        Sonnet.get('newMessages', 'en', args: {'count': -2}),
        equals('You have -2 new messages'),
      );
    });

    test('balance', () async {
      expect(
        Sonnet.get('balance', 'en', args: {'amount': 0, 'date': DateTime.now()}),
        equals('Your balance is USD0.00 on 11/5/2023'),
      );
    });
  });

  test('replacing arb', () async {
    const locale = Locale('en', 'US');
    // ignore: avoid_init_to_null
    // ignore: avoid_init_to_null
    String? error = null;

    Sonnet.init(
      initialLocale: locale.languageCode,
      publicKey: '<PUBLIC KEY>',
      onError: (dynamic flavor, dynamic error) {
        error = error.toString();
      },
    );

    if (error != null) {
      throw Exception(error);
    }

    expect(Sonnet.get('helloWorld', 'en'), equals('Hello World!'));

    await Sonnet.changeLocale(const Locale('en', 'GB').languageCode);

    expect(Sonnet.get('helloWorld', 'en'), equals('Hello Universe!'));
  });
}
