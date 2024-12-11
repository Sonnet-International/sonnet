// ignore_for_file: unnecessary_brace_in_string_interps, prefer_const_constructors, unnecessary_string_interpolations, unnecessary_statements, prefer_const_declarations, always_declare_return_types, use_raw_strings, depend_on_referenced_packages, lines_longer_than_80_chars, type_annotate_public_apis, unnecessary_parenthesis, prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, prefer_single_quotes, inference_failure_on_function_return_type

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

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
    const [Text('away')];

    // constructors that should be skipped
    Logger('logger').log(Level.INFO, 'log message');
    RouteSettings(name: 'a route');
    RangeError('error message');
    Exception('exception message');
    Uri.parse('http://example.com');
    RegExp('a regex');
    Image.asset('foo');

    final someLocalString = 'some local string';
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

        Text(r'^+ [regexp]+$'),
        Text(r'^+ [regexp]+$'),

        Text('true as ${'true'} could be'),
        Text('true as ${'true'} could be'),

        Text('nullable string: $nullableString'),
        Text('nullable string: $nullableString'),

        Text('nullable string wrapped: ${nullableString}'),
        Text('nullable string wrapped: ${nullableString}'),

        Text('nullable string plus other: ${nullableString ?? 'other'}'),
        Text('nullable string plus other: ${nullableString ?? 'other'}'),

        Text(someLocalString),
        Text(someLocalString),

        Text(stringGetter),
        Text(stringGetter),

        Text(stringFunction()),
        Text(stringFunction()),

        // TODO: already camel-cased should stay camel-cased
        Text('${someLocalString}'),
        Text('${someLocalString}'),

        Text('${stringGetter}'),
        Text('${stringGetter}'),

        Text('${stringFunction()}'),
        Text('${stringFunction()}'),

        Text('interpolated $argStatic ${argStatic + argStatic} 1'),
        Text('interpolated $argStatic ${argStatic + argStatic} 1'),

        Text('interpolated $argStatic ${argStatic + argStatic + argStatic} 1'),
        Text('interpolated $argStatic ${argStatic + argStatic + argStatic} 1'),

        Text('interpolated $argStatic $argStatic 1'),
        Text('interpolated $argStatic $argStatic 1'),

        // slightly different localization
        Text('interpolated $argStatic 1'),
        Text('interpolated $argStatic 1'),

        // parameter has different type than before
        Text('interpolated $multipleStatic 1'),
        Text('interpolated $multipleStatic 1'),

        // very long string
        Text(
          'a string that is definitely too long to be used as a key in the arb file and in the dart code',
        ),
        Text(
          'a string that is definitely too long to be used as a key in the arb file and in the dart code',
        ),

        // reserved word
        Text('continue'),
        Text('continue'),

        // repeated word new casing
        Text('CONTINUE'),
        Text('CONTINUE'),

        // should remove const from lists
        ...(const [Text('foo')]),
        ...(const [Text('foo')]),

        // should convert enum to string
        Text('${_InternalEnum.somEnum}'),
        Text('${_InternalEnum.somEnum}'),

        // repeated word with characters
        Text('continue!'),
        Text('continue!'),

        // const keyword
        const Text('foo'),
        const Text('foo'),

        // adding strings with +
        Text('1' + '2' + '${3} 4'),
        Text('1' + '2' + '${3} 4'),

        // interpolation
        Text('interpolated $argStatic ${argStatic + 2} 1'),
        Text('interpolated $argStatic ${argStatic + 2} 1'),

        // repeated interpolation
        Text('interpolated ${argStatic} ${argStatic * 100} 1'),
        Text('interpolated ${argStatic} ${argStatic * 100} 1'),

        // raw string
        Text(r'tis $ raw'),
        Text(r'tis $ raw'),
        Text('tis \$ raw'),

        // raw string repeated in interpolation
        Text('${r'tis $ raw'} ${r'tis $ raw'} ${'tis \$ raw'}'),
        Text('${r'tis $ raw'} ${r'tis $ raw'} ${'tis \$ raw'}'),

        // triple single quotes
        Text('''triple single-quotes'''),
        Text('''triple single-quotes'''),
        Text('triple single-quotes'),

        // triple double quotes
        Text("""triple double-quotes"""),
        Text("""triple double-quotes"""),
        Text("triple double-quotes"),

        // multiline interpolation
        Text(
          '''
        Multiline String
        $_interpolatedStatic
        
        1. 
        ''',
        ),
        Text(
          '''
        Multiline String
        $_interpolatedStatic
        
        1. 
        ''',
        ),

        // inner interpolation
        Text(
          '${'outer ${1 == 1 ? '${true == false ? 'foo' : 'bar'}' : 'inner'} interpolation'} interpolation',
        ),
        Text(
          '${'outer ${1 == 1 ? '${true == false ? 'foo' : 'bar'}' : 'inner'} interpolation'} interpolation',
        ),

        // interpolation spanning multiple lines
        Text(
          '${'interpolated ${manyArgs(
            arg1: 'argument 1',
            arg2: 'argument.2',
            arg3: 'argument 1',
          )} other'} last of all',
          textAlign: TextAlign.center,
        ),
        Text(
          '${'interpolated ${manyArgs(
            arg1: 'argument 1',
            arg2: 'argument.2',
            arg3: 'argument 1',
          )} other'} last of all',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
