// ============================================================================
// 📝 CAMPO DE TEXTO ESTÁNDAR CENTRALIZADO
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

enum AppTextFieldType {
  text,
  email,
  password,
  number,
  phone,
  multiline,
  search,
  url,
}

enum AppTextFieldSize {
  small,
  medium,
  large,
}

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? initialValue;
  final TextEditingController? controller;
  final AppTextFieldType type;
  final AppTextFieldSize size;
  final bool isRequired;
  final bool isDisabled;
  final bool isReadOnly;
  final bool showCounter;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onSuffixIconTap;
  final VoidCallback? onPrefixIconTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final Function()? onEditingComplete;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool obscureText;
  final bool canToggleObscureText;
  final EdgeInsets? customPadding;
  final BorderRadius? customBorderRadius;
  final Color? customBorderColor;
  final Color? customFillColor;
  final TextStyle? customTextStyle;
  final TextStyle? customLabelStyle;
  final TextStyle? customHintStyle;
  final double? customHeight;
  final bool filled;
  final bool dense;
  final String? semanticsLabel;
  final bool autofocus;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final TextAlign textAlign;
  final bool enableInteractiveSelection;
  final bool showCursor;
  final double? cursorWidth;
  final double? cursorHeight;
  final Color? cursorColor;
  final Radius? cursorRadius;
  final ScrollController? scrollController;
  final EdgeInsets scrollPadding;
  final String? restorationId;
  final bool scribbleEnabled;
  final bool enableIMEPersonalizedLearning;
  final Key? key;

  const AppTextField({
    this.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.controller,
    this.type = AppTextFieldType.text,
    this.size = AppTextFieldSize.medium,
    this.isRequired = false,
    this.isDisabled = false,
    this.isReadOnly = false,
    this.showCounter = false,
    this.maxLength,
    this.maxLines,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onSuffixIconTap,
    this.onPrefixIconTap,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.focusNode,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.obscureText = false,
    this.canToggleObscureText = false,
    this.customPadding,
    this.customBorderRadius,
    this.customBorderColor,
    this.customFillColor,
    this.customTextStyle,
    this.customLabelStyle,
    this.customHintStyle,
    this.customHeight,
    this.filled = true,
    this.dense = false,
    this.semanticsLabel,
    this.autofocus = false,
    this.expands = false,
    this.textAlignVertical,
    this.textAlign = TextAlign.start,
    this.enableInteractiveSelection = true,
    this.showCursor = true,
    this.cursorWidth,
    this.cursorHeight,
    this.cursorColor,
    this.cursorRadius,
    this.scrollController,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.restorationId,
    this.scribbleEnabled = true,
    this.enableIMEPersonalizedLearning = true,
  }) : super(key: key);

  // Factory constructors para tipos específicos
  factory AppTextField.email({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    String? initialValue,
    TextEditingController? controller,
    AppTextFieldSize size = AppTextFieldSize.medium,
    bool isRequired = false,
    bool isDisabled = false,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint ?? 'Ingresa tu email',
      errorText: errorText,
      initialValue: initialValue,
      controller: controller,
      type: AppTextFieldType.email,
      size: size,
      isRequired: isRequired,
      isDisabled: isDisabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      prefixIcon: Icons.email_outlined,
    );
  }

  factory AppTextField.password({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    String? initialValue,
    TextEditingController? controller,
    AppTextFieldSize size = AppTextFieldSize.medium,
    bool isRequired = false,
    bool isDisabled = false,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    bool canToggleObscureText = true,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint ?? 'Ingresa tu contraseña',
      errorText: errorText,
      initialValue: initialValue,
      controller: controller,
      type: AppTextFieldType.password,
      size: size,
      isRequired: isRequired,
      isDisabled: isDisabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      prefixIcon: Icons.lock_outlined,
      obscureText: true,
      canToggleObscureText: canToggleObscureText,
    );
  }

  factory AppTextField.search({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    String? initialValue,
    TextEditingController? controller,
    AppTextFieldSize size = AppTextFieldSize.medium,
    bool isDisabled = false,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onSuffixIconTap,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint ?? 'Buscar...',
      errorText: errorText,
      initialValue: initialValue,
      controller: controller,
      type: AppTextFieldType.search,
      size: size,
      isDisabled: isDisabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onSuffixIconTap: onSuffixIconTap,
      focusNode: focusNode,
      textInputAction: textInputAction ?? TextInputAction.search,
      prefixIcon: Icons.search,
      suffixIcon: Icons.close,
    );
  }

  factory AppTextField.multiline({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    String? initialValue,
    TextEditingController? controller,
    AppTextFieldSize size = AppTextFieldSize.medium,
    bool isRequired = false,
    bool isDisabled = false,
    int? maxLines,
    int? minLines,
    int? maxLength,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint,
      errorText: errorText,
      initialValue: initialValue,
      controller: controller,
      type: AppTextFieldType.multiline,
      size: size,
      isRequired: isRequired,
      isDisabled: isDisabled,
      maxLines: maxLines ?? 4,
      minLines: minLines ?? 2,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction ?? TextInputAction.newline,
      textAlignVertical: TextAlignVertical.top,
    );
  }

  factory AppTextField.number({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    String? initialValue,
    TextEditingController? controller,
    AppTextFieldSize size = AppTextFieldSize.medium,
    bool isRequired = false,
    bool isDisabled = false,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint,
      errorText: errorText,
      initialValue: initialValue,
      controller: controller,
      type: AppTextFieldType.number,
      size: size,
      isRequired: isRequired,
      isDisabled: isDisabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      prefixIcon: Icons.numbers,
    );
  }

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();
    final decoration = _getInputDecoration(dimensions);
    final textStyle = _getTextStyle();
    final keyboardType = _getKeyboardType();
    final inputFormatters = _getInputFormatters();

    Widget textField = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: !widget.isDisabled,
      readOnly: widget.isReadOnly,
      obscureText: _obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      keyboardType: keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      maxLength: widget.maxLength,
      maxLines: widget.type == AppTextFieldType.multiline ? widget.maxLines : 1,
      minLines: widget.type == AppTextFieldType.multiline ? widget.minLines : null,
      expands: widget.expands,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      style: textStyle,
      decoration: decoration,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onEditingComplete: widget.onEditingComplete,
      inputFormatters: inputFormatters,
      autofocus: widget.autofocus,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      showCursor: widget.showCursor,
      cursorWidth: widget.cursorWidth ?? 2.0,
      cursorHeight: widget.cursorHeight,
      cursorColor: widget.cursorColor ?? AppColors.primary,
      cursorRadius: widget.cursorRadius,
      scrollController: widget.scrollController,
      scrollPadding: widget.scrollPadding,
      restorationId: widget.restorationId,
      scribbleEnabled: widget.scribbleEnabled,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
    );

    if (widget.semanticsLabel != null) {
      textField = Semantics(
        label: widget.semanticsLabel!,
        textField: true,
        child: textField,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          _buildLabel(),
          SizedBox(height: DesignTokens.spaceXS),
        ],
        textField,
        if (widget.helperText != null && widget.errorText == null) ...[
          SizedBox(height: DesignTokens.spaceXS),
          _buildHelperText(),
        ],
      ],
    );
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label!,
        style: widget.customLabelStyle ?? TextStyle(
          fontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightMedium,
          color: AppColors.textPrimary,
        ),
        children: [
          if (widget.isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHelperText() {
    return Text(
      widget.helperText!,
      style: TextStyle(
        fontSize: DesignTokens.fontSizeXS,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _getInputDecoration(_TextFieldDimensions dimensions) {
    final hasError = widget.errorText != null;
    final borderColor = hasError 
        ? AppColors.error 
        : _hasFocus 
            ? AppColors.primary 
            : widget.customBorderColor ?? AppColors.textSecondary.withValues(alpha: 0.3);

    return InputDecoration(
      hintText: widget.hint,
      hintStyle: widget.customHintStyle ?? TextStyle(
        fontSize: dimensions.fontSize,
        color: AppColors.textSecondary,
      ),
      errorText: widget.errorText,
      errorStyle: TextStyle(
        fontSize: DesignTokens.fontSizeXS,
        color: AppColors.error,
      ),
      prefixIcon: _buildPrefixIcon(),
      suffixIcon: _buildSuffixIcon(),
      prefix: widget.prefix,
      suffix: widget.suffix,
      filled: widget.filled,
      fillColor: widget.customFillColor ?? (widget.isDisabled 
          ? AppColors.backgroundLight 
          : Colors.white),
      contentPadding: widget.customPadding ?? dimensions.padding,
      border: _buildBorder(borderColor),
      enabledBorder: _buildBorder(borderColor),
      focusedBorder: _buildBorder(AppColors.primary),
      errorBorder: _buildBorder(AppColors.error),
      focusedErrorBorder: _buildBorder(AppColors.error),
      disabledBorder: _buildBorder(AppColors.textSecondary.withValues(alpha: 0.2)),
      counterText: widget.showCounter ? null : '',
      isDense: widget.dense,
    );
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefixIcon == null) return null;
    
    return GestureDetector(
      onTap: widget.onPrefixIconTap,
      child: Icon(
        widget.prefixIcon,
        color: _hasFocus ? AppColors.primary : AppColors.textSecondary,
        size: _getDimensions().iconSize,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.canToggleObscureText && widget.type == AppTextFieldType.password) {
      return GestureDetector(
        onTap: _toggleObscureText,
        child: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
          size: _getDimensions().iconSize,
        ),
      );
    }
    
    if (widget.suffixIcon == null) return null;
    
    return GestureDetector(
      onTap: widget.onSuffixIconTap,
      child: Icon(
        widget.suffixIcon,
        color: _hasFocus ? AppColors.primary : AppColors.textSecondary,
        size: _getDimensions().iconSize,
      ),
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: widget.customBorderRadius ?? BorderRadius.circular(DesignTokens.radiusInput),
      borderSide: BorderSide(
        color: color,
        width: _hasFocus ? DesignTokens.borderWidthInputFocused : DesignTokens.borderWidthInput,
      ),
    );
  }

  TextStyle _getTextStyle() {
    if (widget.customTextStyle != null) {
      return widget.customTextStyle!;
    }
    
    final dimensions = _getDimensions();
    return TextStyle(
      fontSize: dimensions.fontSize,
      fontWeight: DesignTokens.fontWeightRegular,
      color: widget.isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
    );
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case AppTextFieldType.email:
        return TextInputType.emailAddress;
      case AppTextFieldType.password:
        return TextInputType.visiblePassword;
      case AppTextFieldType.number:
        return TextInputType.number;
      case AppTextFieldType.phone:
        return TextInputType.phone;
      case AppTextFieldType.multiline:
        return TextInputType.multiline;
      case AppTextFieldType.url:
        return TextInputType.url;
      case AppTextFieldType.search:
      case AppTextFieldType.text:
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? _getInputFormatters() {
    if (widget.inputFormatters != null) {
      return widget.inputFormatters;
    }
    
    switch (widget.type) {
      case AppTextFieldType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case AppTextFieldType.phone:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15),
        ];
      default:
        return null;
    }
  }

  _TextFieldDimensions _getDimensions() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return _TextFieldDimensions(
          height: DesignTokens.inputHeightS,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          fontSize: DesignTokens.fontSizeS,
          iconSize: DesignTokens.iconS,
        );
      case AppTextFieldSize.medium:
        return _TextFieldDimensions(
          height: DesignTokens.inputHeightM,
          padding: DesignTokens.inputPadding,
          fontSize: DesignTokens.fontSizeRegular,
          iconSize: DesignTokens.iconM,
        );
      case AppTextFieldSize.large:
        return _TextFieldDimensions(
          height: DesignTokens.inputHeightL,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          fontSize: DesignTokens.fontSizeM,
          iconSize: DesignTokens.iconL,
        );
    }
  }
}

class _TextFieldDimensions {
  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;

  _TextFieldDimensions({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
  });
}