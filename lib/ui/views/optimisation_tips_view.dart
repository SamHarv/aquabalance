import 'package:aquabalance/config/constants.dart';
import 'package:aquabalance/logic/services/data_persist_service.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../widgets/constrained_width_widget.dart';

class OptimisationTipsView extends StatefulWidget {
  const OptimisationTipsView({super.key});

  @override
  State<OptimisationTipsView> createState() => _OptimisationTipsViewState();
}

class _OptimisationTipsViewState extends State<OptimisationTipsView> {
  // TODO: add inputs
  // Initialise data persist service
  final _dataPersistService = DataPersistService();

  Future<Map<String, String>> getUserInputs() async {
    final tankData = await _dataPersistService.loadTankData();
    final tanks = tankData['tanks'] as List;
    // Get tanks capacity & inventory (waterLevel)
    int totalCapacity = 0;
    int totalInventory = 0;
    for (var tank in tanks) {
      totalCapacity += (tank.capacity ?? 0) as int;
      totalInventory += (tank.waterLevel ?? 0) as int;
    }
    // get daily usage & num of people in house
    final waterUsageData = await _dataPersistService.loadWaterUsageData();
    final List<int> dailyUsage = waterUsageData['personWaterUsageList'];
    // sum dailyUsage list
    final totalUsage = dailyUsage.fold<int>(0, (sum, usage) => sum + usage);
    final int numPeople = waterUsageData['numOfPeople'] as int;
    // Get roof catchment and other water intake
    final roofCatchmentData = await _dataPersistService.loadRoofCatchmentData();
    final String otherWaterIntake = roofCatchmentData['otherIntake'];
    final String roofCatchment = roofCatchmentData['roofCatchmentArea'];
    // Get average annual rainfall
    // Get median annual rainfall for last 10 years
    final rainfall = lastYearTotal;

    return {
      'totalCapacity': totalCapacity.toString(),
      'totalInventory': totalInventory.toString(),
      'dailyUsage': totalUsage.toString(),
      'numPeople': numPeople.toString(),
      'otherWaterIntake': otherWaterIntake,
      'roofCatchment': roofCatchment,
      'rainfall': rainfall.toString(),
    };
  }

  // Enable copy & paste?

  // Prompt for Gemini model
  late final List<Content> prompt;

  // For loading wheel
  bool isLoading = true;

  // Future for future builder (to become generated output)
  late final Future<String> _output;
  // Output text to be displayed in widget
  String outputText = "";

  // Gemini model
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash',
  );

  // Generate output
  Future<String> getTips() async {
    try {
      final tankData = await _dataPersistService.loadTankData();
      final tanks = tankData['tanks'] as List;
      // Get tanks capacity & inventory (waterLevel)
      int totalCapacity = 0;
      int totalInventory = 0;
      for (var tank in tanks) {
        totalCapacity += (tank.capacity ?? 0) as int;
        totalInventory += (tank.waterLevel ?? 0) as int;
      }
      // get daily usage & num of people in house
      final waterUsageData = await _dataPersistService.loadWaterUsageData();
      final List<int> dailyUsage = waterUsageData['personWaterUsageList'];
      // sum dailyUsage list
      final totalUsage = dailyUsage.fold<int>(0, (sum, usage) => sum + usage);
      final int numPeople = waterUsageData['numOfPeople'] as int;
      // Get roof catchment and other water intake
      final roofCatchmentData = await _dataPersistService
          .loadRoofCatchmentData();
      final String otherWaterIntake = roofCatchmentData['otherIntake'];
      final String roofCatchment = roofCatchmentData['roofCatchmentArea'];
      // Get average annual rainfall
      // Get median annual rainfall for last 10 years
      final rainfall = lastYearTotal;

      prompt = [
        Content.text(
          """My household in the Adelaide fringe is off-mains for water.
          People in household: $numPeople
          Current water use: ${totalUsage}L per day
          Tank capacity: ${totalCapacity}L
          Current tank inventory: ${totalInventory}L
          Roof catchment: ${roofCatchment}sqm
          Other water sources: ${otherWaterIntake}L
          Annual rainfall: ${rainfall}mm
          Generate practical, mobile-friendly water-saving tips for house and garden activities.
          Instructions:
          Group the tips under clear subheadings
          Each topic subheading should be surrounded by **
          Each bullet point should use a • symbol, break a new line, and should:
          • Describe a specific action or change
          • Quantify the potential water saving where possible
          • Use concise, Australian English wording
          Only output the grouped list with subheadings and bullet points—no extra explanations or introductions""",
        ),
      ];
      await model.generateContent(prompt).then((value) {
        setState(() {
          isLoading = false;
          outputText = value.text!;
        });
        return value;
      });
    } catch (e) {
      return "Static Output";
    }
    return "";
  }

  List<Widget> processStringToTextWidgets(String input) {
    return input.split('\n').map((line) {
      line.trim();
      if (line.contains('**')) {
        // Remove the ** markers and make the text bold
        String cleanLine = line.replaceAll('**', '');
        return Row(
          children: [
            Flexible(
              child: Text(
                cleanLine,
                textAlign: TextAlign.left,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Flexible(
              child: Text(
                line,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      }
    }).toList();
  }

  @override
  void initState() {
    _output = getTips(); // initialise output

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: FutureBuilder(
              future: _output,
              builder: (context, snapshot) {
                return isLoading
                    ? const CircularProgressIndicator(color: white)
                    : ConstrainedWidthWidget(
                        child: Container(
                          decoration: BoxDecoration(
                            color: white,
                            border: Border.all(color: black, width: 3),
                            borderRadius: kBorderRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ...processStringToTextWidgets(outputText),
                              ],
                            ),
                          ),
                        ),
                      );
              },
            ),
          ),
        ),
      ),
    );
  }
}
