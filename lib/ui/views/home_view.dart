import 'package:aquabalance/ui/views/location_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/ui/widgets/constrained_width_widget.dart';

import '../../config/constants.dart';
import 'disclaimer_view.dart';

class HomeView extends StatefulWidget {
  /// [HomeView] is the welcome screen of the app
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Button state for press animation
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    // MediaQueries for screen height and width
    final mediaHeight = MediaQuery.sizeOf(context).height;
    final mediaWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Center(
        // Scrollable page to allow for varying screen heights
        child: SingleChildScrollView(
          child: Padding(
            padding: kPadding, // 32px padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 32,
              children: [
                // Logo
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: mediaHeight * 0.3),
                  child: Hero(tag: "logo", child: Image.asset(logo)),
                ),
                // App Title - stack to achieve outlined text
                Stack(
                  children: [
                    // Stroked text as border.
                    Text(
                      appTitle,
                      style: GoogleFonts.openSans(
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Open Sans",
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 5
                            ..color = black,
                        ),
                      ),
                    ),
                    // Solid text as fill.
                    Text(
                      appTitle,
                      style: GoogleFonts.openSans(
                        textStyle: const TextStyle(
                          fontFamily: "Open Sans",
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                // Tagline
                ConstrainedWidthWidget(
                  child: Text(
                    "When water is the new gold, we help protect yours.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Helping communities conserve precious water through "
                        "predictive modelling and education.",
                        // textAlign: TextAlign.center,
                        style: subHeadingStyle,
                      ),
                    ),
                  ),
                ),
                // Button to begin
                Tooltip(
                  message: "Continue to next step",
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 300),
                    child: InkWell(
                      borderRadius: kBorderRadius, // 32px radius
                      onTap: () {
                        // Handle button press animation
                        setState(() {
                          isPressed = true;
                        });
                        Future.delayed(const Duration(milliseconds: 150)).then((
                          value,
                        ) {
                          setState(() {
                            isPressed = false;
                          });
                          // navigate to disclaimer view
                          Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocationView(),
                            ),
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
                            child: Text("Begin", style: subHeadingStyle),
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
