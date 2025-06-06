// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '/ui/widgets/constrained_width_widget.dart';

// import '../../config/constants.dart';
// import 'location_view.dart';

// class DisclaimerView extends StatefulWidget {
//   /// [DisclaimerView] displays a disclaimer with which to agree before
//   /// using the tool
//   const DisclaimerView({super.key});

//   @override
//   State<DisclaimerView> createState() => _DisclaimerViewState();
// }

// class _DisclaimerViewState extends State<DisclaimerView> {
//   // Initialise button state for press animation
//   bool isPressed = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Build consistent app bar
//       appBar: buildAppBar(context),
//       body: Center(
//         // Scrollable page to allow for varying screen heights
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: kPadding, // 32px padding
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               spacing: 32,
//               children: [
//                 // Disclaimer text
//                 ConstrainedWidthWidget(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: white,
//                       border: Border.all(color: black, width: 3),
//                       borderRadius: kBorderRadius,
//                     ),
//                     child: Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Center(
//                         child: Column(
//                           spacing: 24,
//                           children: [
//                             Text("Disclaimer", style: headingStyle),
//                             Text(
//                               "Estimate how many days of water inventory you have "
//                               "in your water tank based on current inventory, "
//                               "predicted rainfall, and estimated water usage to "
//                               "better manage your supply.",
//                               style: subHeadingStyle,
//                             ),
//                             Text(
//                               "This tool uses calculations to estimate water "
//                               "intake and usage, and may not reflect actual "
//                               "intake and usage. Results should not be relied "
//                               "upon for critical decisions without "
//                               "professional advice. Data entered into this app "
//                               "will be stored on your device and kept private.",
//                               style: GoogleFonts.openSans(
//                                 textStyle: TextStyle(fontSize: 16),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Agree & Continue button
//                 Tooltip(
//                   message: "Agree to disclaimer and continue",
//                   child: ConstrainedWidthWidget(
//                     child: InkWell(
//                       borderRadius: kBorderRadius, // 32px border radius
//                       onTap: () {
//                         // Handle button press animation
//                         setState(() {
//                           isPressed = true;
//                         });
//                         Future.delayed(const Duration(milliseconds: 150)).then((
//                           value,
//                         ) {
//                           setState(() {
//                             isPressed = false;
//                           });
//                           // Navigate to location view
//                           Navigator.push(
//                             // ignore: use_build_context_synchronously
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const LocationView(),
//                             ),
//                           );
//                         });
//                       },
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 100),
//                         decoration: BoxDecoration(
//                           color: white,
//                           border: Border.all(color: black, width: 3),
//                           borderRadius: kBorderRadius,
//                           boxShadow: [isPressed ? BoxShadow() : kShadow],
//                         ),
//                         child: Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Center(
//                             child: Text(
//                               "Agree & Continue",
//                               style: subHeadingStyle,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
