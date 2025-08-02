import 'package:flutter/material.dart';

class AppColors {
  // Paleta de colores principal
  static const Color darkBrown = Color(0xFF140f07);    // .color1
  static const Color darkNavy = Color(0xFF102941);     // .color2
  static const Color mediumBlue = Color(0xFF1968a1);   // .color3
  static const Color lightBlue = Color(0xFF29b1ff);    // .color4
  static const Color cyan = Color(0xFF39fff9);         // .color5
  
  // Colores adicionales
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  static const Color success = Color(0xFF4CAF50); // Verde para éxito
  static const Color successLight = Color(0xFF81C784); // Verde claro
  static const Color error = Color(0xFFE53E3E); // Rojo para errores
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkNavy, mediumBlue],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mediumBlue, lightBlue],
  );
  
  // Colores con opacidad
  static Color blackWithOpacity(double opacity) => black.withOpacity(opacity);
  static Color whiteWithOpacity(double opacity) => white.withOpacity(opacity);
  static Color darkNavyWithOpacity(double opacity) => darkNavy.withOpacity(opacity);
}
