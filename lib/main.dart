import 'package:flutter/material.dart';
import 'package:reducio/home_screen.dart';

void main() {
  runApp(const ReducioApp());
}

class ReducioApp extends StatelessWidget {
  const ReducioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- "Magical Tome" Color Palette ---
    const Color parchmentLight =
        Color(0xFFF5EFE1); // Light parchment for text on dark bg
    const Color parchmentDark =
        Color(0xFFDCCDBA); // Aged parchment for backgrounds/surfaces
    const Color ancientInk = Color(0xFF3A2E27); // Dark brown/black for text
    const Color darkLeather =
        Color(0xFF2A201D); // Very dark brown for main background
    const Color mysticalGold = Color(0xFFC0A062); // Gold accent
    const Color subtleGoldHighlight = Color(0xFFD4B98A);
    const Color darkWood =
        Color(0xFF4A3B34); // For card backgrounds or darker surfaces

    // A more readable body font (optional, if you added one to pubspec)
    // const String bodyFontFamily = 'Lora'; // Or your chosen body font

    return MaterialApp(
      title: 'reducio',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily:
            null, // Default to system for body text unless specified like 'Lora'
        // fontFamily: bodyFontFamily, // Uncomment if using a custom body font

        // --- Color Scheme ---
        colorScheme: ColorScheme(
          brightness: Brightness.dark, // Overall dark theme

          primary: mysticalGold, // Primary actions, highlights
          onPrimary: ancientInk, // Text on primary buttons/elements

          secondary: subtleGoldHighlight, // Secondary accents
          onSecondary: ancientInk, // Text on secondary

          error: Colors.red.shade300, // Error color
          onError: Colors.black, // Text on error

          background: darkLeather, // Deepest background of the app window
          onBackground: parchmentLight, // Main text on the deepest background

          surface:
              darkWood, // Background of cards, dialogs, input fields (slightly lighter)
          onSurface: parchmentLight, // Text on surfaces

          surfaceVariant: Color.lerp(
              darkWood, darkLeather, 0.3)!, // For subtle variations, borders
          outline: mysticalGold.withOpacity(0.4), // Borders for inputs, etc.
        ),

        // --- Text Theme ---
        textTheme: TextTheme(
          // Headline (reducio title) will be styled directly with HarryPotter font
          displayLarge: TextStyle(
              fontFamily: 'HarryPotter',
              color: mysticalGold,
              fontSize: 52), // For the main "reducio"

          // Section Headers (e.g., "Source & Destination")
          titleLarge: TextStyle(
              color: parchmentDark,
              fontWeight: FontWeight.bold,
              fontSize: 20), // fontFamily: bodyFontFamily (if used)
          titleMedium: TextStyle(
              color: parchmentDark.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 18), // fontFamily: bodyFontFamily

          // Body text
          bodyLarge: TextStyle(
              color: parchmentLight,
              fontSize: 15,
              height: 1.4), // fontFamily: bodyFontFamily
          bodyMedium: TextStyle(
              color: parchmentLight.withOpacity(0.85),
              fontSize: 14,
              height: 1.3), // fontFamily: bodyFontFamily

          // Labels (for input fields, etc.)
          labelLarge: TextStyle(
              color: mysticalGold,
              fontWeight: FontWeight.w600,
              fontSize: 15), // fontFamily: bodyFontFamily
          labelMedium: TextStyle(
              color: parchmentDark.withOpacity(0.8),
              fontSize: 13), // fontFamily: bodyFontFamily
        ),

        // --- Input Decoration Theme (for TextFields, Dropdowns) ---
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkLeather.withOpacity(
              0.6), // Slightly darker than surface for "inset" feel
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(4.0), // Sharper edges, less "modern"
            borderSide: BorderSide(color: mysticalGold.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide:
                BorderSide(color: mysticalGold.withOpacity(0.5), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(color: mysticalGold, width: 1.5),
          ),
          labelStyle: TextStyle(color: mysticalGold.withOpacity(0.8)),
          hintStyle: TextStyle(color: parchmentLight.withOpacity(0.5)),
          // Prefix/suffix icon colors
          prefixIconColor: mysticalGold.withOpacity(0.7),
          suffixIconColor: mysticalGold.withOpacity(0.7),
        ),

        // --- Button Themes ---
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: mysticalGold,
            foregroundColor: ancientInk,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8), // fontFamily: bodyFontFamily
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0), // Slightly less rounded
              side:
                  BorderSide(color: mysticalGold.withOpacity(0.7), width: 0.5),
            ),
            elevation: 3,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: mysticalGold,
            side: BorderSide(color: mysticalGold.withOpacity(0.8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600), // fontFamily: bodyFontFamily
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0)),
          ),
        ),

        // --- TabBar Theme ---
        tabBarTheme: TabBarTheme(
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
              // "Underline" style indicator
              border:
                  Border(bottom: BorderSide(color: mysticalGold, width: 3))),
          // indicator: BoxDecoration( // "Filled tab" style indicator
          //   borderRadius: BorderRadius.circular(0), // Square for tome feel
          //   color: darkWood.withOpacity(0.7),
          //   border: Border.all(color: mysticalGold.withOpacity(0.5))
          // ),
          labelColor: mysticalGold,
          unselectedLabelColor: parchmentDark.withOpacity(0.7),
          labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold), // fontFamily: bodyFontFamily
          unselectedLabelStyle:
              const TextStyle(fontSize: 15), // fontFamily: bodyFontFamily
        ),

        // --- Card Theme ---
        cardTheme: CardTheme(
          elevation: 4, // Slightly increased elevation for more "pop"
          color: darkWood,
          shadowColor:
              Colors.black.withOpacity(0.4), // Make shadow a bit more visible
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Slightly more rounding
            side:
                BorderSide(color: mysticalGold.withOpacity(0.25), width: 0.75),
          ),
          margin: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal:
                  0), // No horizontal margin on cards if content is centered
        ),

        sliderTheme: SliderThemeData(
          trackHeight: 3.0, // Slightly thinner or thicker track
          activeTrackColor: mysticalGold.withOpacity(0.8),
          inactiveTrackColor: ancientInk.withOpacity(0.5),
          thumbColor: parchmentDark, // Thumb color
          overlayColor: mysticalGold.withOpacity(0.2),
          thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8.0), // Smaller/larger thumb
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          valueIndicatorColor: ancientInk.withOpacity(0.8),
          valueIndicatorTextStyle: TextStyle(
            color: parchmentLight,
          ), // Ensure themed font for value indicator
        ),

        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return mysticalGold; // Thumb color when selected
            }
            return parchmentDark
                .withOpacity(0.8); // Thumb color when unselected
          }),
          trackColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return mysticalGold.withOpacity(0.5); // Track color when selected
            }
            return ancientInk.withOpacity(0.6); // Track color when unselected
          }),
          trackOutlineColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return mysticalGold.withOpacity(0.2);
            }
            return ancientInk.withOpacity(0.3);
          }),
        ),

        scaffoldBackgroundColor: darkLeather, // Main app background
        dialogBackgroundColor: darkWood,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
