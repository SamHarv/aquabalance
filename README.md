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