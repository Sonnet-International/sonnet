## Sonnet

Internationalization in Flutter sucks. Sonnet an make it suck less.

## Quick Start

1. Add the package to your project:

    `pubspec.yaml`:
    
    ```yaml
    dependencies:
      sonnet:
    ```
   
2. Import the package, initialize and wrap your app in Sonnet:

    ```dart
    import 'package:sonnet/sonnet.dart';
   
    main() {
      // Get public key from https://dashboard.sonnet.international
      Sonnet.init(publicKey: '**************');
      
      runApp(
        Sonnet(
          builder: (locale) {
            return MaterialApp(
              title: 'Sonnet Demo',
              locale: locale,
              localizationsDelegates: Sonnet.localizationsDelegates,
              supportedLocales: Sonnet.supportedLocales,
              home: MyHomePage(),
            );
          },  
        ),
      );
    }
    ```
   
3. Generate your translations:

    ```shell
    flutter pub global activate sonnet # (first-time only)
    flutter pub global run sonnet:gen
    ```
   
## Change User Locale

Sonnet will automatically detect the user's locale and update the app accordingly. You can also manually change the locale:

```dart
Sonnet.instance.changeLocale('fr');
```
