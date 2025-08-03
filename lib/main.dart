import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'constants/app_dimensions.dart';
import 'models/user_model.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/nueva_venta_viewmodel.dart';
import 'views/login_view.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LoginViewModel()),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
          ],
          child: MaterialApp(
            title: 'Distribuidor de Agua',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginView(),
              '/login': (context) => const LoginView(),
              '/dashboard': (context) {
                final UserModel usuario = ModalRoute.of(context)!.settings.arguments as UserModel;
                return DashboardScreen(usuario: usuario);
              },
            },
          ),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      // Paleta de colores personalizada usando nuestras constantes
      primarySwatch: Colors.blue,
      primaryColor: AppColors.mediumBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.mediumBlue,
        secondary: AppColors.lightBlue,
        surface: AppColors.white,
        background: AppColors.darkNavy,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.darkBrown,
        onBackground: AppColors.white,
      ),
      
      // Configuración de AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkNavy,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: AppDimensions.textXl,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
      
      // Configuración de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.lightBlue.withOpacity(0.5),
          disabledForegroundColor: AppColors.white.withOpacity(0.7),
          elevation: AppDimensions.elevationMd,
          shadowColor: AppColors.blackWithOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLg,
            vertical: AppDimensions.paddingMd,
          ),
          textStyle: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Configuración de botones outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightBlue,
          disabledForegroundColor: AppColors.lightBlue.withOpacity(0.5),
          side: BorderSide(
            color: AppColors.lightBlue,
            width: 2.w,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLg,
            vertical: AppDimensions.paddingMd,
          ),
          textStyle: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Configuración de botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightBlue,
          disabledForegroundColor: AppColors.lightBlue.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd,
            vertical: AppDimensions.paddingSm,
          ),
          textStyle: TextStyle(
            fontSize: AppDimensions.textMd,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Configuración de campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: AppColors.lightBlue,
            width: 2.w,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: Colors.red,
            width: 2.w,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: Colors.red,
            width: 2.w,
          ),
        ),
        labelStyle: TextStyle(
          color: AppColors.mediumBlue,
          fontSize: AppDimensions.textMd,
        ),
        hintStyle: TextStyle(
          color: AppColors.darkBrown.withOpacity(0.5),
          fontSize: AppDimensions.textMd,
        ),
        errorStyle: TextStyle(
          color: Colors.red,
          fontSize: AppDimensions.textSm,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingMd,
        ),
      ),
      
      // Configuración de iconos
      iconTheme: IconThemeData(
        color: AppColors.mediumBlue,
        size: AppDimensions.iconMd,
      ),
      
      // Configuración de texto
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.darkBrown,
          fontSize: AppDimensions.textHeading,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.darkBrown,
          fontSize: AppDimensions.textTitle,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.darkBrown,
          fontSize: AppDimensions.textXl,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.darkBrown,
          fontSize: AppDimensions.textLg,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.darkBrown,
          fontSize: AppDimensions.textLg,
        ),
        bodyMedium: TextStyle(
          color: AppColors.darkBrown,
          fontSize: AppDimensions.textMd,
        ),
        bodySmall: TextStyle(
          color: AppColors.darkBrown,
          fontSize: AppDimensions.textSm,
        ),
        labelLarge: TextStyle(
          color: AppColors.mediumBlue,
          fontSize: AppDimensions.textMd,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Configuración de cards
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: AppDimensions.elevationSm,
        shadowColor: AppColors.blackWithOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        margin: EdgeInsets.all(AppDimensions.marginSm),
      ),
      
      // Configuración de dividers
      dividerTheme: DividerThemeData(
        color: AppColors.darkBrown.withOpacity(0.1),
        thickness: 1.w,
        space: AppDimensions.marginMd,
      ),
      
      // Configuración de snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.mediumBlue,
        contentTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: AppDimensions.textMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
