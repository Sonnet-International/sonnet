import 'dart:developer';

import 'package:intl/intl.dart';
import 'package:intl_generator/generate_localized.dart';

class Producer {
  static String getString(
    String locale,
    String id,
    Message message,
    Map<dynamic, dynamic>? metaData,
    Map<String, Object> args,
  ) {
    if (message is LiteralString) {
      return message.string;
    } else if (message is CompositeMessage) {
      final s = StringBuffer();
      for (final element in message.pieces) {
        s.write(getString(locale, id, element, metaData, args));
      }
      return s.toString();
    }
    if (message is VariableSubstitution) {
      final placeholder = args[message.variableName.toLowerCase()];

      if (placeholder == null) {
        throw Exception('Missing placeholder ${message.variableName}');
      }

      final placeholders = metaData!['placeholders'] as Map<String, dynamic>?;
      final m = placeholders![message.variableName.toLowerCase()]!
          as Map<String, dynamic>?;

      final type = m?['type']?.toString().toLowerCase();

      if (type == null) {
        throw Exception('Missing type for placeholder ${message.variableName}');
      }

      switch (type) {
        case 'string':
        case 'object':
          return placeholder.toString();
        case 'int':
        case 'double':
        case 'num':
          final format = m!['format'] as String?;
          final p = num.parse(placeholder.toString());
          late final decimalDigits =
              int.tryParse(m['decimalDigits'].toString());
          late final name = m['name'] as String?;
          late final symbol = m['symbol'] as String?;
          late final customPattern = m['customPattern'] as String?;

          switch (format) {
            case 'compact':
              return NumberFormat.compact(locale: locale).format(p);
            case 'percentPattern':
              return NumberFormat.percentPattern(locale).format(p);
            case 'currencyPattern':
              // ignore: deprecated_member_use
              return NumberFormat.currencyPattern(locale).format(p);
            case 'scientificPattern':
              return NumberFormat.scientificPattern(locale).format(p);
            case 'compactLong':
              return NumberFormat.compactLong(locale: locale).format(p);
            case 'decimalPattern':
              return NumberFormat.decimalPattern(locale).format(p);
            case 'compactCurrency':
              return NumberFormat.compactCurrency(
                locale: locale,
                name: name,
                symbol: symbol,
                decimalDigits: decimalDigits,
              ).format(p);
            case 'compactSimpleCurrency':
              return NumberFormat.compactSimpleCurrency(
                locale: locale,
                name: name,
                decimalDigits: decimalDigits,
              ).format(p);
            case 'currency':
              return NumberFormat.currency(
                locale: locale,
                name: name,
                symbol: symbol,
                decimalDigits: decimalDigits,
                customPattern: customPattern,
              ).format(p);
            case 'decimalPercentPattern':
              return NumberFormat.decimalPercentPattern(
                locale: locale,
                decimalDigits: decimalDigits,
              ).format(p);
            case 'simpleCurrency':
              return NumberFormat.simpleCurrency(
                locale: locale,
                name: name,
                decimalDigits: decimalDigits,
              ).format(p);
            default:
              throw Exception('Unknown format $format for $placeholder');
          }
        case 'datetime':
          final format = m!['format'] as String?;

          if (format == null) {
            return placeholder.toString();
          } else {
            return DateFormat(format, locale).format(placeholder as DateTime);
          }
        default:
          throw Exception(
            'Unsupported type $type for placeholder ${message.variableName}',
          );
      }
    } else if (message is Gender) {
      return Intl.genderLogic(
        args[message.mainArgument].toString(),
        locale: locale,
        other: getString(locale, id, message.other!, metaData, args),
        male: getString(
          locale,
          id,
          message.male ?? message.other!,
          metaData,
          args,
        ),
        female: getString(
          locale,
          id,
          message.female ?? message.other!,
          metaData,
          args,
        ),
      );
    } else if (message is Plural) {
      return Intl.pluralLogic(
        args[message.mainArgument]! as num,
        locale: locale,
        other: getString(locale, id, message.other!, metaData, args),
        few: getString(
          locale,
          id,
          message.few ?? message.other!,
          metaData,
          args,
        ),
        many: getString(
          locale,
          id,
          message.many ?? message.other!,
          metaData,
          args,
        ),
        one: getString(
          locale,
          id,
          message.one ?? message.other!,
          metaData,
          args,
        ),
        two: getString(
          locale,
          id,
          message.two ?? message.other!,
          metaData,
          args,
        ),
        zero: getString(
          locale,
          id,
          message.zero ?? message.other!,
          metaData,
          args,
        ),
      );
    } else if (message is Select) {
      return Intl.selectLogic(
        args[message.mainArgument]!,
        Map<Object, String>.fromEntries(
          message.cases.entries.map((entry) {
            return MapEntry<Object, String>(
              entry.key,
              getString(locale, id, entry.value, metaData, args),
            );
          }),
        ),
      );
    } else {
      log('Unsupported type ${message.runtimeType}');
    }
    return '';
  }
}
