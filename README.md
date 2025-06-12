# AquaBalance

A water tank management tool.

Calculate how many days you have remaining of water inventory in your tanks based on current inventory, rainfall, and usage.

Visualise how differing water usage would affect how long your inventory lasts.

## Supported Platforms

- [Web](https://aquabalance-tool.web.app/)

## File Structure

- The Dart code for this application lies within the lib folder
- Under here you will find the config, data, logic, and UI folders, along with the main.dart file, which is the entry point of the application
- The config folder contains constant variables to be used throughout the application
- The data folder contains the logic used to access the API, and model classes for custom objects used throughout the application
- The logic folder contains files on services around data persistence as well as files with the calculations used throughout the application to process inputs
- The UI (user interface) folder contains files for each screen displayed in the app and for custom widgets reused throughout the code

## Dependencies

AquaBalance was build using Flutter 3.32.0 (stable) and Dart 3.8.0 (stable) with a Firebase backend through VS Code.

External packages:
- google_fonts: ^6.2.1
- flutter_native_splash: ^2.4.6
- flutter_launcher_icons: ^0.14.3
- firebase_core: ^3.13.1
- shared_preferences: ^2.5.3
- http: ^1.4.0
- fl_chart: ^1.0.0
- intl: ^0.20.2
- firebase_ai: ^2.0.0
- url_launcher: ^6.3.1