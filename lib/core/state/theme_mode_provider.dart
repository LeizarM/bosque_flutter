
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isDarkModeProvider = StateProvider<bool>((ref) => false);

//Lista de colores inmutable

final colorListProvider = Provider( (ref)=> colorList );


final selectedColorProvider = StateProvider( (ref) => 0  );



// un objeto de tipo AppTheme

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, AppTheme>( 
  (ref) =>  ThemeNotifier(), 
 );



class ThemeNotifier extends StateNotifier<AppTheme> {
  
  ThemeNotifier(): super( AppTheme() );

  void toggleDarkMode() {
    
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    


  }

  void changeColorIndex(int colorIndex){

      state = state.copyWith(selectedColor: colorIndex);
  }


}