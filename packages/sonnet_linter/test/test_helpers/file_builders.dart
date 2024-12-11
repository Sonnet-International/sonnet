String widgetBuilder(
  String content, {
  List<String> imports = const [],
  String innerBuildSetup = '',
  String classSetup = '',
  String outOfClassSetup = '',
}) {
  return '''
import 'package:flutter/material.dart';
${imports.join('\n')}

$outOfClassSetup;

class Linted extends StatelessWidget {
  $classSetup

  @override
  Widget build(BuildContext context) {
    $innerBuildSetup
    return $content;
  }
}
      ''';
}

String textBuilder(String text, [String quote = '"']) {
  return 'Text($quote$text$quote)';
}

String widgetTextBuilder(
  String text, {
  List<String> imports = const [],
  String innerBuildSetup = '',
  String classSetup = '',
  String outOfClassSetup = '',
}) {
  return widgetBuilder(
    textBuilder(text),
    imports: imports,
    innerBuildSetup: innerBuildSetup,
    classSetup: classSetup,
    outOfClassSetup: outOfClassSetup,
  );
}

String widgetFunctionBuilder(
  String content, {
  List<String> imports = const [],
  String innerBuildSetup = '',
  String classSetup = '',
  String outOfClassSetup = '',
}) {
  return widgetBuilder(
    '''
ElevatedButton(
  onPressed: () {
    $content;
  },
  child: Container(),
)
  ''',
    imports: imports,
    innerBuildSetup: innerBuildSetup,
    classSetup: classSetup,
    outOfClassSetup: outOfClassSetup,
  );
}

String widgetListBuilder(
  List<String> contents, {
  List<String> imports = const [],
  String innerBuildSetup = '',
  String classSetup = '',
  String outOfClassSetup = '',
}) {
  return widgetBuilder(
    '''
Column(
  children: [
    ${contents.join(',\n    ')}
  ],
)
  ''',
    imports: imports,
    innerBuildSetup: innerBuildSetup,
    classSetup: classSetup,
    outOfClassSetup: outOfClassSetup,
  );
}
