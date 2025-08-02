import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            color: AppColors.darkBrown,
          ),
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: AppColors.mediumBlue,
                    size: AppDimensions.iconMd,
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.white,
            
            // Border normal
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide.none,
            ),
            
            // Border cuando está enfocado
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: AppColors.lightBlue,
                width: 2.w,
              ),
            ),
            
            // Border cuando hay error
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2.w,
              ),
            ),
            
            // Border cuando está enfocado y hay error
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2.w,
              ),
            ),
            
            // Border cuando está deshabilitado
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide.none,
            ),
            
            // Estilo del label
            labelStyle: TextStyle(
              color: AppColors.mediumBlue,
              fontSize: AppDimensions.textMd,
            ),
            
            // Estilo del label flotante
            floatingLabelStyle: TextStyle(
              color: AppColors.mediumBlue,
              fontSize: AppDimensions.textSm,
            ),
            
            // Estilo del hint
            hintStyle: TextStyle(
              color: AppColors.darkBrown.withOpacity(0.5),
              fontSize: AppDimensions.textMd,
            ),
            
            // Comportamiento del label
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            
            // Estilo del texto de error
            errorStyle: TextStyle(
              color: Colors.red,
              fontSize: AppDimensions.textSm,
            ),
            
            // Padding interno
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMd,
              vertical: AppDimensions.paddingMd,
            ),
            
            // Counter style para maxLength
            counterStyle: TextStyle(
              color: AppColors.mediumBlue,
              fontSize: AppDimensions.textSm,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget especializado para campos de búsqueda
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;

  const SearchTextField({
    super.key,
    required this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: '',
      hintText: hintText,
      prefixIcon: Icons.search,
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(
                Icons.clear,
                color: AppColors.mediumBlue,
                size: AppDimensions.iconMd,
              ),
              onPressed: () {
                controller.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
    );
  }
}

// Widget especializado para campos numéricos
class NumericTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool allowDecimals;
  final double? min;
  final double? max;

  const NumericTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.onChanged,
    this.allowDecimals = false,
    this.min,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      keyboardType: allowDecimals
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      validator: validator ?? _defaultValidator,
      onChanged: onChanged,
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }

    final number = allowDecimals ? double.tryParse(value) : int.tryParse(value);
    if (number == null) {
      return allowDecimals
          ? 'Ingrese un número válido'
          : 'Ingrese un número entero válido';
    }

    if (min != null && number < min!) {
      return 'El valor debe ser mayor o igual a $min';
    }

    if (max != null && number > max!) {
      return 'El valor debe ser menor o igual a $max';
    }

    return null;
  }
}
