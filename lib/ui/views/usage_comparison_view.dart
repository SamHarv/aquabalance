import 'package:aquabalance/ui/views/water_usage_view.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '/logic/results_calculator.dart';
import '/ui/views/home_view.dart';
import '/ui/widgets/constrained_width_widget.dart';
import '/config/constants.dart';
import 'optimisation_tips_view.dart';

class UsageComparisonView extends StatefulWidget {
  /// [UsageComparisonView] to model different water usage scenarios
  const UsageComparisonView({super.key});

  @override
  State<UsageComparisonView> createState() => _UsageComparisonViewState();
}

class _UsageComparisonViewState extends State<UsageComparisonView> {
  bool isPressed = false;
  bool optimisationIsPressed = false;
  bool usageIsPressed = false;

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

  double comparisonUsage = 0;

  // User inputs
  String selectedRainfall = "10-year median";

  // Loading state
  bool isLoading = true;
  String? errorMessage;

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
              Text("Preparing comparison...", style: subHeadingStyle),
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
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leadingWidth: 144,
        leading: IconButton(
          icon: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 32, 12),
            child: Row(
              spacing: 8,
              children: [
                Icon(Icons.arrow_back_ios_new),
                Text(
                  "Back",
                  style: GoogleFonts.openSans(
                    textStyle: const TextStyle(
                      color: white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          color: white,
          onPressed: () => Navigator.pop(context), // Back to prev view
        ),
        actions: [
          Hero(
            tag: "logo",
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 12, 48, 12),
              child: Image.asset(logo),
            ),
          ),
        ],
      ),
      body: // Water optimisation tips
      Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              spacing: 32,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedWidthWidget(
                  child: Text("Usage Comparison", style: headingStyle),
                ),
                ConstrainedWidthWidget(
                  child: Text(
                    "Understand how changes in your usage affect your days of "
                    "remaining inventory",
                    style: subHeadingStyle,
                  ),
                ),
                ConstrainedWidthWidget(
                  child: Column(
                    children: [
                      ConstrainedWidthWidget(
                        child: Text(
                          "Assumed Rainfall Scenario:",
                          style: subHeadingStyle,
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
                            "Water Level Comparison",
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

                // Slider
                ConstrainedWidthWidget(
                  child: Container(
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: kBorderRadius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        spacing: 16,
                        children: [
                          ConstrainedWidthWidget(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Current Usage: ", style: subHeadingStyle),
                                Text(
                                  "${formatter.format(dailyUsage)}L/day",
                                  style: subHeadingStyle,
                                ),
                              ],
                            ),
                          ),
                          ConstrainedWidthWidget(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Comparison Usage: ",
                                  style: subHeadingStyle,
                                ),
                                Text(
                                  "${formatter.format(comparisonUsage)}L/day",
                                  style: subHeadingStyle,
                                ),
                              ],
                            ),
                          ),
                          ConstrainedWidthWidget(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.water_drop_outlined,
                                  color: black,
                                  size: 60,
                                ),
                                Expanded(
                                  child: Slider(
                                    value: comparisonUsage,
                                    activeColor: black,
                                    secondaryActiveColor: white,
                                    thumbColor: blue,
                                    min: 0,
                                    max: 2000,
                                    divisions: 45,
                                    onChanged: (value) {
                                      setState(() {
                                        comparisonUsage = value;
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      setState(() {
                                        // TODO: Update chart
                                        // _calculateResults(); // Recalculate when slider stops
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                ConstrainedWidthWidget(
                  child: Container(
                    decoration: BoxDecoration(
                      color: white,
                      border: Border.all(color: black, width: 3),
                      borderRadius: kBorderRadius,
                    ),
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "Water Projection Results",
                                  textAlign: TextAlign.left,
                                  style: inputFieldStyle,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "Days of current inventory remaining:",
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [Flexible(child: Text("Current usage:"))],
                          ),
                          Row(
                            children: [
                              Flexible(child: Text("Comparison usage:")),
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "Your comparison usage assumes a % reduction/ increase on your current usage",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ConstrainedWidthWidget(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          "How can I optimise my water usage?",
                          style: subHeadingStyle,
                        ),
                      ),
                    ],
                  ),
                ),

                // Optimisation tips button
                ConstrainedWidthWidget(
                  child: Row(
                    spacing: 16,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                // Optimisation tips button
                ConstrainedWidthWidget(
                  child: Row(
                    spacing: 16,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: "Back to water usage input page",
                          child: InkWell(
                            borderRadius: kBorderRadius,
                            onTap: () {
                              setState(() {
                                usageIsPressed = true;
                              });
                              Future.delayed(
                                const Duration(milliseconds: 150),
                              ).then((value) async {
                                setState(() {
                                  usageIsPressed = false;
                                });

                                // nav to optimisation tips view
                                await Navigator.push(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WaterUsageView(),
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
                                  usageIsPressed ? BoxShadow() : kShadow,
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    "Back to Water Usage",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
