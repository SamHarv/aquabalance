import 'package:flutter/material.dart';

import '/ui/views/water_usage_view.dart';
import '/ui/widgets/input_field_widget.dart';
import '/config/constants.dart';
import '../../logic/services/data_persist_service.dart';
import '../widgets/constrained_width_widget.dart';

class RoofCatchmentView extends StatefulWidget {
  /// [RoofCatchmentView] to take roof catchment area and other intake
  const RoofCatchmentView({super.key});

  @override
  State<RoofCatchmentView> createState() => _RoofCatchmentViewState();
}

class _RoofCatchmentViewState extends State<RoofCatchmentView> {
  // Button states for animation
  bool learnToMeasureIsPressed = false;
  bool continueButtonIsPressed = false;
  // Determine whether the user knows their roof catchment
  bool knowRoofCatchment = false;

  late final TextEditingController roofCatchmentController;
  late final TextEditingController otherIntakeController;

  // Data persist service
  final _dataPersistService = DataPersistService();

  // Loading state
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    roofCatchmentController = TextEditingController();
    otherIntakeController = TextEditingController();
    _loadSavedData();
  }

  // Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final roofCatchmentData =
          await _dataPersistService.loadRoofCatchmentData();

      setState(() {
        // Load boolean state
        knowRoofCatchment = roofCatchmentData['knowRoofCatchment'];

        // Load text field values
        final savedRoofCatchment = roofCatchmentData['roofCatchmentArea'];
        if (savedRoofCatchment.isNotEmpty) {
          roofCatchmentController.text = savedRoofCatchment;
        }

        final savedOtherIntake = roofCatchmentData['otherIntake'];
        if (savedOtherIntake.isNotEmpty) {
          otherIntakeController.text = savedOtherIntake;
        }

        isLoading = false;
      });

      // Add listeners for auto-save after loading data
      _addListeners();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      throw 'Error loading roof catchment data: $e';
    }
  }

  // Add listeners to controllers for auto-save
  void _addListeners() {
    roofCatchmentController.addListener(_saveData);
    otherIntakeController.addListener(_saveData);
  }

  // Remove listeners from controllers
  void _removeListeners() {
    roofCatchmentController.removeListener(_saveData);
    otherIntakeController.removeListener(_saveData);
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      await _dataPersistService.saveRoofCatchmentData(
        knowRoofCatchment: knowRoofCatchment,
        roofCatchmentArea: roofCatchmentController.text,
        otherIntake: otherIntakeController.text,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Validate inputs
  bool _validateInputs() {
    if (roofCatchmentController.text.isEmpty) {
      _showAlertDialog("Please enter the roof catchment area");
      return false;
    }

    final roofArea = double.tryParse(roofCatchmentController.text);
    if (roofArea == null || roofArea <= 0) {
      _showAlertDialog(
        "Please enter a valid roof catchment area (greater than 0)",
      );
      return false;
    }

    // Other intake is optional, but if provided, should be valid
    if (otherIntakeController.text.isNotEmpty) {
      final otherIntake = double.tryParse(otherIntakeController.text);
      if (otherIntake == null || otherIntake < 0) {
        _showAlertDialog(
          "Please enter a valid other intake value (0 or greater)",
        );
        return false;
      }
    }

    return true;
  }

  // Show alert dialog
  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
  void dispose() {
    _removeListeners();
    roofCatchmentController.dispose();
    otherIntakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while data is being loaded
    if (isLoading) {
      return Scaffold(
        appBar: buildAppBar(context),
        body: Center(child: CircularProgressIndicator(color: white)),
      );
    }

    final mediaWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: buildAppBar(context),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: kPadding,
            child: Column(
              spacing: 32,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedWidthWidget(
                  child: Text(
                    "Roof Catchment & Other Intake",
                    style: headingStyle,
                  ),
                ),
                // Know catchment area?
                ConstrainedWidthWidget(
                  child: Text(
                    "Enter your roof catchment area plumbed into tanks:",
                    style: inputFieldStyle,
                  ),
                ),

                // Input catchment area m2
                ConstrainedWidthWidget(
                  child: InputFieldWidget(
                    label: "Catchment Area (m²)",
                    controller: roofCatchmentController,
                    onChanged: (value) {
                      // Validate inputs
                      if (roofCatchmentController.text.isNotEmpty) {
                        try {
                          double.parse(value);
                        } catch (e) {
                          _showAlertDialog(
                            "Please enter a valid numerical roof catchment area in m²",
                          );
                          roofCatchmentController.clear();
                          return;
                        }
                      }
                      setState(() {});
                      // Auto-save is handled by the listener
                    },
                  ),
                ),
                Tooltip(
                  message: "Learn to measure roof catchment area",
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: InkWell(
                      borderRadius: kBorderRadius,
                      onTap: () {
                        // Handle button press animation
                        setState(() {
                          learnToMeasureIsPressed = true;
                        });
                        Future.delayed(const Duration(milliseconds: 150)).then((
                          value,
                        ) {
                          setState(() {
                            learnToMeasureIsPressed = false;
                          });
                        });

                        // TODO: Add instructional video to measure roof catchment on Maps?

                        // Show information dialog
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: kBorderRadius,
                                  side: kBorderSide,
                                ),
                                title: Text(
                                  'How to Measure Roof Catchment Area',
                                  style: subHeadingStyle,
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '1. Measure the length and width of your roof in metres',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '2. Multiply length x width = area in m²',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '3. For complex roofs, break into rectangles and add areas together',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '4. Only include areas that drain into your tank system',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Example: 10m x 8m roof = 80m² catchment area',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text(
                                      "Got it!",
                                      style: TextStyle(color: black),
                                    ),
                                  ),
                                ],
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
                          boxShadow: [
                            learnToMeasureIsPressed ? BoxShadow() : kShadow,
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              "Learn how to measure",
                              style: subHeadingStyle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ConstrainedWidthWidget(
                  child: Text(
                    "Record any water intake from other sources such as bores "
                    "or community supply:",
                    style: inputFieldStyle,
                  ),
                ),
                ConstrainedWidthWidget(
                  child: InputFieldWidget(
                    label: "Other Intake (L/day)",
                    controller: otherIntakeController,
                    onChanged: (value) {
                      // Validate inputs
                      if (otherIntakeController.text.isNotEmpty) {
                        try {
                          double.parse(value);
                        } catch (e) {
                          _showAlertDialog(
                            "Please enter a valid numerical other intake in L/day",
                          );
                          otherIntakeController.clear();
                          return;
                        }
                      }
                      setState(() {});
                      // Auto-save is handled by the listener
                    },
                  ),
                ),
                Tooltip(
                  message: "Continue to next step",
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: InkWell(
                      borderRadius: kBorderRadius,
                      onTap: () {
                        // Validate inputs before continuing
                        if (!_validateInputs()) {
                          return;
                        }

                        // Handle button press animation
                        setState(() {
                          continueButtonIsPressed = true;
                        });
                        Future.delayed(const Duration(milliseconds: 150)).then((
                          value,
                        ) {
                          setState(() {
                            continueButtonIsPressed = false;
                          });
                        });

                        // Save data before navigating
                        _saveData();

                        // Navigate to water usage view
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WaterUsageView(),
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
                          boxShadow: [
                            continueButtonIsPressed ? BoxShadow() : kShadow,
                          ],
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
