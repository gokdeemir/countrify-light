import 'package:countrify_light/src/models/country.dart';
import 'package:flutter/material.dart';

/// A standalone flag widget that displays a country's flag emoji.
///
/// Example:
/// ```dart
/// CountryFlag(
///   country: CountryUtils.getCountryByAlpha2Code('US')!,
///   size: const Size(32, 24),
/// )
/// ```
class CountryFlag extends StatelessWidget {
  /// Creates a flag emoji for [country].
  const CountryFlag({
    required this.country,
    super.key,
    this.size = const Size(24, 18),
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.borderColor,
    this.borderWidth = 0,
    this.shadowColor,
    this.shadowBlur = 2,
    this.shadowOffset = const Offset(0, 1),
    this.emojiTextStyle,
    this.opticalOffset = defaultOpticalOffset,
  });

  /// Default optical correction for emoji flag glyphs.
  static const defaultOpticalOffset = Offset(0, -0.08);

  /// The country whose flag to display.
  final Country country;

  /// Size allocated to the flag emoji.
  final Size size;

  /// Border radius of the flag container.
  final BorderRadius borderRadius;

  /// Border color. Used only when [borderWidth] is greater than zero.
  final Color? borderColor;

  /// Border width. Defaults to `0` so emoji flags render without a frame.
  final double borderWidth;

  /// Shadow color. A null value disables the flag shadow.
  final Color? shadowColor;

  /// Blur radius of the optional flag shadow.
  final double shadowBlur;

  /// Offset of the optional flag shadow.
  final Offset shadowOffset;

  /// Text style for the flag emoji.
  final TextStyle? emojiTextStyle;

  /// Fractional translation used to optically center the emoji glyph.
  ///
  /// Emoji fonts commonly paint flags below the center of their line box, so
  /// this defaults to [defaultOpticalOffset]. Set [Offset.zero] to disable the
  /// correction for a platform-specific font.
  final Offset opticalOffset;

  @override
  Widget build(BuildContext context) {
    final flag = Center(
      child: FractionalTranslation(
        translation: opticalOffset,
        child: Text(
          country.flagEmoji,
          style: TextStyle(fontSize: size.width * 0.7, height: 1)
              .merge(emojiTextStyle),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
    final hasDecoration = borderWidth > 0 || shadowColor != null;

    return Semantics(
      label: 'Flag of ${country.name}',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: hasDecoration
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: borderWidth > 0
                      ? Border.all(
                          color: borderColor ?? Colors.grey.shade300,
                          width: borderWidth,
                        )
                      : null,
                  boxShadow: shadowColor == null
                      ? null
                      : [
                          BoxShadow(
                            color: shadowColor!,
                            blurRadius: shadowBlur,
                            offset: shadowOffset,
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: flag,
                ),
              )
            : flag,
      ),
    );
  }
}
