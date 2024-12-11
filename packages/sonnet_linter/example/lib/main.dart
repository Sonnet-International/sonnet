// ignore_for_file: unnecessary_brace_in_string_interps, prefer_interpolation_to_compose_strings, prefer_adjacent_string_concatenation, unnecessary_string_interpolations, prefer_single_quotes

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

  @override
  Widget build(BuildContext context) {
    // expect_lint: avoid_string_literals_inside_widget
    const [Text('away')];

    // constructors that should be skipped
    Logger('logger').log(Level.INFO, 'log message');
    RouteSettings(name: 'a route');
    RangeError('error message');
    Exception('exception message');
    Uri.parse('http://example.com');
    RegExp('a regex');
    Image.asset('foo');
    Sonnet.changeLocale('pt');

    // expect_lint: avoid_string_literals_inside_widget
    final someLocalString = 'some local string';
    return Scaffold(
      body: Column(
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
          ElevatedButton(
            onPressed: () => Exception('some exception'),
            child: Container(),
          ),
          Text('${someLocalString}'),
          Text('${stringGetter}'),
          Text('${stringFunction()}'),
          Text('${_InternalEnum.somEnum}'),
          Text('1' + '2' + '${3} 4'),

          // expect_lint: avoid_string_literals_inside_widget
          Text(r'^+ [regexp]+$'),

          // expect_lint: avoid_string_literals_inside_widget
          Text('true as ${'true'} could be'),

          // expect_lint: avoid_string_literals_inside_widget
          Text('interpolated $argStatic ${argStatic + argStatic} 1'),

          Text(
            // expect_lint: avoid_string_literals_inside_widget
            'a string that is definitely too long to be used as a key in the arb file and in the dart code',
          ),
          Text(
            // expect_lint: avoid_string_literals_inside_widget
            'a string that is definitely too long to be used as a key in the arb file and in the dart code',
          ),


          // expect_lint: avoid_string_literals_inside_widget
          const Text('foo'),

          // expect_lint: avoid_string_literals_inside_widget
          Text('interpolated $argStatic ${argStatic + 2} 1'),

          // expect_lint: avoid_string_literals_inside_widget
          Text(r'tis $ raw'),

          // expect_lint: avoid_string_literals_inside_widget
          Text('''triple single-quotes'''),

          // expect_lint: avoid_string_literals_inside_widget
          Text("""triple double-quotes"""),

          Text(
            // expect_lint: avoid_string_literals_inside_widget
            '''
          Multiline String
          $_interpolatedStatic
          
          1. 
          ''',
          ),

          Text(
            // expect_lint: avoid_string_literals_inside_widget
            '${'outer ${1 == 1 ? '${true == false ? 'foo' : 'bar'}' : 'inner'} interpolation'} interpolation',
          ),

          Text(
            // expect_lint: avoid_string_literals_inside_widget
            '${'interpolated ${manyArgs(
              // expect_lint: avoid_string_literals_inside_widget
              arg1: 'argument 1',
              // expect_lint: avoid_string_literals_inside_widget
              arg2: 'argument.2',
              // expect_lint: avoid_string_literals_inside_widget
              arg3: 'argument 1',
            )} other'} last of all',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
