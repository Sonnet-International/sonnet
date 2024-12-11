import 'dart:io';

class ProcessRunner {
  static Future<void> genL10n() async {
    await Process.run('flutter', ['gen-l10n']);
  }
}
