import 'package:aquabalance/config/constants.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../widgets/constrained_width_widget.dart';

class OptimisationTipsView extends StatefulWidget {
  const OptimisationTipsView({super.key});

  @override
  State<OptimisationTipsView> createState() => _OptimisationTipsViewState();
}

class _OptimisationTipsViewState extends State<OptimisationTipsView> {
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash',
  );

  // Provide a prompt that contains text
  final prompt = [
    Content.text(
      "What are some tips to optimise water usage for fringe suburban Adelaide "
      "(South Australia) households who are not connected to mains water?",
    ),
  ];

  String output = "";

  bool isLoading = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              spacing: 32,
              children: [
                ConstrainedWidthWidget(
                  child: Tooltip(
                    message: "Generate Water Optimisation Tips",
                    child: InkWell(
                      borderRadius: kBorderRadius,
                      onTap: () async {
                        setState(() {
                          isPressed = true;
                          isLoading = true;
                        });
                        Future.delayed(const Duration(milliseconds: 150)).then((
                          value,
                        ) async {
                          setState(() {
                            isPressed = false;
                          });
                          // Generate content based on prompt
                          await model.generateContent(prompt).then((value) {
                            setState(() {
                              isLoading = false;
                              output = value.text!;
                            });
                            return value;
                          });
                        });
                      },
                      child: AnimatedContainer(
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
                            child: Text(
                              "Generate Optimisation Tips",
                              style: subHeadingStyle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                isLoading
                    ? const CircularProgressIndicator(color: white)
                    : Text(output, style: subHeadingStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
