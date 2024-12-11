import 'dart:io';

class ProcessRunner {
  static Future<void> genL10n() async {
    await Process.run('flutter', const ['pub', 'global', 'run', 'sonnet:gen']);
  }
}
