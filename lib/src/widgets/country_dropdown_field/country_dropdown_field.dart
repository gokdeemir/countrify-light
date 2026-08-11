import 'package:countrify_light/src/icons/countrify_icons.dart';
import 'package:countrify_light/src/models/country.dart';
import 'package:countrify_light/src/models/country_code.dart';
import 'package:countrify_light/src/utils/country_utils.dart';
import 'package:countrify_light/src/widgets/countrify_field_style.dart';
import 'package:countrify_light/src/widgets/country_picker/country_picker.dart';
import 'package:countrify_light/src/widgets/country_picker_config.dart';
import 'package:countrify_light/src/widgets/country_picker_mode.dart';
import 'package:countrify_light/src/widgets/country_picker_theme.dart';
import 'package:countrify_light/src/widgets/shared/countrify_check_icon.dart';
import 'package:countrify_light/src/widgets/shared/country_flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds a country row for [CountryDropdownField] picker presentations.
typedef CountryDropdownItemBuilder = Widget Function(
  BuildContext context,
  Country country,
  // Kept positional to match CountryPicker.customCountryBuilder.
  // ignore: avoid_positional_boolean_parameters
  bool isSelected,
);

/// {@template country_dropdown_field}
/// A text field-style dropdown for selecting countries with consistent styling.
///
/// Use [CountrifyFieldStyle] to customise every aspect of the field
/// decoration in one place:
///
/// ```dart
/// CountryDropdownField(
///   style: CountrifyFieldStyle.defaultStyle().copyWith(
///     labelText: 'Country',
///     fillColor: Colors.grey.shade50,
///   ),
///   onChanged: (country) => print(country.name),
/// )
/// ```
/// {@endtemplate}
class CountryDropdownField extends StatefulWidget {
  /// {@macro country_dropdown_field}
  const CountryDropdownField({
    super.key,
    this.initialCountryCode,
    this.onChanged,
    this.theme,
    this.config,
    this.style,
    this.enabled = true,
    this.showPhoneCode = true,
    this.showFlag = true,
    this.showDropdownIcon = true,
    this.searchEnabled = true,
    this.filterEnabled = false,
    this.customCountryBuilder,
    this.customHeaderBuilder,
    this.customSearchBuilder,
    this.customFilterBuilder,
    this.pickerMode = CountryPickerMode.bottomSheet,
    this.focusNode,
  });

  /// Optional external focus node. Lets callers wire this field into form
  /// focus chains (e.g. `FocusScope.of(context).nextFocus()`).
  final FocusNode? focusNode;

  /// Initial selected country by enum code.
  final CountryCode? initialCountryCode;

  /// Callback when a country is selected.
  final ValueChanged<Country>? onChanged;

  /// Theme configuration for the picker.
  final CountryPickerTheme? theme;

  /// Configuration options for the picker.
  final CountryPickerConfig? config;

  /// Modular style for the field. Controls every aspect of the
  /// [InputDecoration] plus extras like [CountrifyFieldStyle.selectedCountryTextStyle].
  ///
  /// When null, a default style is built from the [theme].
  final CountrifyFieldStyle? style;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether to show phone code in the field.
  final bool showPhoneCode;

  /// Whether to show country flag in the field.
  final bool showFlag;

  /// Whether to show the built-in dropdown icon.
  ///
  /// A [CountrifyFieldStyle.suffixIcon] still takes precedence when supplied.
  final bool showDropdownIcon;

  /// Whether search is enabled in the picker.
  final bool searchEnabled;

  /// Whether filtering is enabled in the picker.
  final bool filterEnabled;

  /// Custom country item builder forwarded to every picker presentation.
  final CountryDropdownItemBuilder? customCountryBuilder;

  /// Custom picker header forwarded to every picker presentation.
  final Widget Function(BuildContext)? customHeaderBuilder;

  /// Custom picker search field forwarded to every picker presentation.
  final Widget Function(
    BuildContext,
    TextEditingController,
    ValueChanged<String>,
  )? customSearchBuilder;

  /// Custom picker filter forwarded to every picker presentation.
  final Widget Function(
    BuildContext,
    CountryFilter,
    ValueChanged<CountryFilter>,
  )? customFilterBuilder;

  /// How the picker is displayed.
  final CountryPickerMode pickerMode;

  @override
  State<CountryDropdownField> createState() => _CountryDropdownFieldState();
}

class _CountryDropdownFieldState extends State<CountryDropdownField> {
  Country? _selectedCountry;
  final GlobalKey _fieldKey = GlobalKey();
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = CountryUtils.resolveInitialCountry(
      initialCountryCode: widget.initialCountryCode,
    );
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(CountryDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)
          ?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
      _isFocused = _focusNode.hasFocus;
    }
    if (widget.initialCountryCode != oldWidget.initialCountryCode) {
      setState(() {
        _selectedCountry = CountryUtils.resolveInitialCountry(
          initialCountryCode: widget.initialCountryCode,
        );
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  Future<void> _showPicker() async {
    if (!widget.enabled || widget.pickerMode == CountryPickerMode.none) return;

    // Dismiss any currently-focused keyboard (e.g. a sibling TextField)
    // before opening the picker so the modal is not partially covered.
    FocusScope.of(context).unfocus();

    Country? selectedCountry;

    switch (widget.pickerMode) {
      case CountryPickerMode.bottomSheet:
        selectedCountry = await _showBottomSheetPicker();
      case CountryPickerMode.dialog:
        selectedCountry = await _showDialogPicker();
      case CountryPickerMode.fullScreen:
        selectedCountry = await _showFullScreenPicker();
      case CountryPickerMode.dropdown:
        selectedCountry = await _showDropdownPicker();
      case CountryPickerMode.none:
        return;
    }

    if (!mounted) return;
    if (selectedCountry != null) {
      setState(() {
        _selectedCountry = selectedCountry;
      });
      widget.onChanged?.call(selectedCountry);
    }
  }

  Future<Country?> _showBottomSheetPicker() async {
    return showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildPicker(CountryPickerType.bottomSheet),
    );
  }

  Future<Country?> _showDialogPicker() async {
    return showDialog<Country>(
      context: context,
      builder: (_) => _buildPicker(CountryPickerType.dialog),
    );
  }

  Future<Country?> _showFullScreenPicker() async {
    return Navigator.of(context).push<Country>(
      MaterialPageRoute(
        builder: (_) => _buildPicker(CountryPickerType.fullScreen),
      ),
    );
  }

  Future<Country?> _showDropdownPicker() async {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return _showDialogPicker();

    final origin = box.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final width = box.size.width > screenSize.width - 16
        ? screenSize.width - 16
        : box.size.width;
    final left = origin.dx
        .clamp(8, (screenSize.width - width - 8).clamp(8, double.infinity))
        .toDouble();
    final openAbove = origin.dy + box.size.height + 300 > screenSize.height &&
        origin.dy > screenSize.height / 2;
    final barrierLabel =
        MaterialLocalizations.of(context).modalBarrierDismissLabel;

    return showGeneralDialog<Country>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            Positioned(
              left: left,
              width: width,
              top: openAbove ? null : origin.dy + box.size.height + 4,
              bottom: openAbove ? screenSize.height - origin.dy + 4 : null,
              child: Material(
                color: Colors.transparent,
                child: _buildPicker(
                  CountryPickerType.inline,
                  onCountrySelected: (country) {
                    Navigator.of(dialogContext).pop(country);
                  },
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  CountryPicker _buildPicker(
    CountryPickerType pickerType, {
    ValueChanged<Country>? onCountrySelected,
  }) {
    return CountryPicker(
      initialCountryCode: CountryCodeExtension.fromAlpha2Code(
        _selectedCountry?.alpha2Code ?? '',
      ),
      onCountrySelected: onCountrySelected,
      theme: widget.theme,
      config: widget.config,
      pickerType: pickerType,
      showPhoneCode: widget.showPhoneCode,
      showFlag: widget.showFlag,
      searchEnabled: widget.searchEnabled,
      filterEnabled: widget.filterEnabled,
      customCountryBuilder: widget.customCountryBuilder,
      customHeaderBuilder: widget.customHeaderBuilder,
      customSearchBuilder: widget.customSearchBuilder,
      customFilterBuilder: widget.customFilterBuilder,
    );
  }

  String _displayName(Country country) {
    final locale = (widget.config ?? const CountryPickerConfig()).locale ??
        Localizations.localeOf(context).languageCode;
    if (locale == 'en') return country.name;
    return CountryUtils.getCountryNameInLanguage(country, locale);
  }

  String _getDisplayText() {
    final config = widget.config ?? const CountryPickerConfig();
    if (_selectedCountry == null) {
      return config.selectCountryHintText;
    }

    final parts = <String>[_displayName(_selectedCountry!)];

    if (widget.showPhoneCode && _selectedCountry!.callingCodes.isNotEmpty) {
      parts.add('(+${_selectedCountry!.callingCodes.first})');
    }

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? CountryPickerTheme.defaultTheme();
    final effectiveStyle = widget.style ?? CountrifyFieldStyle.defaultStyle();
    final config = widget.config ?? const CountryPickerConfig();

    final Widget? defaultPrefixWidget;
    if (_selectedCountry != null && widget.showFlag) {
      defaultPrefixWidget = Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: CountryFlag(
          country: _selectedCountry!,
          size: const Size(28, 20),
          borderRadius: config.flagBorderRadius,
          borderColor: config.flagBorderColor,
          borderWidth: config.flagBorderWidth,
          emojiTextStyle: theme.flagEmojiTextStyle,
        ),
      );
    } else if (_selectedCountry == null && widget.showFlag) {
      defaultPrefixWidget = Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(
          theme.defaultCountryIcon ?? CountrifyIcons.globe,
          size: 20,
          color: theme.headerIconColor ?? Colors.grey.shade600,
        ),
      );
    } else {
      defaultPrefixWidget = null;
    }

    final defaultSuffixWidget = widget.showDropdownIcon
        ? Padding(
            padding: const EdgeInsets.only(right: 12),
            child: theme.dropdownIcon != null
                ? Icon(
                    theme.dropdownIcon,
                    size: 18,
                    color: widget.enabled ? null : Colors.grey,
                  )
                : CountrifyDownArrowIcon(
                    color: widget.enabled
                        ? (theme.headerIconColor ?? Colors.grey.shade500)
                        : Colors.grey,
                  ),
          )
        : null;

    final borderRadius =
        effectiveStyle.fieldBorderRadius ?? BorderRadius.circular(12);

    final decoration = effectiveStyle.toInputDecoration(
      prefixIconOverride: effectiveStyle.prefixIcon ?? defaultPrefixWidget,
      suffixIconOverride: effectiveStyle.suffixIcon ?? defaultSuffixWidget,
    );

    final field = DecoratedBox(
      key: _fieldKey,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: _isFocused && effectiveStyle.focusedBoxShadow != null
            ? effectiveStyle.focusedBoxShadow!
            : const [],
      ),
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: widget.enabled,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.space ||
                  event.logicalKey == LogicalKeyboardKey.enter)) {
            _showPicker();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          onTap: widget.enabled && widget.pickerMode != CountryPickerMode.none
              ? _showPicker
              : null,
          borderRadius: borderRadius,
          child: InputDecorator(
            decoration: decoration,
            isEmpty: _selectedCountry == null,
            child: _selectedCountry != null
                ? Text(
                    _getDisplayText(),
                    style: effectiveStyle.selectedCountryTextStyle ??
                        theme.countryNameTextStyle,
                  )
                : null,
          ),
        ),
      ),
    );

    return effectiveStyle.wrapWithExternalLabel(context, child: field);
  }
}
