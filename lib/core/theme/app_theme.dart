// ignore_for_file: file_names

import 'package:flutter/material.dart';

const colorList = <Color>[
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.red,
  Colors.purple,
  Colors.yellow,
  Colors.orange,
  Colors.deepPurple,
  Colors.pink,
];

class AppTheme {
  final int selectedColor;
  final bool isDarkMode;

  AppTheme({this.isDarkMode = false , this.selectedColor = 3})
    : assert(
        selectedColor >= 0,
        'selectedColor must be greater than or equal to 0',
      ),
      assert(
        selectedColor < colorList.length,
        'selectedColor must be less or equal to ${colorList.length - 1}',
      );

  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorSchemeSeed: colorList[selectedColor],
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }


  AppTheme copyWith(
    {
      bool? isDarkMode,
      int? selectedColor,
    }
  ) => AppTheme(
      isDarkMode: isDarkMode?? this.isDarkMode,
      selectedColor: selectedColor?? this.selectedColor,
  
  );

  


}