import 'package:flutter/material.dart';

const List<Color> allMateriaColors = [
  // Claros (12 colores)
  Color(0xFFFFD54F),
  Color(0xFFFFAB91),
  Color(0xFF90CAF9),
  Color(0xFFE1BEE7),
  Color(0xFFF48FB1),
  Color(0xFF4DB6AC),
  Color(0xFF4FC3F7),
  Color(0xFFA5D6A7),
  Color(0xFF4DD0E1),
  Color(0xFFAED581),
  Color(0xFFFFB74D),
  Color(0xFF48A9FE),
  // Oscuros (12 colores)
  Color(0xFFFF8A65),
  Color(0xFFBA68C8),
  Color(0xFF9C7BD5),
  Color(0xFFFF7043),
  Color(0xFF0F766E),
  Color(0xFF1D4ED8),
  Color(0xFFB45309),
  Color(0xFFBE123C),
  Color(0xFF6D28D9),
  Color(0xFF0E7490),
  Color(0xFF3F6212),
  Color(0xFF991B1B),
  // Neutros
  Colors.white,
  Colors.black,
];

Color cardColorForTheme(Color color, Brightness brightness) {
  final hsl = HSLColor.fromColor(color);

  // Evitamos extremos absolutos si el color es blanco o negro puro
  if (color == Colors.white || color == Colors.black) {
    return brightness == Brightness.light
        ? const Color(0xFFF8F9FA)
        : const Color(0xFF1E2630);
  }

  // Evaluamos si el color base original es oscuro según su luminosidad inicial
  final isDarkBase = hsl.lightness < 0.50;

  if (brightness == Brightness.light) {
    return hsl
        .withLightness(isDarkBase ? 0.92 : 0.89)
        .withSaturation(isDarkBase ? 0.35 : 0.48)
        .toColor();
  } else {
    return hsl
        .withLightness(isDarkBase ? 0.14 : 0.20)
        .withSaturation(isDarkBase ? 0.38 : 0.25)
        .toColor();
  }
}

Color materiaColorForTheme(Color color, Brightness brightness) {
  final hsl = HSLColor.fromColor(color);

  if (color == Colors.white || color == Colors.black) {
    return brightness == Brightness.light
        ? Colors.grey.shade300
        : Colors.grey.shade700;
  }

  final isDarkBase = hsl.lightness < 0.50;

  if (brightness == Brightness.light) {
    return hsl
        .withLightness(isDarkBase ? 0.52 : 0.75)
        .withSaturation(0.85)
        .toColor();
  } else {
    return hsl
        .withLightness(isDarkBase ? 0.45 : 0.35)
        .withSaturation(0.75)
        .toColor();
  }
}

Color defaultCardColor(Color background) => cardColorForTheme(
  background,
  background.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
);

Color defaultIconColor(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black : Colors.white;

Color defaultTextColor(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

Color pageBackgroundForPrimary(Color color, Brightness brightness) {
  final hsl = HSLColor.fromColor(color);

  if (color == Colors.white || color == Colors.black) {
    return brightness == Brightness.light
        ? const Color(0xFFF4F7F6)
        : const Color(0xFF0F1720);
  }

  return hsl
      .withLightness(brightness == Brightness.light ? 0.95 : 0.10)
      .withSaturation(brightness == Brightness.light ? 0.18 : 0.12)
      .toColor();
}

Color menuBackgroundForPrimary(Color color, Brightness brightness) {
  final hsl = HSLColor.fromColor(color);

  if (color == Colors.white || color == Colors.black) {
    return brightness == Brightness.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF0B1220);
  }

  return hsl
      .withLightness(brightness == Brightness.light ? 0.92 : 0.07)
      .withSaturation(brightness == Brightness.light ? 0.15 : 0.12)
      .toColor();
}

BoxDecoration scheduleCardDecoration(
  BuildContext context, {
  required Color backgroundColor,
  required Color accentColor,
}) {
  return BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(18),
  );
}
