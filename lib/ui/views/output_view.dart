import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '/logic/services/url_launcher.dart';
import '/logic/results_calculator.dart';
import '/ui/views/home_view.dart';
import '/ui/widgets/constrained_width_widget.dart';
import '/config/constants.dart';
import 'optimisation_tips_view.dart';

// TODO: Apply formatter.format() to this

class OutputView extends StatefulWidget {
  /// [OutputView] to display results of tool
  const OutputView({super.key});

  @override
  State<OutputView> createState() => _OutputViewState();
}

class _OutputViewState extends State<OutputView> {
  bool isPressed = false;
  bool optimisationIsPressed = false;

  // Results data
  int daysLeft = 0;
  int currentInventory = 0;
  double dailyUsage = 0;
  double dailyIntake = 0;
  double netDailyChange = 0;
  bool isIncreasing = false;
  String resultMessage = "";
  List<Map<String, dynamic>> projectedData = [];
  Map<String, dynamic> tankSummary = {};
  int annualRainfall = 0;

  // User inputs
  String selectedRainfall = "10-year median";
  double perPersonUsage = 200.0;

  // Loading state
  bool isLoading = true;
  String? errorMessage;

  String tipsGenerated = "";

  @override
  void initState() {
    super.initState();
    _calculateResults();
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

  // Calculate results
  Future<void> _calculateResults() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Calculate days remaining
      final results = await ResultsCalculator.calculateDaysRemaining(
        rainfallScenario: selectedRainfall,
        perPersonUsage: perPersonUsage,
      );

      // Get tank summary
      final summary = await ResultsCalculator.getTankSummary();

      setState(() {
        daysLeft = results['daysRemaining'] ?? 0;
        currentInventory = results['currentInventory'] ?? 0;
        dailyUsage = results['dailyUsage'] ?? 0;
        dailyIntake = results['dailyIntake'] ?? 0;
        netDailyChange = results['netDailyChange'] ?? 0;
        isIncreasing = results['isIncreasing'] ?? false;
        resultMessage = results['message'] ?? "";
        projectedData = results['projectedData'] ?? [];
        tankSummary = summary;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error calculating results: $e';
        isLoading = false;
      });
    }
  }

  // Build projection chart
  Widget _buildProjectionChart() {
    if (projectedData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "No projection data available",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Find max value for chart scaling
    final maxLevel = projectedData
        .map((d) => d['waterLevel'] as int)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxLevel > 0 ? maxLevel * 1.2 : 1000.0;

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(
                      color: black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: projectedData.length / 6,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < projectedData.length) {
                    return Text(
                      projectedData[index]['dateFormatted'], // 00 Mmm format
                      style: TextStyle(
                        color: black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: black, width: 2),
              left: BorderSide(color: black, width: 2),
            ),
          ),
          minX: 0,
          maxX: projectedData.length.toDouble() - 1,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: projectedData.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value['waterLevel'].toDouble(),
                );
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [blue, isIncreasing ? Colors.green : Colors.red],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    blue.withValues(alpha: 0.3),
                    (isIncreasing ? Colors.green : Colors.red).withValues(
                      alpha: 0.1,
                    ),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < projectedData.length) {
                    final data = projectedData[index];
                    final date = DateTime.parse(data['date']);
                    return LineTooltipItem(
                      '${date.day}/${date.month}\n${data['waterLevel']}L',
                      TextStyle(color: white, fontSize: 12),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // Build results cards
  Widget _buildResultsCards() {
    return Column(
      spacing: 16,
      children: [
        // Days remaining card
        ConstrainedWidthWidget(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: !isIncreasing ? Colors.red.shade50 : Colors.green.shade50,
              border: Border.all(
                color: !isIncreasing ? Colors.red : Colors.green,
                width: 3,
              ),
              borderRadius: kBorderRadius,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 40),
                    Icon(
                      daysLeft == -1
                          ? Icons.trending_up
                          : !isIncreasing
                          ? Icons.warning
                          : Icons.check_circle,
                      size: 40,
                      color: !isIncreasing ? Colors.red : Colors.green,
                    ),
                    IconButton(
                      icon: Icon(Icons.warning_amber_outlined, color: black),
                      tooltip: "Disclaimer",
                      onPressed: () => _showAlertDialog(
                        "This tool "
                        "uses calculations to estimate water "
                        "intake and usage, and may not reflect actual "
                        "measures. Results should not be relied "
                        "upon for critical decisions without "
                        "professional advice. Data entered into this app "
                        "will be stored on your device and kept private.",
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  daysLeft == -1
                      ? "Water Increasing!"
                      : "$daysLeft days remaining",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: !isIncreasing
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  resultMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: !isIncreasing
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Current status cards
        ConstrainedWidthWidget(
          child: Row(
            spacing: 16,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: white,
                    border: Border.all(color: black, width: 2),
                    borderRadius: kBorderRadius,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Current Inventory",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${formatter.format(currentInventory)}L",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: blue,
                        ),
                      ),
                      if (tankSummary['totalCapacity'] != null &&
                          tankSummary['totalCapacity'] > 0)
                        Text(
                          "${tankSummary['fillPercentage'].toStringAsFixed(1)}% full",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: white,
                    border: Border.all(color: black, width: 2),
                    borderRadius: kBorderRadius,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Daily Balance",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${netDailyChange >= 0 ? '+' : ''}${formatter.format(netDailyChange.toInt())}L",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: netDailyChange >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      Text(
                        "per day",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.sizeOf(context).width;

    // Loading screen
    if (isLoading) {
      return Scaffold(
        appBar: buildAppBar(context, 5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: white),
              SizedBox(height: 16),
              Text("Calculating results...", style: subHeadingStyle),
            ],
          ),
        ),
      );
    }

    // Error screen
    if (errorMessage != null) {
      return Scaffold(
        appBar: buildAppBar(context, 5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text("Error", style: headingStyle),
              SizedBox(height: 8),
              Text(errorMessage!, style: subHeadingStyle),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculateResults,
                child: Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: buildAppBar(context, 5),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: kPadding,
            child: Column(
              spacing: 32,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Results cards
                _buildResultsCards(),

                ConstrainedWidthWidget(
                  child: Column(
                    children: [
                      ConstrainedWidthWidget(
                        child: Text(
                          "Assumed Rainfall Scenario:",
                          style: inputFieldStyle,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Rainfall pattern dropdown
                      ConstrainedWidthWidget(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 16,
                          children: [
                            Expanded(
                              child: Tooltip(
                                message:
                                    "Select assumed rainfall pattern for projections",
                                child: DropdownMenu<String>(
                                  width: double.infinity,
                                  //mediaWidth * 0.8,
                                  initialSelection: selectedRainfall,
                                  dropdownMenuEntries: [
                                    DropdownMenuEntry(
                                      value: "No Rainfall",
                                      label: "No Rainfall",
                                    ),
                                    DropdownMenuEntry(
                                      value: "Lowest recorded",
                                      label: "Lowest recorded (10 yr)",
                                    ),
                                    DropdownMenuEntry(
                                      value: "10-year median",
                                      label: "10-year median",
                                    ),
                                    DropdownMenuEntry(
                                      value: "Highest recorded",
                                      label: "Highest recorded (10 yr)",
                                    ),
                                  ],
                                  label: Text(
                                    "Rainfall Pattern",
                                    style: inputFieldStyle,
                                  ),
                                  menuStyle: MenuStyle(
                                    maximumSize: WidgetStateProperty.all(
                                      Size.fromWidth(500),
                                    ),
                                    backgroundColor: WidgetStateProperty.all(
                                      white,
                                    ),
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
                                  hintText: "Select rainfall scenario",
                                  onSelected: (rainfall) {
                                    if (rainfall != null) {
                                      setState(() {
                                        selectedRainfall = rainfall;
                                      });
                                      _calculateResults(); // Recalculate with new scenario
                                    }
                                  },
                                ),
                              ),
                            ),
                            // Question mark icon to launch dialog to explain patterns
                            IconButton(
                              icon: Icon(Icons.help, color: white),
                              tooltip: "Learn more about rainfall patterns",
                              onPressed: () => _showAlertDialog(
                                "Assumed rainfall scenario is the assumption made about "
                                "rainfall in your area based on data from the "
                                "last 10 years for each given month.\n\n"
                                "The greater the rainfall, the greater your "
                                "water intake.",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Chart to visualise tank levels
                ConstrainedWidthWidget(
                  child: Container(
                    decoration: BoxDecoration(
                      color: white,
                      border: Border.all(color: black, width: 3),
                      borderRadius: kBorderRadius,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        spacing: 16,
                        children: [
                          Text(
                            "Water Level Projection",
                            style: subHeadingStyle,
                          ),
                          Text(
                            "Based on current usage and selected rainfall pattern",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),

                          _buildProjectionChart(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Per person water usage slider
                // Column(
                //   spacing: 16,
                //   children: [
                //     ConstrainedWidthWidget(
                //       child: Text(
                //         "Adjust household water usage:",
                //         style: inputFieldStyle,
                //       ),
                //     ),
                //     ConstrainedWidthWidget(
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: [
                //           Text(
                //             "${formatter.format(dailyUsage)}L/day",
                //             style: TextStyle(
                //               fontSize: 18,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //           SizedBox(width: 8),
                //           Expanded(
                //             child: Slider(
                //               value: dailyUsage,
                //               activeColor: black,
                //               secondaryActiveColor: white,
                //               thumbColor: white,
                //               min: 50,
                //               max: 3000, // TODO: 2000?
                //               divisions: 45,
                //               onChanged: (value) {
                //                 setState(() {
                //                   dailyUsage = value;
                //                 });
                //               },
                //               onChangeEnd: (value) {
                //                 setState(() {
                //                   // TODO: Update chart
                //                   // _calculateResults(); // Recalculate when slider stops
                //                 });
                //               },
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),

                // Daily intake/usage breakdown
                ConstrainedWidthWidget(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: black, width: 2),
                      borderRadius: kBorderRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Daily Water Balance", style: subHeadingStyle),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Water intake:",
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "+${formatter.format(dailyIntake)}L",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Water usage:",
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "-${formatter.format(dailyUsage)}L",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Change in inventory:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${netDailyChange >= 0 ? '+' : ''}${formatter.format(netDailyChange)}L",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: netDailyChange >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Water optimisation tips
                ConstrainedWidthWidget(
                  child: Row(
                    spacing: 16,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.local_library_outlined,
                        color: white,
                        size: 60,
                      ),
                      Expanded(
                        child: Tooltip(
                          message: "Water optimisation tips",
                          child: InkWell(
                            borderRadius: kBorderRadius,
                            onTap: () {
                              setState(() {
                                optimisationIsPressed = true;
                              });
                              Future.delayed(
                                const Duration(milliseconds: 150),
                              ).then((value) async {
                                setState(() {
                                  optimisationIsPressed = false;
                                });

                                // nav to optimisation tips view
                                await Navigator.push(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OptimisationTipsView(),
                                  ),
                                );

                                // Generate content based on prompt
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              decoration: BoxDecoration(
                                color: white,
                                border: Border.all(color: black, width: 3),
                                borderRadius: kBorderRadius,
                                boxShadow: [
                                  optimisationIsPressed ? BoxShadow() : kShadow,
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    "Optimisation Tips",
                                    style: subHeadingStyle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Start again button
                Tooltip(
                  message: "Return to home page and start again",
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
                          Navigator.pushAndRemoveUntil(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(builder: (context) => HomeView()),
                            (route) => false,
                          );
                        });
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
                            child: Text("Start Again", style: subHeadingStyle),
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
