import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00408b),
      surfaceTint: Color(0xff0d5bbc),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff0057b8),
      onPrimaryContainer: Color(0xffbfd2ff),
      secondary: Color(0xffae2f34),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffff6b6b),
      onSecondaryContainer: Color(0xff6d0010),
      tertiary: Color(0xff006d43),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff00a86b),
      onTertiaryContainer: Color(0xff00331d),
      error: Color(0xffa30000),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffd10000),
      onErrorContainer: Color(0xffffdfda),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff1c1b1b),
      onSurfaceVariant: Color(0xff444748),
      outline: Color(0xff747878),
      outlineVariant: Color(0xffc4c7c8),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffadc7ff),
      primaryFixed: Color(0xffd8e2ff),
      onPrimaryFixed: Color(0xff001a41),
      primaryFixedDim: Color(0xffadc7ff),
      onPrimaryFixedVariant: Color(0xff004493),
      secondaryFixed: Color(0xffffdad8),
      onSecondaryFixed: Color(0xff410006),
      secondaryFixedDim: Color(0xffffb3b0),
      onSecondaryFixedVariant: Color(0xff8c1520),
      tertiaryFixed: Color(0xff78fbb6),
      onTertiaryFixed: Color(0xff002111),
      tertiaryFixedDim: Color(0xff59de9b),
      onTertiaryFixedVariant: Color(0xff005232),
      surfaceDim: Color(0xffddd9d9),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f3f2),
      surfaceContainer: Color(0xfff1edec),
      surfaceContainerHigh: Color(0xffebe7e7),
      surfaceContainerHighest: Color(0xffe5e2e1),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003473),
      surfaceTint: Color(0xff0d5bbc),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff0057b8),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff730012),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffc23e41),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff003f25),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff007d4e),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740000),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffd10000),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff111111),
      onSurfaceVariant: Color(0xff333738),
      outline: Color(0xff4f5354),
      outlineVariant: Color(0xff6a6e6e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffadc7ff),
      primaryFixed: Color(0xff2a6bcc),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff0052ad),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xffc23e41),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xffa0252c),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff007d4e),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff00623c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc9c6c5),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f3f2),
      surfaceContainer: Color(0xffebe7e7),
      surfaceContainerHigh: Color(0xffdfdcdb),
      surfaceContainerHighest: Color(0xffd4d1d0),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff002a60),
      surfaceTint: Color(0xff0d5bbc),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff004697),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff60000d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff901822),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff00341e),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff005533),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff610000),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff980000),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff292d2d),
      outlineVariant: Color(0xff464a4a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffadc7ff),
      primaryFixed: Color(0xff004697),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff00316c),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff901822),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff6c0010),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff005533),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff003b23),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbbb8b7),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff4f0ef),
      surfaceContainer: Color(0xffe5e2e1),
      surfaceContainerHigh: Color(0xffd7d4d3),
      surfaceContainerHighest: Color(0xffc9c6c5),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffadc7ff),
      surfaceTint: Color(0xffadc7ff),
      onPrimary: Color(0xff002e68),
      primaryContainer: Color(0xff0057b8),
      onPrimaryContainer: Color(0xffbfd2ff),
      secondary: Color(0xffffb3b0),
      onSecondary: Color(0xff68000f),
      secondaryContainer: Color(0xffff6b6b),
      onSecondaryContainer: Color(0xff6d0010),
      tertiary: Color(0xff59de9b),
      onTertiary: Color(0xff003921),
      tertiaryContainer: Color(0xff00a86b),
      onTertiaryContainer: Color(0xff00331d),
      error: Color(0xffffb4a8),
      onError: Color(0xff690000),
      errorContainer: Color(0xffd10000),
      onErrorContainer: Color(0xffffdfda),
      surface: Color(0xff141313),
      onSurface: Color(0xffe5e2e1),
      onSurfaceVariant: Color(0xffc4c7c8),
      outline: Color(0xff8e9192),
      outlineVariant: Color(0xff444748),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff0d5bbc),
      primaryFixed: Color(0xffd8e2ff),
      onPrimaryFixed: Color(0xff001a41),
      primaryFixedDim: Color(0xffadc7ff),
      onPrimaryFixedVariant: Color(0xff004493),
      secondaryFixed: Color(0xffffdad8),
      onSecondaryFixed: Color(0xff410006),
      secondaryFixedDim: Color(0xffffb3b0),
      onSecondaryFixedVariant: Color(0xff8c1520),
      tertiaryFixed: Color(0xff78fbb6),
      onTertiaryFixed: Color(0xff002111),
      tertiaryFixedDim: Color(0xff59de9b),
      onTertiaryFixedVariant: Color(0xff005232),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff3a3939),
      surfaceContainerLowest: Color(0xff0e0e0e),
      surfaceContainerLow: Color(0xff1c1b1b),
      surfaceContainer: Color(0xff201f1f),
      surfaceContainerHigh: Color(0xff2a2a2a),
      surfaceContainerHighest: Color(0xff353434),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffcedcff),
      surfaceTint: Color(0xffadc7ff),
      onPrimary: Color(0xff002454),
      primaryContainer: Color(0xff568ff3),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffffd2cf),
      onSecondary: Color(0xff54000a),
      secondaryContainer: Color(0xffff6b6b),
      onSecondaryContainer: Color(0xff230002),
      tertiary: Color(0xff71f5b0),
      onTertiary: Color(0xff002c19),
      tertiaryContainer: Color(0xff00a86b),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cb),
      onError: Color(0xff540000),
      errorContainer: Color(0xffff5541),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff141313),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdadddd),
      outline: Color(0xffafb2b3),
      outlineVariant: Color(0xff8d9191),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff004595),
      primaryFixed: Color(0xffd8e2ff),
      onPrimaryFixed: Color(0xff00102d),
      primaryFixedDim: Color(0xffadc7ff),
      onPrimaryFixedVariant: Color(0xff003473),
      secondaryFixed: Color(0xffffdad8),
      onSecondaryFixed: Color(0xff2d0003),
      secondaryFixedDim: Color(0xffffb3b0),
      onSecondaryFixedVariant: Color(0xff730012),
      tertiaryFixed: Color(0xff78fbb6),
      onTertiaryFixed: Color(0xff001509),
      tertiaryFixedDim: Color(0xff59de9b),
      onTertiaryFixedVariant: Color(0xff003f25),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff454444),
      surfaceContainerLowest: Color(0xff070707),
      surfaceContainerLow: Color(0xff1e1d1d),
      surfaceContainer: Color(0xff282828),
      surfaceContainerHigh: Color(0xff333232),
      surfaceContainerHighest: Color(0xff3e3d3d),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffecefff),
      surfaceTint: Color(0xffadc7ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffa6c3ff),
      onPrimaryContainer: Color(0xff000a22),
      secondary: Color(0xffffecea),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffffadaa),
      onSecondaryContainer: Color(0xff220002),
      tertiary: Color(0xffbcffd5),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff55da98),
      onTertiaryContainer: Color(0xff000e06),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea1),
      onErrorContainer: Color(0xff220000),
      surface: Color(0xff141313),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffeef0f1),
      outlineVariant: Color(0xffc0c3c4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff004595),
      primaryFixed: Color(0xffd8e2ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffadc7ff),
      onPrimaryFixedVariant: Color(0xff00102d),
      secondaryFixed: Color(0xffffdad8),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffffb3b0),
      onSecondaryFixedVariant: Color(0xff2d0003),
      tertiaryFixed: Color(0xff78fbb6),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xff59de9b),
      onTertiaryFixedVariant: Color(0xff001509),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff51504f),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff201f1f),
      surfaceContainer: Color(0xff313030),
      surfaceContainerHigh: Color(0xff3c3b3b),
      surfaceContainerHighest: Color(0xff474646),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
