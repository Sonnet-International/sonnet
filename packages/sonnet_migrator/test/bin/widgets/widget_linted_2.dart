// ignore_for_file: unnecessary_brace_in_string_interps, prefer_const_constructors, unnecessary_string_interpolations, unnecessary_statements, prefer_const_declarations, always_declare_return_types, use_raw_strings, depend_on_referenced_packages, lines_longer_than_80_chars, type_annotate_public_apis, unnecessary_parenthesis, prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, prefer_single_quotes, inference_failure_on_function_return_type

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sonnet/sonnet.dart';

const argStatic = 1;
const _interpolatedStatic = 'interpolated';
const multipleStatic = 'multiple';
const stringsStatic = 'strings';

enum _InternalEnum { somEnum }

class ToBeLinted extends StatelessWidget {
  const ToBeLinted({super.key});

  manyArgs({
    required String arg1,
    required String arg2,
    required String arg3,
  }) {}

  String get stringGetter => 'string getter';

  String stringFunction() => 'string function';

  String? get nullableString => null;

  @override
  Widget build(BuildContext context) {
    [Text(context.sonnet.away)];

    // constructors that should be skipped
    Logger('logger').log(Level.INFO, 'log message');
    RouteSettings(name: 'a route');
    RangeError('error message');
    Exception('exception message');
    Uri.parse('http://example.com');
    RegExp('a regex');
    Image.asset('foo');

    final someLocalString = context.sonnet.someLocalString;
    return Column(
      key: ValueKey('key'),
      children: [
        // should be skipped
        Text(''),
        Text(' '),
        Text('  '),
        Text('*'),
        Text(' *_!@@#\$%^&*)'),
        Text('http://www.example.com'),
        Text('assets/images/foo.png'),
        Text('/some-path/with/no/spaces'),
        Text('1'),
        Text('99999999999'),
        Text('no-spaces-ending-in.png'),

        // ignore: avoid_string_literals_inside_widget
        Text('ignored string literal'),
        // ignore: avoid_string_literals_inside_widget
        Text('ignored string literal'),

        Text(context.sonnet.regexp),
        Text(context.sonnet.regexp),

        Text(context.sonnet.trueAsTrueCouldBe(context.sonnet.kTrue)),
        Text(context.sonnet.trueAsTrueCouldBe(context.sonnet.kTrue)),

        Text(context.sonnet.nullableStringNullablestring((nullableString).toString())),
        Text(context.sonnet.nullableStringNullablestring((nullableString).toString())),

        Text(context.sonnet.nullableStringWrappedNullablestring((nullableString).toString())),
        Text(context.sonnet.nullableStringWrappedNullablestring((nullableString).toString())),

        Text(context.sonnet.nullableStringPlusOtherOther(nullableString ?? context.sonnet.other)),
        Text(context.sonnet.nullableStringPlusOtherOther(nullableString ?? context.sonnet.other)),

        Text(someLocalString),
        Text(someLocalString),

        Text(stringGetter),
        Text(stringGetter),

        Text(stringFunction()),
        Text(stringFunction()),

        // TODO: already camel-cased should stay camel-cased
        Text(context.sonnet.somelocalstring(someLocalString)),
        Text(context.sonnet.somelocalstring(someLocalString)),

        Text(context.sonnet.somelocalstring(stringGetter)),
        Text(context.sonnet.somelocalstring(stringGetter)),

        Text(context.sonnet.somelocalstring(stringFunction())),
        Text(context.sonnet.somelocalstring(stringFunction())),

        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic + argStatic)),
        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic + argStatic)),

        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic + argStatic + argStatic)),
        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic + argStatic + argStatic)),

        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic)),
        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic)),

        // slightly different localization
        Text(context.sonnet.interpolatedArgstatic1(argStatic)),
        Text(context.sonnet.interpolatedArgstatic1(argStatic)),

        // parameter has different type than before
        Text(context.sonnet.interpolatedArgstatic1(int.parse(multipleStatic))),
        Text(context.sonnet.interpolatedArgstatic1(int.parse(multipleStatic))),

        // very long string
        Text(
          context.sonnet.aStringThatIsDefinitelyTooLongToBeUsedAsA,
        ),
        Text(
          context.sonnet.aStringThatIsDefinitelyTooLongToBeUsedAsA,
        ),

        // reserved word
        Text(context.sonnet.kContinue),
        Text(context.sonnet.kContinue),

        // repeated word new casing
        Text(context.sonnet.kContinue2),
        Text(context.sonnet.kContinue2),

        // should remove const from lists
        ...([Text(context.sonnet.foo)]),
        ...([Text(context.sonnet.foo)]),

        // should convert enum to string
        Text(context.sonnet.somelocalstring((_InternalEnum.somEnum).toString())),
        Text(context.sonnet.somelocalstring((_InternalEnum.somEnum).toString())),

        // repeated word with characters
        Text(context.sonnet.kContinue3),
        Text(context.sonnet.kContinue3),

        // const keyword
        Text(context.sonnet.foo),
        Text(context.sonnet.foo),

        // adding strings with +
        Text('1' + '2' + context.sonnet.three4(3)),
        Text('1' + '2' + context.sonnet.three4(3)),

        // interpolation
        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic + 2)),
        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic + 2)),

        // repeated interpolation
        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic * 100)),
        Text(context.sonnet.interpolatedArgstaticArgstatic1(argStatic, argStatic * 100)),

        // raw string
        Text(context.sonnet.tisRaw),
        Text(context.sonnet.tisRaw),
        Text(context.sonnet.tisRaw2),

        // raw string repeated in interpolation
        Text(context.sonnet.rawRawRaw(context.sonnet.tisRaw, context.sonnet.tisRaw, context.sonnet.tisRaw2)),
        Text(context.sonnet.rawRawRaw(context.sonnet.tisRaw, context.sonnet.tisRaw, context.sonnet.tisRaw2)),

        // triple single quotes
        Text(context.sonnet.tripleSingleQuotes),
        Text(context.sonnet.tripleSingleQuotes),
        Text(context.sonnet.tripleSingleQuotes),

        // triple double quotes
        Text(context.sonnet.tripleDoubleQuotes),
        Text(context.sonnet.tripleDoubleQuotes),
        Text(context.sonnet.tripleDoubleQuotes),

        // multiline interpolation
        Text(
          context.sonnet.multilineStringInterpolatedstatic1(_interpolatedStatic),
        ),
        Text(
          context.sonnet.multilineStringInterpolatedstatic1(_interpolatedStatic),
        ),

        // inner interpolation
        Text(
          context.sonnet.interpolationInterpolation(context.sonnet.outerInnerInterpolation(1 == 1 ? '${true == false ? 'foo' : 'bar'}' : 'inner')),
        ),
        Text(
          context.sonnet.interpolationInterpolation(context.sonnet.outerInnerInterpolation(1 == 1 ? '${true == false ? 'foo' : 'bar'}' : 'inner')),
        ),

        // interpolation spanning multiple lines
        Text(
          context.sonnet.otherLastOfAll(context.sonnet.interpolated1Other((manyArgs(arg1: 'argument 1', arg2: 'argument.2', arg3: 'argument 1')).toString())),
          textAlign: TextAlign.center,
        ),
        Text(
          context.sonnet.otherLastOfAll(context.sonnet.interpolated1Other((manyArgs(arg1: 'argument 1', arg2: 'argument.2', arg3: 'argument 1')).toString())),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
