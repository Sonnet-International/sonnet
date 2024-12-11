import 'dart:developer';

import 'package:flutter/material.dart';
import 'l10n/sonnet_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get public key from https://dashboard.sonnet.international
  Sonnet.init(
    publicKey: 'eylWanFg5GcNTz2LQ3SOm',
    onError: (e, s) {
      log('ERROR loading sonnet: $e\n$s');
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sonnet(
      builder: (locale) {
        return MaterialApp(
          title: context.sonnet.sonnetDemo,
          localizationsDelegates: SonnetLocalizations.localizationsDelegates,
          supportedLocales: SonnetLocalizations.supportedLocales,
          locale: locale,
          home: const MyHomePage(),
        );
      }
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(context.sonnet.helloWorld),
            Builder(builder: (context) {
              return Container();
            }),
            Text(
              _counter.toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () => Sonnet.changeLocale('pt'),
              child: Text(context.sonnet.changeLocale),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: context.sonnet.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
