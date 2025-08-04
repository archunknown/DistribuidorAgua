import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/cliente_model.dart';

class AutocompleteTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final List<ClienteModel> suggestions;
  final Function(String) onChanged;
  final Function(ClienteModel) onSuggestionSelected;
  final Function()? onAddPressed;
  final ClienteModel? selectedClient;
  final bool isLoading;

  const AutocompleteTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    required this.suggestions,
    required this.onChanged,
    required this.onSuggestionSelected,
    this.onAddPressed,
    this.selectedClient,
    this.isLoading = false,
  });

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.suggestions.isNotEmpty) {
      _showSuggestionsOverlay();
    } else {
      _hideSuggestionsOverlay();
    }
  }

  void _showSuggestionsOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideSuggestionsOverlay() {
    if (_overlayEntry == null) return;

    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 200.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.suggestions.isEmpty
                    ? _buildNoResultsWidget()
                    : _buildSuggestionsList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      child: Row(
        children: [
          Icon(
            Icons.search_off,
            color: AppColors.darkBrown.withOpacity(0.5),
            size: AppDimensions.iconMd,
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No se encontraron clientes',
                  style: TextStyle(
                    fontSize: AppDimensions.textMd,
                    color: AppColors.darkBrown.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.onAddPressed != null) ...[
                  SizedBox(height: AppDimensions.marginSm),
                  GestureDetector(
                    onTap: () {
                      _hideSuggestionsOverlay();
                      widget.onAddPressed!();
                    },
                    child: Text(
                      'Toca aquí para crear un nuevo cliente',
                      style: TextStyle(
                        fontSize: AppDimensions.textSm,
                        color: AppColors.lightBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: widget.suggestions.length,
      itemBuilder: (context, index) {
        final cliente = widget.suggestions[index];
        final isSelected = widget.selectedClient?.id == cliente.id;
        
        return InkWell(
          onTap: () {
            widget.onSuggestionSelected(cliente);
            _hideSuggestionsOverlay();
            _focusNode.unfocus();
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMd,
              vertical: AppDimensions.paddingSm,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.lightBlue.withOpacity(0.1)
                  : Colors.transparent,
              border: index < widget.suggestions.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: AppColors.darkNavy.withOpacity(0.1),
                        width: 0.5,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: isSelected 
                      ? AppColors.lightBlue 
                      : AppColors.lightBlue.withOpacity(0.7),
                  child: Text(
                    cliente.iniciales,
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.textSm,
                    ),
                  ),
                ),
                SizedBox(width: AppDimensions.marginMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombreCompleto,
                        style: TextStyle(
                          fontSize: AppDimensions.textMd,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? AppColors.lightBlue 
                              : AppColors.darkBrown,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${cliente.distrito} • ${cliente.referencia}',
                        style: TextStyle(
                          fontSize: AppDimensions.textSm,
                          color: AppColors.darkBrown.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cliente.telefono != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          cliente.telefono!,
                          style: TextStyle(
                            fontSize: AppDimensions.textXs,
                            color: AppColors.mediumBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.lightBlue,
                    size: AppDimensions.iconSm,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: (value) {
          widget.onChanged(value);
          
          // Mostrar/ocultar sugerencias basado en el contenido
          if (value.isNotEmpty && widget.suggestions.isNotEmpty) {
            if (_overlayEntry == null) {
              _showSuggestionsOverlay();
            }
          } else {
            _hideSuggestionsOverlay();
          }
        },
        decoration: InputDecoration(
          labelText: widget.labelText,
          prefixIcon: Icon(widget.prefixIcon),
          suffixIcon: _buildSuffixIcon(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(color: AppColors.darkNavy.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(color: AppColors.darkNavy.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(color: AppColors.lightBlue, width: 2),
          ),
          filled: true,
          fillColor: widget.selectedClient != null 
              ? AppColors.success.withOpacity(0.05)
              : AppColors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd,
            vertical: AppDimensions.paddingMd,
          ),
        ),
        style: TextStyle(
          fontSize: AppDimensions.textMd,
          color: AppColors.darkBrown,
        ),
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (widget.isLoading) {
      return Padding(
        padding: EdgeInsets.all(AppDimensions.paddingSm),
        child: SizedBox(
          width: 20.w,
          height: 20.h,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightBlue),
          ),
        ),
      );
    }

    if (widget.selectedClient != null) {
      return Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: AppDimensions.iconMd,
      );
    }

    if (widget.onAddPressed != null) {
      return IconButton(
        icon: Icon(
          Icons.person_add,
          color: AppColors.lightBlue,
          size: AppDimensions.iconMd,
        ),
        onPressed: widget.onAddPressed,
        tooltip: 'Agregar nuevo cliente',
      );
    }

    return const SizedBox.shrink();
  }
}
