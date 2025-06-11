import 'package:flutter/material.dart';
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/logic/results_calculator.dart';
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
  // For optimisation tips button animation
  bool optimisationIsPressed = false;
  // For back to water usage animation
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
  Map<String, double> monthlyIntakeData = {};
  Map<String, dynamic> tankSummary = {};
  int annualRainfall = 0;

  // Comparison data
  double comparisonUsage = 0;
  dynamic comparisonDaysLeft = 0;
  String comparisonResultMessage = "";
  bool usageIsIncreasing = false;
  bool daysRemainingIsIncreasing = true;

  // User inputs
  String selectedRainfall = "10-year median";

  // Loading state
  bool isLoading = true;

  // Message to display on error
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _calculateResults().then((_) {
      // // Initialise comparison usage to daily usage minus 5%
      // comparisonUsage = dailyUsage * 0.95;
      // Get comparison vs current % difference
      comparisonResultMessage = getComparisonDifference(
        dailyUsage,
        comparisonUsage,
      );
      _calculateComparisonDaysRemaining();
    }); // Calculate results to initialise values
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
        title: ConstrainedWidthWidget(
          child: Text(message, style: subHeadingStyle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK", style: TextStyle(color: black)),
          ),
        ],
      ),
    );
  }

  // Get percentage difference in daily usage vs comparison usage
  String getComparisonDifference(double current, double comparison) {
    double percDiff = 0;
    if (comparison == 0) {
      // Comparison usage is 100% less than current
      percDiff = -100;
    } else if (current == 0) {
      // Comparison usage is 100% more than current
      percDiff = 100;
    } else {
      // Calculate the percentage difference (can be negative)
      percDiff = ((comparison - current) / current) * 100;
    }

    if (percDiff > 0) {
      // Comparison usage is greater than current
      percDiff = percDiff.abs();
      usageIsIncreasing = true;
      return "${percDiff.toInt()}% increase";
    } else {
      // Comparison usage is less than or equal to current
      percDiff = percDiff.abs();
      usageIsIncreasing = false;
      return "${percDiff.toInt()}% reduction";
    }
  }

  // Get percentage difference in days remaining
  String getDaysRemainingDifference(
    dynamic currentDaysLeft,
    dynamic comparisonDaysLeft,
  ) {
    double daysDiffPerc = 0;

    if (comparisonDaysLeft == "Infinite" && currentDaysLeft == -1) {
      if (usageIsIncreasing) {
        daysRemainingIsIncreasing = false;
        return "decreases days remaining";
      } else {
        daysRemainingIsIncreasing = true;
        return "increases days remaining";
      }
    } else if (comparisonDaysLeft == "Infinite") {
      daysRemainingIsIncreasing = true;
      return "increases days remaining";
    } else if (currentDaysLeft == "Infinite" || currentDaysLeft == -1) {
      daysRemainingIsIncreasing = false;
      return "decreases days remaining";
    }

    if (comparisonDaysLeft == 0) {
      daysDiffPerc = -100;
    } else if (currentDaysLeft == 0) {
      daysDiffPerc = 100;
    } else {
      daysDiffPerc =
          ((comparisonDaysLeft - currentDaysLeft) / currentDaysLeft) * 100;
    }

    if (daysDiffPerc > 0) {
      daysDiffPerc = daysDiffPerc.abs();
      daysRemainingIsIncreasing = true;
      return "increases days remaining by ${daysDiffPerc.toInt()}%";
    } else {
      daysDiffPerc = daysDiffPerc.abs();
      daysRemainingIsIncreasing = false;
      return "decreases days remaining by ${daysDiffPerc.toInt()}%";
    }
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

      // Assign results
      setState(() {
        daysLeft = results['daysRemaining'] ?? 0;
        currentInventory = results['currentInventory'] ?? 0;
        dailyUsage = results['dailyUsage'] ?? 0;
        comparisonUsage == 0
            ? comparisonUsage = results['dailyUsage'] * 0.95 ?? 0
            : comparisonUsage = comparisonUsage;
        dailyIntake = results['dailyIntake'] ?? 0;
        netDailyChange = results['netDailyChange'] ?? 0;
        isIncreasing = results['isIncreasing'] ?? false;
        resultMessage = results['message'] ?? "";
        projectedData = results['projectedData'] ?? [];
        monthlyIntakeData = results['monthlyIntake'] ?? {};
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

  // Calculate comparison projection data
  List<Map<String, dynamic>> _calculateComparisonProjection() {
    if (projectedData.isEmpty || monthlyIntakeData.isEmpty) return [];

    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final List<Map<String, dynamic>> comparisonProjectedData = [];
    double currentLevel = currentInventory.toDouble();
    final startDate = DateTime.now();
    final daysToProject = 90; // Same as original projection

    for (int day = 0; day <= daysToProject; day++) {
      // Daily increments
      final projectedDate = startDate.add(Duration(days: day));
      final monthIndex = projectedDate.month - 1;
      final monthName = monthNames[monthIndex];

      // Calculate days in this specific month and year
      final daysInMonth = DateTime(
        projectedDate.year,
        projectedDate.month + 1,
        0,
      ).day;

      // Get the daily intake for this specific month using the stored monthly intake data
      final dailyIntakeForThisMonth =
          monthlyIntakeData[monthName]! / daysInMonth;

      // Update water level with comparison usage
      // Ensure it does not exceed total capacity
      if (currentLevel <= tankSummary['totalCapacity']) {
        currentLevel += (dailyIntakeForThisMonth - comparisonUsage);
      }

      // Ensure level doesn't go below 0
      if (currentLevel < 0) currentLevel = 0;

      comparisonProjectedData.add({
        'day': day,
        'date': projectedDate.toIso8601String().split('T')[0],
        'dateFormatted': DateFormat('dd MMM').format(projectedDate),
        'waterLevel': currentLevel.round(),
        'dailyIntake': dailyIntakeForThisMonth,
        'dailyUsage': comparisonUsage,
      });

      // Stop projecting if tank is empty
      if (currentLevel <= 0 && day > 0) break;
    }

    return comparisonProjectedData;
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

    // Calculate comparison projection
    final comparisonProjectedData = _calculateComparisonProjection();

    // Find max value for chart scaling from both datasets
    // final maxLevel = [
    //   ...projectedData.map((d) => d['waterLevel'] as int),
    //   ...comparisonProjectedData.map((d) => d['waterLevel'] as int),
    // ].reduce((a, b) => a > b ? a : b);

    // Add 20% to max value for chart height
    // final maxY = maxLevel > 0 ? maxLevel * 1.2 : 1000.0;

    final maxY = tankSummary['totalCapacity'] + 1000;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            clipData: FlClipData.all(),
            // Horizontal lines
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
                  maxIncluded:
                      false, // Don't show max line to avoid cluttered labels
                  showTitles: true,
                  reservedSize: 50, // Space for labels
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
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
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
                        projectedData[index]['dateFormatted'],
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
              // Current usage line
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
              // Comparison usage line
              if (comparisonUsage > 0)
                LineChartBarData(
                  spots: comparisonProjectedData.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value['waterLevel'].toDouble(),
                    );
                  }).toList(),
                  preventCurveOverShooting: true,

                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.purple],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  dashArray: [5, 5], // Dashed line to differentiate
                  belowBarData: BarAreaData(
                    show: false,
                  ), // No fill for comparison line
                ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final isCurrentUsage = spot.barIndex == 0;

                    if (isCurrentUsage && index < projectedData.length) {
                      final data = projectedData[index];
                      final date = DateTime.parse(data['date']);
                      return LineTooltipItem(
                        'Current Usage\n${date.day}/${date.month}\n${data['waterLevel']}L',
                        TextStyle(color: white, fontSize: 12),
                      );
                    } else if (!isCurrentUsage &&
                        index < comparisonProjectedData.length) {
                      final data = comparisonProjectedData[index];
                      final date = DateTime.parse(data['date']);
                      return LineTooltipItem(
                        'Comparison Usage\n${date.day}/${date.month}\n${data['waterLevel']}L',
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
      ),
    );
  }

  // Calculate comparison days remaining
  void _calculateComparisonDaysRemaining() {
    if (comparisonUsage <= 0) {
      comparisonDaysLeft = "Infinite";
      return;
    }

    final netDailyChange = dailyIntake - comparisonUsage;

    if (netDailyChange >= 0) {
      comparisonDaysLeft = "Infinite"; // Infinite/increasing
    } else {
      if (currentInventory <= 0) {
        comparisonDaysLeft = 0;
      } else {
        comparisonDaysLeft = (currentInventory / netDailyChange.abs()).floor();
      }
    }
  }

  // Add legend to chart to differentiate between current and comparison usage
  Widget _buildChartWithLegend() {
    return ConstrainedWidthWidget(
      child: Container(
        decoration: BoxDecoration(
          color: white,
          border: Border.all(color: black, width: 3),
          borderRadius: kBorderRadius,
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Current vs Comparison Usage", style: subHeadingStyle),
              SizedBox(height: 16),

              // Build the chart
              _buildProjectionChart(),
              // Legend
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Current usage line
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              blue,
                              isIncreasing ? Colors.green : Colors.red,
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Current Usage",
                          style: GoogleFonts.openSans(
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "${formatter.format(dailyUsage)}L/day",
                        style: GoogleFonts.openSans(
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Comparison usage line
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.purple],
                          ),
                        ),
                        child: CustomPaint(painter: DashedLinePainter()),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Comparison Usage",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "${formatter.format(comparisonUsage)}L/day",
                        style: GoogleFonts.openSans(
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              //
              ConstrainedWidthWidget(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.water_drop_outlined, color: black, size: 40),
                    Expanded(
                      child: Slider(
                        value: comparisonUsage,
                        activeColor: black,
                        secondaryActiveColor: white,
                        thumbColor: blue,
                        min: 0,
                        max: dailyUsage * 2,
                        divisions: 200,
                        label: "${formatter.format(comparisonUsage)}L/day",
                        onChanged: (value) {
                          setState(() {
                            comparisonUsage = value;
                            comparisonResultMessage = getComparisonDifference(
                              dailyUsage,
                              comparisonUsage,
                            );
                            _calculateComparisonDaysRemaining();
                          });
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            comparisonUsage = value;
                            comparisonResultMessage = getComparisonDifference(
                              dailyUsage,
                              comparisonUsage,
                            );
                            _calculateComparisonDaysRemaining();
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
      appBar: buildAppBar(context, null),
      body: Center(
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

                // // Slider Container
                // ConstrainedWidthWidget(
                //   child: Container(
                //     decoration: BoxDecoration(
                //       color: white,
                //       borderRadius: kBorderRadius,
                //     ),
                //     child: Padding(
                //       padding: const EdgeInsets.all(16),
                //       child: Column(
                //         spacing: 16,
                //         children: [
                //           // Current usage values
                //           ConstrainedWidthWidget(
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Row(
                //                   mainAxisAlignment:
                //                       MainAxisAlignment.spaceBetween,
                //                   children: [
                //                     Text(
                //                       "Current Usage",
                //                       style: subHeadingStyle,
                //                     ),
                //                     // Current usage in L/day
                //                     RichText(
                //                       text: TextSpan(
                //                         children: [
                //                           TextSpan(
                //                             text: formatter.format(dailyUsage),
                //                             // textAlign: TextAlign.right,
                //                             style: GoogleFonts.openSans(
                //                               textStyle: const TextStyle(
                //                                 color: black,
                //                                 fontSize: 20,
                //                                 fontWeight: FontWeight.bold,
                //                               ),
                //                             ),
                //                           ),
                //                           TextSpan(
                //                             text: " L/day",
                //                             // textAlign: TextAlign.right,
                //                             style: GoogleFonts.openSans(
                //                               textStyle: const TextStyle(
                //                                 color: black,
                //                                 fontSize: 16,
                //                               ),
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //                 SizedBox(height: 8),
                //                 Row(
                //                   mainAxisAlignment:
                //                       MainAxisAlignment.spaceBetween,
                //                   children: [
                //                     Text(
                //                       "Comparison Usage",
                //                       style: subHeadingStyle,
                //                     ),
                //                     // Comparison usage in L/day
                //                     RichText(
                //                       text: TextSpan(
                //                         children: [
                //                           TextSpan(
                //                             text: formatter.format(
                //                               comparisonUsage,
                //                             ),
                //                             style: GoogleFonts.openSans(
                //                               textStyle: const TextStyle(
                //                                 color: black,
                //                                 fontSize: 20,
                //                                 fontWeight: FontWeight.bold,
                //                               ),
                //                             ),
                //                           ),
                //                           TextSpan(
                //                             text: " L/day",
                //                             style: GoogleFonts.openSans(
                //                               textStyle: const TextStyle(
                //                                 color: black,
                //                                 fontSize: 16,
                //                               ),
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ],
                //             ),
                //           ),

                //           // Slider
                //           ConstrainedWidthWidget(
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //               children: [
                //                 Icon(
                //                   Icons.water_drop_outlined,
                //                   color: black,
                //                   size: 40,
                //                 ),
                //                 Expanded(
                //                   child: Slider(
                //                     value: comparisonUsage,
                //                     activeColor: black,
                //                     secondaryActiveColor: white,
                //                     thumbColor: blue,
                //                     min: 0,
                //                     max: dailyUsage * 2,
                //                     divisions: 200,
                //                     label:
                //                         "${formatter.format(comparisonUsage)}L/day",
                //                     onChanged: (value) {
                //                       setState(() {
                //                         comparisonUsage = value;
                //                         comparisonResultMessage =
                //                             getComparisonDifference(
                //                               dailyUsage,
                //                               comparisonUsage,
                //                             );
                //                         _calculateComparisonDaysRemaining();
                //                       });
                //                     },
                //                     onChangeEnd: (value) {
                //                       setState(() {
                //                         comparisonUsage = value;
                //                         comparisonResultMessage =
                //                             getComparisonDifference(
                //                               dailyUsage,
                //                               comparisonUsage,
                //                             );
                //                         _calculateComparisonDaysRemaining();
                //                       });
                //                     },
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),

                // Chart to visualise tank levels
                _buildChartWithLegend(),

                // Outputs
                ConstrainedWidthWidget(
                  child: Container(
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: kBorderRadius,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Days of inventory remaining:",
                                style: subHeadingStyle,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "On current usage:",
                                style: GoogleFonts.openSans(
                                  textStyle: const TextStyle(
                                    color: black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              // Current days remaining of inventory
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: daysLeft == -1
                                          ? "Infinite"
                                          : daysLeft.toString(),
                                      // textAlign: TextAlign.right,
                                      style: GoogleFonts.openSans(
                                        textStyle: const TextStyle(
                                          color: black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // TextSpan(
                                    //   text: " days remaining",
                                    //   // textAlign: TextAlign.right,
                                    //   style: GoogleFonts.openSans(
                                    //     textStyle: const TextStyle(
                                    //       color: black,
                                    //       fontSize: 16,
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Comparison days remaining
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "On comparison usage:",
                                style: GoogleFonts.openSans(
                                  textStyle: const TextStyle(
                                    color: black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              // Comparison days remaining of inventory
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: comparisonDaysLeft == -1
                                          ? "Infinite"
                                          : comparisonDaysLeft.toString(),
                                      style: GoogleFonts.openSans(
                                        textStyle: TextStyle(
                                          color: black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // TextSpan(
                                    //   text: " days remaining",
                                    //   style: GoogleFonts.openSans(
                                    //     textStyle: const TextStyle(
                                    //       color: black,
                                    //       fontSize: 16,
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Percentage comparison
                          ConstrainedWidthWidget(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Percentage difference between current and comparison
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Comparison usage assumes a ",
                                        style: GoogleFonts.openSans(
                                          textStyle: subHeadingStyle,
                                        ),
                                      ),
                                      TextSpan(
                                        text: getComparisonDifference(
                                          dailyUsage,
                                          comparisonUsage,
                                        ),
                                        style: GoogleFonts.openSans(
                                          textStyle: TextStyle(
                                            color: usageIsIncreasing
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      TextSpan(
                                        text: " on current, this ",
                                        style: GoogleFonts.openSans(
                                          textStyle: subHeadingStyle,
                                        ),
                                      ),

                                      TextSpan(
                                        text: getDaysRemainingDifference(
                                          daysLeft,
                                          comparisonDaysLeft,
                                        ),
                                        style: GoogleFonts.openSans(
                                          textStyle: TextStyle(
                                            color: daysRemainingIsIncreasing
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
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

                // Rainfall pattern selection
                ConstrainedWidthWidget(
                  child: Column(
                    children: [
                      ConstrainedWidthWidget(
                        child: Text(
                          "Assumed Rainfall Scenario:",
                          style: subHeadingStyle,
                        ),
                      ),

                      SizedBox(height: 16),

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
                                        // Update values for new scenario
                                        _calculateResults().then((_) {
                                          _calculateComparisonDaysRemaining();
                                        });
                                      });
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

                // Optimisation tips
                Column(
                  children: [
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
                    SizedBox(height: 16),
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
                                      optimisationIsPressed
                                          ? BoxShadow()
                                          : kShadow,
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
                  ],
                ),

                // Back to water usage view button
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
                                // Double pop to nav back to water usage view
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
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

// Custom painter for the dashed line in legend
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
