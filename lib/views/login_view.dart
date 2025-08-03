import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/responsive_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Verificar sesión existente al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginViewModel>().checkExistingSession();
    });
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final loginViewModel = context.read<LoginViewModel>();
      final success = await loginViewModel.loginDemo();
      
      if (success && loginViewModel.currentUser != null) {
        // Navegar al dashboard después del login exitoso
        if (mounted) {
          Navigator.pushReplacementNamed(
            context, 
            '/dashboard',
            arguments: loginViewModel.currentUser,
          );
        }
      }
      // El mensaje de error se mostrará automáticamente en la vista si falla
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Consumer<LoginViewModel>(
        builder: (context, loginViewModel, child) {
          return LoadingOverlay(
            isLoading: loginViewModel.isLoading,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          mobile: EdgeInsets.all(AppDimensions.paddingLg),
                          tablet: EdgeInsets.all(AppDimensions.paddingXl),
                          desktop: EdgeInsets.all(AppDimensions.paddingXl * 2),
                        ),
                        child: _buildLoginForm(context, loginViewModel),
                      ),
                    ),
                    
                    // Marca de agua en la parte inferior
                    _buildWatermark(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginViewModel loginViewModel) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(
            context,
            mobile: 60,
            tablet: 80,
            desktop: 100,
          )),
          
          // Logo de la aplicación
          _buildLogo(context),
          
          SizedBox(height: AppDimensions.marginXl),
          
          // Título
          _buildTitle(context),
          
          SizedBox(height: AppDimensions.marginSm),
          
          // Subtítulo
          _buildSubtitle(context),
          
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(
            context,
            mobile: 50,
            tablet: 60,
            desktop: 70,
          )),
          
          // Campos del formulario
          _buildFormFields(context, loginViewModel),
          
          SizedBox(height: AppDimensions.marginXl),
          
          // Botón de login
          _buildLoginButton(context, loginViewModel),
          
          // Mensaje de error
          if (loginViewModel.errorMessage != null)
            _buildErrorMessage(context, loginViewModel.errorMessage!),
          
          // Mensaje de éxito
          if (loginViewModel.successMessage != null)
            _buildSuccessMessage(context, loginViewModel.successMessage!),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final logoSize = ResponsiveHelper.getResponsiveWidth(
      context,
      mobile: 120,
      tablet: 150,
      desktop: 180,
    );

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackWithOpacity(0.2),
            blurRadius: AppDimensions.elevationLg,
            offset: Offset(0, AppDimensions.xs),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Image.asset(
          'assets/images/icono.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.water_drop,
              size: logoSize * 0.5,
              color: AppColors.lightBlue,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'Distribuidor de Agua',
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(
          context,
          mobile: 28,
          tablet: 32,
          desktop: 36,
        ),
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'Gestión de Ventas',
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(
          context,
          mobile: 16,
          tablet: 18,
          desktop: 20,
        ),
        color: AppColors.cyan,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFormFields(BuildContext context, LoginViewModel loginViewModel) {
    return Column(
      children: [
        // Campo Usuario
        CustomTextField(
          controller: loginViewModel.usuarioController,
          labelText: 'Usuario',
          prefixIcon: Icons.person,
          validator: loginViewModel.validateUsuario,
          onChanged: (_) => loginViewModel.clearMessages(),
        ),
        
        SizedBox(height: AppDimensions.marginLg),
        
        // Campo Contraseña
        CustomTextField(
          controller: loginViewModel.passwordController,
          labelText: 'Contraseña',
          prefixIcon: Icons.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: loginViewModel.validatePassword,
          onChanged: (_) => loginViewModel.clearMessages(),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, LoginViewModel loginViewModel) {
    return CustomButton(
      text: 'Iniciar Sesión',
      onPressed: loginViewModel.isLoading ? null : _handleLogin,
      isLoading: loginViewModel.isLoading,
      width: double.infinity,
    );
  }

  Widget _buildErrorMessage(BuildContext context, String errorMessage) {
    return Container(
      margin: EdgeInsets.only(top: AppDimensions.marginLg),
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppDimensions.iconMd,
          ),
          SizedBox(width: AppDimensions.marginSm),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: AppColors.error,
                fontSize: AppDimensions.textMd,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context, String successMessage) {
    return Container(
      margin: EdgeInsets.only(top: AppDimensions.marginLg),
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: AppDimensions.iconMd,
          ),
          SizedBox(width: AppDimensions.marginSm),
          Expanded(
            child: Text(
              successMessage,
              style: TextStyle(
                color: AppColors.success,
                fontSize: AppDimensions.textMd,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermark(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.paddingLg),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMd,
              vertical: AppDimensions.paddingSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.blackWithOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            ),
            child: Text(
              'Desarrollado por: Adrián Tasayco',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: AppDimensions.marginXs),
          Text(
            '© Arch Adrian. Todos los derechos reservados.',
            style: TextStyle(
              color: AppColors.whiteWithOpacity(0.7),
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 10,
                tablet: 12,
                desktop: 14,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
