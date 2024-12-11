import 'package:number_to_character/number_to_character.dart';

extension StringX on String {
  String get camelize => Casing.camelCase(this);
}

final _numberToCharacterConverter = NumberToCharacterConverter('en');

class Casing {
  static final RegExp _digitRegExp = RegExp(r'\d');

  static String camelCase(String inputString) {
    final input = inputString
        .trim()
        .replaceAll(RegExp(r'[/_-\s]'), ' ')
        .replaceAll(r'\n', ' ')
        .replaceAll(r'\t', ' ')
        .replaceAll(RegExp('[^a-zA-Z0-9 ]'), '')
        .trim();

    if (input.isEmpty) return '';

    // if it's already camel-cased, return as is
    if (RegExp(r'^[a-z][a-z0-9]*$').hasMatch(input)) return input;

    final group = input.split(' ').where((e) => e.isNotEmpty).toList();

    final buffer = StringBuffer();

    for (var i = 0; i < group.length; i++) {
      final word = group[i];

      if (i == 0) {
        if (word.startsWith(_digitRegExp)) {
          final number = word
              .split('')
              .takeWhile((e) => e.startsWith(_digitRegExp))
              .take(4)
              .join();

          if (number.length < 4) {
            buffer.write(
              _numberToCharacterConverter
                  .convertInt(int.parse(number))
                  .camelize,
            );

            final rest = word.substring(number.length);
            if (rest.isNotEmpty) {
              buffer.write(_uppercaseFirst(rest));
            }
          } else {
            buffer.write(
              _lowercaseFirst(
                _numberToCharacterConverter.convertInt(int.parse(number[0])),
              ),
            );

            number.substring(1, 3).split('').forEach((e) {
              buffer.write(
                _uppercaseFirst(
                  _numberToCharacterConverter.convertInt(int.parse(e)),
                ),
              );
            });

            final rest = number.substring(3);

            if (rest.isNotEmpty) {
              buffer.write(_uppercaseFirst(rest));
            }
          }
        } else {
          if (word.toUpperCase() == word) {
            buffer.write(word.toLowerCase());
          } else {
            buffer.write(_lowercaseFirst(word));
          }
        }
      } else {
        if (word.toUpperCase() == word) {
          buffer.write(_uppercaseFirst(word.toLowerCase()));
        } else {
          buffer.write(_uppercaseFirst(word));
        }
      }
    }

    return buffer.toString();
  }

  static String _uppercaseFirst(String word) {
    return word.replaceRange(0, 1, word[0].toUpperCase());
  }

  static String _lowercaseFirst(String word) {
    return word.replaceRange(0, 1, word[0].toLowerCase());
  }
}

extension StringBufferX on StringBuffer {
  void appendCamel(String value) {
    if (isEmpty) {
      write(value);
    } else if (value.isNotEmpty) {
      write(value[0].toUpperCase() + value.substring(1));
    }
  }
}
