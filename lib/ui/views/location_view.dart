import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/database/database_service.dart';
import '../../data/models/monthly_rainfall_model.dart';
import '../../logic/services/postcode_service.dart';
import '../../logic/services/data_persist_service.dart';
import '/ui/views/tank_inventory_view.dart';
import '/ui/widgets/constrained_width_widget.dart';

class LocationView extends StatefulWidget {
  /// [LocationView] allows the user to select their location via postcode and
  /// look at historical rainfall data for that location
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  // Button state for press animation
  bool isPressed = false;
  // Default to current year
  double yearSelected = DateTime.now().year.toDouble();
  // Default to "Monthly" for chart display
  String timePeriod = "Monthly";
  // Postcode selection to choose location
  String? selectedPostcode;

  late final TextEditingController postcodeController;

  // Chart data
  List<MonthlyRainfall>? monthlyRainfallData;
  double? annualRainfall;
  bool isLoadingChart = false;
  String? chartError;

  // Instant access to hardcoded postcodes
  List<String> availablePostcodes = PostcodesService.getAvailablePostcodes();

  // Services
  final DataPersistService _dataPersistService = DataPersistService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    postcodeController = TextEditingController();
    _loadSavedData();
  }

  // Load saved location data
  Future<void> _loadSavedData() async {
    try {
      final locationData = await _dataPersistService.loadLocationData();

      setState(() {
        selectedPostcode = locationData['postcode'];
        yearSelected = locationData['year'];
        timePeriod = locationData['timePeriod'];
      });

      // Load chart data if postcode is selected
      if (selectedPostcode != null) {
        _loadChartData();
      }
    } catch (e) {
      setState(() {
        selectedPostcode = null;
        yearSelected = DateTime.now().year.toDouble();
        timePeriod = "Monthly";
      });
    }
  }

  // Load chart data using DatabaseService - no more duplication!
  Future<void> _loadChartData() async {
    if (selectedPostcode == null) return;

    // Limit years to 1975-current
    final constrainedYear = yearSelected.toInt().clamp(
      1975,
      DateTime.now().year,
    );

    setState(() {
      isLoadingChart = true;
      chartError = null;
    });

    try {
      // Use DatabaseService instead of direct API call
      final rainfallData = await _databaseService.getRainfallData(
        postcode: selectedPostcode!,
        year: constrainedYear,
        includeMonthly: timePeriod == "Monthly",
        includeAnnual: timePeriod == "Annual",
        useCache: true,
      );

      setState(() {
        if (timePeriod == "Monthly") {
          monthlyRainfallData = rainfallData['monthlyData'];
          annualRainfall = null;
        } else {
          annualRainfall = rainfallData['annualTotal'];
          monthlyRainfallData = null;
        }
        isLoadingChart = false;
      });
      print("Success!");
    } catch (e) {
      setState(() {
        chartError = 'Failed to load rainfall data: ${e.toString()}';
        isLoadingChart = false;
      });
      throw "Could not retrieve data for $selectedPostcode!";
    }
  }

  // Save location data
  Future<void> _saveData() async {
    try {
      await _dataPersistService.saveLocationData(
        postcode: selectedPostcode,
        year: yearSelected,
        timePeriod: timePeriod,
      );
    } catch (e) {
      _showAlertDialog('Failed to save location data: ${e.toString()}');
    }
  }

  // Show alert dialog
  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: kBorderRadius,
          side: kBorderSide,
        ),
        title: Text(message, style: subHeadingStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK", style: TextStyle(color: black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Width of screen
    final mediaWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: buildAppBar(context, 1),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: kPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 32,
              children: [
                ConstrainedWidthWidget(
                  child: Text("Location", style: headingStyle),
                ),
                ConstrainedWidthWidget(
                  child: Text(
                    "The functionality of this application is available only to "
                    "Adelaide (South Australia) and surrounding area.",
                    style: subHeadingStyle,
                  ),
                ),
                ConstrainedWidthWidget(
                  child: Text("Enter your location:", style: inputFieldStyle),
                ),

                // Postcode dropdown
                Tooltip(
                  message: "Enter your postcode.",
                  child: ConstrainedWidthWidget(
                    child: DropdownMenu<String>(
                      width: mediaWidth * 0.8,
                      initialSelection: selectedPostcode,
                      requestFocusOnTap:
                          true, // allow typing on mobile for filter
                      dropdownMenuEntries:
                          // All postcodes
                          availablePostcodes
                              .map(
                                (postcode) => DropdownMenuEntry<String>(
                                  label: postcode.toString(),
                                  value: postcode.toString(),
                                ),
                              )
                              .toList(),
                      label: Text("Postcode"),

                      menuStyle: MenuStyle(
                        maximumSize: WidgetStateProperty.all(Size(500, 300)),
                        backgroundColor: WidgetStateProperty.all(white),
                        elevation: WidgetStateProperty.all(8),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: kBorderRadius,
                            side: kBorderSide,
                          ),
                        ),
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        filled: true,
                        fillColor: white,
                        labelStyle: inputFieldStyle,
                        floatingLabelBehavior: FloatingLabelBehavior
                            .never, // Removed floating label
                      ),
                      textStyle: inputFieldStyle,
                      enableFilter: true,
                      hintText:
                          "Select postcode (${PostcodesService.length} available)",
                      controller: postcodeController,
                      onSelected: (postcode) {
                        // validate postcode
                        if (!PostcodesService.isValidPostcode(
                          postcodeController.text,
                        )) {
                          // if numerical and 4 digit
                          if (postcodeController.text.length == 4 &&
                              int.tryParse(postcodeController.text) != null) {
                            _showAlertDialog(
                              "Sorry, your area is outside of the supported area for this application.",
                            );
                          } else {
                            _showAlertDialog("Please enter a valid postcode");
                          }

                          postcodeController.clear();
                        }
                        setState(() {
                          selectedPostcode = postcode;
                        });
                        // Save data
                        _saveData();
                        try {
                          // Load data after postcode is selected
                          _loadChartData();
                        } catch (e) {
                          _showAlertDialog(
                            "Failed to load rainfall data: ${e.toString()}",
                          );
                        }
                      },
                    ),
                  ),
                ),

                // // Show loading/error states for debugging
                // if (isLoadingChart)
                //   Container(
                //     padding: EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color: Colors.blue.shade50,
                //       border: Border.all(color: Colors.blue, width: 2),
                //       borderRadius: kBorderRadius,
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         SizedBox(
                //           width: 20,
                //           height: 20,
                //           child: CircularProgressIndicator(
                //             strokeWidth: 2,
                //             color: Colors.blue,
                //           ),
                //         ),
                //         SizedBox(width: 12),
                //         Text(
                //           "Loading rainfall data...",
                //           style: TextStyle(color: Colors.blue.shade800),
                //         ),
                //       ],
                //     ),
                //   ),

                // if (chartError != null)
                //   Container(
                //     padding: EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color: Colors.red.shade50,
                //       border: Border.all(color: Colors.red, width: 2),
                //       borderRadius: kBorderRadius,
                //     ),
                //     child: Column(
                //       children: [
                //         Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             Icon(Icons.error, color: Colors.red),
                //             SizedBox(width: 8),
                //             Expanded(
                //               child: Text(
                //                 chartError!,
                //                 style: TextStyle(color: Colors.red.shade800),
                //               ),
                //             ),
                //           ],
                //         ),
                //         SizedBox(height: 8),
                //         ElevatedButton(
                //           onPressed: _loadChartData,
                //           style: ElevatedButton.styleFrom(
                //             backgroundColor: Colors.red,
                //             foregroundColor: white,
                //           ),
                //           child: Text("Retry"),
                //         ),
                //       ],
                //     ),
                //   ),

                // // Show data summary if loaded successfully
                // if (!isLoadingChart &&
                //     chartError == null &&
                //     selectedPostcode != null)
                //   Container(
                //     padding: EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color: Colors.green.shade50,
                //       border: Border.all(color: Colors.green, width: 2),
                //       borderRadius: kBorderRadius,
                //     ),
                //     child: Column(
                //       children: [
                //         Text(
                //           "Data loaded for $selectedPostcode",
                //           style: TextStyle(
                //             color: Colors.green.shade800,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         SizedBox(height: 8),
                //         if (timePeriod == "Monthly" &&
                //             monthlyRainfallData != null)
                //           Text(
                //             "Monthly data: ${monthlyRainfallData!.map((m) => m.totalRainfall).reduce((a, b) => a + b).toStringAsFixed(1)}mm total",
                //             style: TextStyle(color: Colors.green.shade700),
                //           ),
                //         if (timePeriod == "Annual" && annualRainfall != null)
                //           Text(
                //             "Annual rainfall: ${annualRainfall!.toStringAsFixed(1)}mm",
                //             style: TextStyle(color: Colors.green.shade700),
                //           ),
                //       ],
                //     ),
                //   ),

                // Continue button
                Tooltip(
                  message: "Continue to next step",
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: InkWell(
                      borderRadius: kBorderRadius,
                      onTap: () {
                        setState(() {
                          isPressed = true;
                        });
                        Future.delayed(const Duration(milliseconds: 150)).then((
                          value,
                        ) {
                          setState(() {
                            isPressed = false;
                          });
                        });

                        if (!PostcodesService.isValidPostcode(
                          postcodeController.text,
                        )) {
                          // if numerical and 4 digit
                          if (postcodeController.text.length == 4 &&
                              int.tryParse(postcodeController.text) != null) {
                            _showAlertDialog(
                              "Sorry, your area is outside of the supported area for this application.",
                            );
                            postcodeController.clear();
                            return;
                          } else {
                            _showAlertDialog("Please enter a valid postcode");
                            postcodeController.clear();
                            return;
                          }
                        }

                        _saveData(); // save

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TankInventoryView(),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        width: mediaWidth * 0.8,
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: white,
                          border: Border.all(color: black, width: 3),
                          borderRadius: kBorderRadius,
                          boxShadow: [isPressed ? BoxShadow() : kShadow],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text("Continue", style: subHeadingStyle),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
