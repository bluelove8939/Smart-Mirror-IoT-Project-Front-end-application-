import 'package:flutter/material.dart';


Map<String, ColorScheme> colorSchemePresets = {
  'red': redColorScheme,
  'yellow': yellowColorScheme,
  'light': whiteColorScheme,
  'dark': blackColorScheme,
};


String translateColorName(localizationDelegate, colorName) {
  assert(colorSchemePresets.containsKey(colorName) == true);

  switch (colorName) {
    case 'red':
      return localizationDelegate.red;
    case 'yellow':
      return localizationDelegate.yellow;
    case 'light':
      return localizationDelegate.light;
    case 'dark':
      return localizationDelegate.dark;
    default:
      return localizationDelegate.red;
  }
}


const ColorScheme redColorScheme = ColorScheme(
  background: Colors.redAccent,  // background color
  brightness: Brightness.light,
  error: Colors.red,
  primary: Colors.redAccent,  // primary background color
  secondary: Colors.redAccent,
  surface: Colors.white,  // dashboard card widget background
  tertiary: Colors.white,  // contrast to primary

  onBackground: Colors.white,
  onError: Colors.red,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.black,
);

const ColorScheme yellowColorScheme = ColorScheme(
  background: Color.fromRGBO(255, 250, 168, 1),  // background color
  brightness: Brightness.light,
  error: Colors.red,
  primary: Color.fromRGBO(255, 250, 168, 1),  // primary background color
  secondary: Color.fromRGBO(255, 250, 168, 1),
  surface: Colors.white,  // dashboard card widget background
  tertiary: Colors.black,  // contrast to primary

  onBackground: Colors.white,
  onError: Colors.red,
  onPrimary: Colors.black,
  onSecondary: Colors.black,
  onSurface: Colors.black,
);

const ColorScheme whiteColorScheme = ColorScheme(
  background: Colors.white,  // background color
  brightness: Brightness.light,
  error: Colors.red,
  primary: Colors.white,  // primary background color
  secondary: Colors.white,
  surface: Color.fromRGBO(230, 230, 230, 1),  // dashboard card widget background
  tertiary: Colors.black,  // contrast to primary

  onBackground: Colors.white,
  onError: Colors.red,
  onPrimary: Colors.black,
  onSecondary: Colors.black,
  onSurface: Colors.black,
);

const ColorScheme blackColorScheme = ColorScheme(
  background: Color.fromRGBO(30, 30, 30, 1),  // background color
  brightness: Brightness.light,
  error: Colors.red,
  primary: Color.fromRGBO(30, 30, 30, 1),  // primary background color
  secondary: Color.fromRGBO(30, 30, 30, 1),
  surface: Color.fromRGBO(179, 179, 179, 1),  // dashboard card widget background
  tertiary: Colors.white,  // contrast to primary

  onBackground: Colors.white,
  onError: Colors.red,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.black,
);