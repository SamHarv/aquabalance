import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '/config/constants.dart';
import '/logic/services/data_persist_service.dart';
import '../widgets/constrained_width_widget.dart';

class OptimisationTipsView extends StatefulWidget {
  /// [OptimisationTipsView] to display tips for water usage optimisation
  /// generated by Gemini
  const OptimisationTipsView({super.key});

  @override
  State<OptimisationTipsView> createState() => _OptimisationTipsViewState();
}

class _OptimisationTipsViewState extends State<OptimisationTipsView> {
  // Initialise data persist service
  final _dataPersistService = DataPersistService();

  // Initialise empty prompt for Gemini model
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

  // Generate output based on user inputs
  Future<String> getTips() async {
    try {
      // Get tank data
      final tankData = await _dataPersistService.loadTankData();
      // Get tanks
      final tanks = tankData['tanks'] as List;
      // Get tanks capacity & inventory (waterLevel)
      int totalCapacity = 0;
      int totalInventory = 0;
      // Sum capacity & inventory for all tanks
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

      // Get last year's annual rainfall
      final rainfall = lastYearTotal;

      // Generate prompt with inputs
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

      // Generate output
      await model.generateContent(prompt).then((value) {
        setState(() {
          isLoading = false;
          outputText = value.text!;
        });
        return value;
      });
    } catch (e) {
      // Static screen for default
      return """
              **In the Home**

              • Take shorter showers. Aim for 4-minute showers. This could save up to 40L per shower.
              • Install a low-flow showerhead. This can reduce water usage by up to 50%.
              • Turn off the tap while brushing your teeth. This can save up to 6L per minute.
              • Use a bowl for washing dishes instead of running the tap. This can save up to 20L per wash.
              • Only run the washing machine and dishwasher with full loads. This saves water and energy.
              • Fix any leaking taps or toilets immediately. A dripping tap can waste up to 20L per day.
              • Install tap aerators to reduce water flow without impacting water pressure.
              • Use a plug in the sink when shaving instead of running the tap.
              • Consider using waterless hand sanitiser.

              **In the Garden**

              • Water plants deeply but less frequently, encouraging deep root growth.
              • Water your garden early in the morning or late in the evening to reduce evaporation.
              • Use a trigger nozzle on your hose.
              • Apply mulch around plants to retain moisture in the soil.
              • Collect rainwater in buckets while waiting for the shower water to heat up and use it for watering pot plants.
              • Choose drought-tolerant plants that require less water.
              • Install a greywater system to recycle water from showers and washing machines for garden irrigation (consult with local regulations).
              • Use a broom instead of a hose to clean driveways and patios.
              • Consider a "no-mow" lawn alternative to reduce watering needs.
              • Direct downpipes into garden beds to distribute water efficiently.""";
    }
    return "";
  }

  // Process output text for consistent formatting
  List<Widget> processStringToTextWidgets(String input) {
    input.replaceAll("\n\n", "\n");
    // print(input); // debug
    return input.split('\n').map((line) {
      line.trim();
      if (line.contains("\t")) {
        line = line.replaceAll("\t", "");
      } else if (line.contains("    ")) {
        line = line.replaceAll("    ", "");
      } else if (line.contains("••")) {
        line = line.replaceAll("••", "•");
      } else if (line.contains("•   ")) {
        line = line.replaceAll("•   ", "• ");
      } else if (line.contains("• •")) {
        line = line.replaceAll("• •", "•");
      }
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
      appBar: buildAppBar(context, null),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
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
