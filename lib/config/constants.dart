import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Colour pallete
const black = Colors.black;
const blue = Color.fromARGB(255, 0, 195, 255);
const white = Colors.white;

// App title
const appTitle = "AquaBalance";

// Logo
const logo = 'images/white_droplet.png';

// Style for headings
final headingStyle = GoogleFonts.openSans(
  textStyle: const TextStyle(
    color: black,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  ),
);

// Style for subheadings/ text
final subHeadingStyle = GoogleFonts.openSans(
  textStyle: const TextStyle(
    color: black,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
);

// Style for input fields
final inputFieldStyle = GoogleFonts.openSans(
  textStyle: TextStyle(color: black, fontSize: 20, fontWeight: FontWeight.bold),
);

// Style for segmented buttons
final segButtonStyle = ButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith<Color>((
    Set<WidgetState> states,
  ) {
    if (states.contains(WidgetState.selected)) {
      return white;
    }
    return Colors.grey[400]!;
  }),
  elevation: WidgetStateProperty.all(8),
  side: WidgetStateProperty.all(kBorderSide),
  shape: WidgetStateProperty.all(
    RoundedRectangleBorder(borderRadius: kBorderRadius, side: kBorderSide),
  ),
  textStyle: WidgetStateProperty.all(subHeadingStyle),
);

// Padding for widgets
const kPadding = EdgeInsets.all(32);

// Border radius for widgets
const kBorderRadius = BorderRadius.all(Radius.circular(32));

// Border side for widgets
const kBorderSide = BorderSide(color: black, width: 3);

// Border for input fields
const inputBorder = OutlineInputBorder(
  borderRadius: kBorderRadius,
  borderSide: kBorderSide,
);

// Shadow for button widgets
const kShadow = BoxShadow(
  color: black,
  blurRadius: 8,
  offset: Offset(4, 4),
  blurStyle: BlurStyle.solid,
);

// Build app bar
AppBar buildAppBar(BuildContext context, int step) {
  return AppBar(
    title: Text("Step $step of 5", style: inputFieldStyle),
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
  );
}

final formatter = NumberFormat('#,##0');

double lastYearTotal = 0;
