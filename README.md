# Sonnet

## Quick Start

1. Add the package to your project:

    `pubspec.yaml`:
    
    ```yaml
    dependencies:
      sonnet:
    ```

2. (Optional) Add Linter to your project:

    `pubspec.yaml`:
    
    ```yaml
    dev_dependencies:
      custom_lint:
      sonnet_linter:
    ```
    
    `analysis_options.yaml`:
    
    ```yaml
    analyzer:
      plugins:
        - custom_lint
    ```
3. (Optional) migrate your code
    
    - add the migrator to your project
        
        `pubpsec.yaml`:

        ```yaml
        dev_dependencies:
          sonnet_migrator:
        ```
    - install the global package at the root of your project
        
        ```shell
        flutter pub global activate sonnet_migrator
        ```

    - run the migration
        
        ```shell
        flutter pub global run sonnet_migrator --auto
        ```
