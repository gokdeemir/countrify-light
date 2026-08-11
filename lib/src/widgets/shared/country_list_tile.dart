import 'package:countrify_light/src/models/country.dart';
import 'package:countrify_light/src/widgets/country_picker_config.dart';
import 'package:countrify_light/src/widgets/shared/countrify_check_icon.dart';
import 'package:countrify_light/src/widgets/shared/country_flag.dart';
import 'package:flutter/material.dart';

/// A reusable country row widget that displays a flag, country name,
/// dial code, and optional selected checkmark.
///
/// Example:
/// ```dart
/// CountryListTile(
///   country: CountryUtils.getCountryByAlpha2Code('US')!,
///   onTap: (country) => print(country.name),
///   isSelected: true,
/// )
/// ```
class CountryListTile extends StatelessWidget {
  /// Creates a [CountryListTile].
  const CountryListTile({
    required this.country,
    required this.onTap,
    super.key,
    this.isSelected = false,
    this.showFlag = true,
    this.showCountryName = true,
    this.showDialCode = true,
    this.flagSize = const Size(24, 18),
    this.flagShape = FlagShape.rectangular,
    this.flagBorderRadius = const BorderRadius.all(Radius.circular(4)),
    this.flagBorderColor,
    this.flagBorderWidth = 0,
    this.flagShadowColor,
    this.flagShadowBlur = 2,
    this.flagShadowOffset = const Offset(0, 1),
    this.flagEmojiTextStyle,
    this.flagOpticalOffset = CountryFlag.defaultOpticalOffset,
    this.countryNameStyle,
    this.dialCodeStyle,
    this.selectedColor,
    this.selectedBorderColor,
    this.selectedIconColor,
    this.selectedIcon,
    this.displayName,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.contentPadding,
    this.splashColor,
    this.highlightColor,
    this.enableSplash = true,
  });

  /// The country to display.
  final Country country;

  /// Callback when the tile is tapped.
  final ValueChanged<Country> onTap;

  /// Whether this tile is currently selected.
  final bool isSelected;

  /// Whether to show the flag. Defaults to `true`.
  final bool showFlag;

  /// Whether to show the country name. Defaults to `true`.
  final bool showCountryName;

  /// Whether to show the dial code. Defaults to `true`.
  final bool showDialCode;

  /// Size allocated to the flag emoji.
  final Size flagSize;

  /// Shape of the flag container.
  final FlagShape flagShape;

  /// Border radius of the flag container.
  final BorderRadius flagBorderRadius;

  /// Border color of the flag container.
  final Color? flagBorderColor;

  /// Border width of the flag container. Defaults to zero.
  final double flagBorderWidth;

  /// Shadow color of the flag container. A null value disables the shadow.
  final Color? flagShadowColor;

  /// Blur radius of the optional flag shadow.
  final double flagShadowBlur;

  /// Offset of the optional flag shadow.
  final Offset flagShadowOffset;

  /// Text style applied to the flag emoji.
  final TextStyle? flagEmojiTextStyle;

  /// Optical correction applied to the flag emoji.
  final Offset flagOpticalOffset;

  /// Text style for the country name.
  final TextStyle? countryNameStyle;

  /// Text style for the dial code.
  final TextStyle? dialCodeStyle;

  /// Background color when selected.
  final Color? selectedColor;

  /// Border color when selected. Defaults to primary at 20% opacity.
  final Color? selectedBorderColor;

  /// Color of the selected checkmark icon.
  final Color? selectedIconColor;

  /// Custom icon to show when selected. Defaults to [Icons.check].
  final IconData? selectedIcon;

  /// Pre-localized display name. Falls back to [Country.name].
  final String? displayName;

  /// Border radius of the tile. Defaults to `BorderRadius.circular(10)`.
  final BorderRadius borderRadius;

  /// Padding inside the tile. Defaults to `EdgeInsets.symmetric(horizontal: 14, vertical: 12)`.
  final EdgeInsetsGeometry? contentPadding;

  /// Splash color when tapped. Set to [Colors.transparent] to disable.
  final Color? splashColor;

  /// Highlight color when long-pressed.
  final Color? highlightColor;

  /// Whether to show ink splash on tap. Defaults to `true`.
  final bool enableSplash;

  String get _effectiveName => displayName ?? country.name;

  String get _dialCode =>
      country.callingCodes.isNotEmpty ? '+${country.callingCodes.first}' : '';

  String? get _semanticLabel {
    final parts = <String>[
      if (showCountryName) _effectiveName,
      if (showDialCode && _dialCode.isNotEmpty) 'dial code $_dialCode',
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final effectiveSelectedColor =
        selectedColor ?? primary.withValues(alpha: 0.08);
    final effectiveBorderColor =
        selectedBorderColor ?? primary.withValues(alpha: 0.2);
    final effectiveFlagBorderRadius = flagShape == FlagShape.circular
        ? BorderRadius.circular(flagSize.width / 2)
        : flagBorderRadius;

    return Semantics(
      label: _semanticLabel,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      onTap: () => onTap(country),
      child: Material(
        color: isSelected ? effectiveSelectedColor : Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: () => onTap(country),
          borderRadius: borderRadius,
          splashColor: enableSplash ? splashColor : Colors.transparent,
          highlightColor: enableSplash ? highlightColor : Colors.transparent,
          splashFactory: enableSplash ? null : NoSplash.splashFactory,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(color: effectiveBorderColor),
                  )
                : null,
            padding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (showFlag) ...[
                  CountryFlag(
                    country: country,
                    size: flagSize,
                    borderRadius: effectiveFlagBorderRadius,
                    borderColor: flagBorderColor,
                    borderWidth: flagBorderWidth,
                    shadowColor: flagShadowColor,
                    shadowBlur: flagShadowBlur,
                    shadowOffset: flagShadowOffset,
                    emojiTextStyle: flagEmojiTextStyle,
                    opticalOffset: flagOpticalOffset,
                  ),
                  const SizedBox(width: 12),
                ],
                if (showDialCode && _dialCode.isNotEmpty) ...[
                  Text(
                    _dialCode,
                    style: dialCodeStyle ??
                        TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? primary
                              : theme.textTheme.bodyMedium?.color,
                        ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (showCountryName)
                  Expanded(
                    child: Text(
                      _effectiveName,
                      overflow: TextOverflow.ellipsis,
                      style: countryNameStyle ??
                          TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? primary
                                : theme.textTheme.bodyMedium?.color,
                          ),
                    ),
                  )
                else
                  const Spacer(),
                if (isSelected)
                  if (selectedIcon != null)
                    Icon(
                      selectedIcon,
                      color: selectedIconColor ?? primary,
                      size: 18,
                    )
                  else
                    CountrifyCheckIcon(
                      size: 18,
                      color: selectedIconColor ?? primary,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
