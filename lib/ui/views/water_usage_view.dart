import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/logic/services/data_persist_service.dart';
import '/logic/services/url_launcher.dart';
import '/ui/widgets/constrained_width_widget.dart';
import '/ui/widgets/input_field_widget.dart';
import '/config/constants.dart';
import 'output_view.dart';

class WaterUsageView extends StatefulWidget {
  /// [WaterUsageView] to determine household water usage
  const WaterUsageView({super.key});

  @override
  State<WaterUsageView> createState() => _WaterUsageViewState();
}

class _WaterUsageViewState extends State<WaterUsageView> {
  // Data persist service
  final _dataPersistService = DataPersistService();

  late final TextEditingController numOfPeopleController;
  bool isPressed = false;
  int numOfPeople = 0;

  // List to store individual water usage for each person
  List<int> personWaterUsageList = [];

  // List to store manual input controllers for each person
  List<TextEditingController> manualInputControllers = [];

  // List to track which input method is being used for each person (true = manual, false = segmented)
  List<bool> isManualInputList = [];

  // Loading state
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    numOfPeopleController = TextEditingController();
    _loadSavedData();
  }

  // Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final waterUsageData = await _dataPersistService.loadWaterUsageData();

      final savedNumOfPeople = waterUsageData['numOfPeople'];
      final savedUsageList = waterUsageData['personWaterUsageList'];
      final savedManualInputList = waterUsageData['isManualInputList'];

      // Initialise all lists properly before setState
      _initialiseLists(savedNumOfPeople, savedUsageList, savedManualInputList);

      setState(() {
        numOfPeople = savedNumOfPeople;
        numOfPeopleController.text =
            numOfPeople > 0 ? numOfPeople.toString() : '';
        isLoading = false;
      });

      // Add listener for auto-save after loading data
      _addListener();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      throw 'Error loading water usage data: $e';
    }
  }

  // Initialise all lists with proper sizes and default values
  void _initialiseLists(
    int numPeople,
    List<int> savedUsageList,
    List<bool> savedManualInputList,
  ) {
    // Clear existing lists
    personWaterUsageList.clear();
    isManualInputList.clear();

    // Dispose existing controllers
    for (final controller in manualInputControllers) {
      controller.dispose();
    }
    manualInputControllers.clear();

    // Initialise lists with proper size
    for (int i = 0; i < numPeople; i++) {
      // Use saved usage or default to 200L
      final usage = i < savedUsageList.length ? savedUsageList[i] : 200;
      personWaterUsageList.add(usage);

      // Use saved manual input preference or default to false
      final isManual =
          i < savedManualInputList.length ? savedManualInputList[i] : false;
      isManualInputList.add(isManual);

      // Create controller and set initial value if manual input
      final controller = TextEditingController();
      if (isManual) {
        controller.text = usage.toString();
      }
      manualInputControllers.add(controller);
    }
  }

  // Adjust usage list size to match number of people
  void _adjustUsageListSize() {
    // Remove listeners first to avoid issues during adjustment
    _removeListener();

    while (personWaterUsageList.length < numOfPeople) {
      personWaterUsageList.add(200); // Default to average usage
      isManualInputList.add(false); // Default to segmented button
      manualInputControllers.add(TextEditingController());
    }

    if (personWaterUsageList.length > numOfPeople) {
      // Dispose excess controllers
      for (int i = numOfPeople; i < manualInputControllers.length; i++) {
        manualInputControllers[i].dispose();
      }

      personWaterUsageList = personWaterUsageList.sublist(0, numOfPeople);
      isManualInputList = isManualInputList.sublist(0, numOfPeople);
      manualInputControllers = manualInputControllers.sublist(0, numOfPeople);
    }

    // Update manual input controllers with current values
    for (int i = 0; i < manualInputControllers.length; i++) {
      if (i < isManualInputList.length && isManualInputList[i]) {
        manualInputControllers[i].text = personWaterUsageList[i].toString();
      }
    }

    // Re-add listeners after adjustment
    _addListener();
  }

  // Add listener to controller for auto-save
  void _addListener() {
    numOfPeopleController.addListener(_saveData);

    // Add listeners to manual input controllers
    for (int i = 0; i < manualInputControllers.length; i++) {
      manualInputControllers[i].addListener(() => _saveData());
    }
  }

  // Remove listener from controller
  void _removeListener() {
    numOfPeopleController.removeListener(_saveData);

    // Remove listeners from manual input controllers
    for (final controller in manualInputControllers) {
      controller.removeListener(_saveData);
    }
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      await _dataPersistService.saveWaterUsageData(
        numOfPeople: numOfPeople,
        personWaterUsageList: personWaterUsageList,
        isManualInputList: isManualInputList,
      );
    } catch (e) {
      throw 'Error saving water usage data: $e';
    }
  }

  // Update number of people and adjust usage list
  void _updateNumOfPeople(int newCount) {
    if (newCount < 0 || newCount > 20) return;

    setState(() {
      numOfPeople = newCount;
      _adjustUsageListSize();
    });

    _saveData(); // Save data when count changes
  }

  // Update individual person's water usage
  void _updatePersonUsage(int personIndex, int usage) {
    if (personIndex < personWaterUsageList.length) {
      setState(() {
        personWaterUsageList[personIndex] = usage;
      });
      _saveData(); // Save data when usage changes
    }
  }

  // Toggle between manual input and segmented button for a person
  void _toggleInputMethod(int personIndex) {
    if (personIndex >= isManualInputList.length ||
        personIndex >= manualInputControllers.length) {
      return; // Safety check
    }

    setState(() {
      isManualInputList[personIndex] = !isManualInputList[personIndex];

      if (isManualInputList[personIndex]) {
        // Switching to manual input - populate field with current value
        manualInputControllers[personIndex].text =
            personWaterUsageList[personIndex].toString();
      } else {
        // Switching to segmented button - ensure value is one of the preset options
        final currentValue = personWaterUsageList[personIndex];
        if (currentValue != 100 && currentValue != 200 && currentValue != 300) {
          // If current value isn't a preset, default to average
          personWaterUsageList[personIndex] = 200;
        }
      }
    });
    _saveData();
  }

  // Handle manual input change
  void _handleManualInputChange(int personIndex, String value) {
    try {
      if (value.isEmpty) {
        _updatePersonUsage(personIndex, 0);
        return;
      }

      final usage = int.parse(value);
      if (usage < 0 || usage > 1500) {
        showAlertDialog("Please enter a value between 0 and 1500 litres");
        return;
      }

      _updatePersonUsage(personIndex, usage);
    } catch (e) {
      if (value.isNotEmpty) {
        showAlertDialog("Please enter a valid number between 0 and 1500");
      }
    }
  }

  // Calculate total water usage
  int _calculateTotalUsage() {
    return personWaterUsageList.fold(0, (sum, usage) => sum + usage);
  }

  // Show alert dialog with message
  void showAlertDialog(String message) {
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close", style: TextStyle(color: black)),
              ),
            ],
          ),
    );
  }

  // Get usage level text for display
  String _getUsageLevelText(int usage) {
    switch (usage) {
      case 100:
        return "Low (100L)";
      case 200:
        return "Avg (200L)";
      case 300:
        return "High (300L)";
      default:
        return "Custom (${usage}L)";
    }
  }

  @override
  void dispose() {
    _removeListener();
    numOfPeopleController.dispose();

    // Dispose all manual input controllers
    for (final controller in manualInputControllers) {
      controller.dispose();
    }

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
                  child: Text("Water Usage", style: headingStyle),
                ),
                ConstrainedWidthWidget(
                  child: Text(
                    "How many people live in your household?",
                    style: inputFieldStyle,
                  ),
                ),
                ConstrainedWidthWidget(
                  child: InputFieldWidget(
                    controller: numOfPeopleController,
                    label: "Number of people (1-20)",
                    onChanged: (number) {
                      // Ensure number within range
                      try {
                        if (number.isNotEmpty) {
                          final n = int.parse(number);
                          if (n < 1 || n > 20) {
                            if (number.isNotEmpty) {
                              showAlertDialog(
                                "Please enter a number of people between 1 and 20",
                              );
                            }
                            return;
                          }
                          _updateNumOfPeople(n);
                        }
                      } catch (e) {
                        if (number.isNotEmpty) {
                          showAlertDialog(
                            "Please enter a valid number of people between 1 and 20",
                          );
                        }
                      }
                    },
                  ),
                ),

                // Generate individual usage selectors for each person
                if (numOfPeople > 0) ...[
                  ConstrainedWidthWidget(
                    child: Text(
                      "Select water usage level for each person:",
                      style: inputFieldStyle,
                    ),
                  ),

                  for (int i = 0; i < numOfPeople; i++)
                    // Add safety check to ensure index is valid
                    if (i < personWaterUsageList.length &&
                        i < isManualInputList.length &&
                        i < manualInputControllers.length)
                      ConstrainedWidthWidget(
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: kBorderRadius,
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          color: white,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Person ${i + 1}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: black,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _toggleInputMethod(i),
                                      child: Text(
                                        isManualInputList[i]
                                            ? "Use Presets"
                                            : "Custom Input",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Current: ${_getUsageLevelText(personWaterUsageList[i])} per day",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 12),

                                // Show either manual input or segmented button based on user preference
                                if (isManualInputList[i]) ...[
                                  // Manual input field
                                  TextFormField(
                                    controller: manualInputControllers[i],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(
                                        4,
                                      ), // Max 1500
                                    ],
                                    decoration: InputDecoration(
                                      labelText:
                                          "Daily usage in litres (0-1500)",
                                      border: OutlineInputBorder(
                                        borderRadius: kBorderRadius,
                                      ),
                                      suffixText: "L",
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onChanged:
                                        (value) =>
                                            _handleManualInputChange(i, value),
                                  ),
                                ] else ...[
                                  // Segmented button for preset values
                                  SegmentedButton<int>(
                                    style: segButtonStyle,
                                    segments: [
                                      ButtonSegment(
                                        value: 100,
                                        label: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Text("Low"),
                                              Text(
                                                "100L",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: 200,
                                        label: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Text("Avg"),
                                              Text(
                                                "200L",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: 300,
                                        label: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Text("High"),
                                              Text(
                                                "300L",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    selected: {
                                      // Only show selection if current value matches a preset
                                      if ([
                                        100,
                                        200,
                                        300,
                                      ].contains(personWaterUsageList[i]))
                                        personWaterUsageList[i],
                                    },
                                    onSelectionChanged: (value) {
                                      _updatePersonUsage(i, value.first);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                  // Show total usage summary
                  ConstrainedWidthWidget(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                        borderRadius: kBorderRadius,
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Household Total",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "${_calculateTotalUsage()} litres per day",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Link to website for more accurate estimates
                // ConstrainedWidthWidget(
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Text(
                //         "For more accurate estimates:",
                //         style: TextStyle(
                //           fontSize: 16,
                //           color: Colors.grey.shade600,
                //           fontStyle: FontStyle.italic,
                //         ),
                //         textAlign: TextAlign.center,
                //       ),
                //       TextButton(
                //         child: Text("click here"),
                //         onPressed:
                //             () async =>
                //                 await UrlLauncher.launchWaterUsageTool(),
                //       ),
                //     ],
                //   ),
                // ),

                // Button to continue
                if (numOfPeople > 0)
                  Tooltip(
                    message: "Continue to results",
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: InkWell(
                        borderRadius: kBorderRadius,
                        onTap: () {
                          // Handle button press animation
                          setState(() {
                            isPressed = true;
                          });
                          Future.delayed(
                            const Duration(milliseconds: 150),
                          ).then((value) {
                            setState(() {
                              isPressed = false;
                            });
                          });

                          final totalWaterUsage = _calculateTotalUsage();

                          // Show dialog with results that enables nav to output page
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: kBorderRadius,
                                    side: kBorderSide,
                                  ),
                                  title: Text(
                                    'Water Usage Results',
                                    style: subHeadingStyle,
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Household Summary:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: black,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        for (int i = 0; i < numOfPeople; i++)
                                          if (i < personWaterUsageList.length)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2,
                                                  ),
                                              child: Text(
                                                "Person ${i + 1}: ${personWaterUsageList[i]}L/day",
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                        Divider(),
                                        Text(
                                          "Total: $totalWaterUsage litres per day",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
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
                                        "Back",
                                        style: TextStyle(color: black),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();

                                        // Save data before navigating
                                        _saveData();

                                        // nav to output view
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OutputView(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Continue",
                                        style: TextStyle(
                                          color: black,
                                          fontWeight: FontWeight.bold,
                                        ),
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
