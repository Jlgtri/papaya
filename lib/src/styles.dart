import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The [BoxShadow] that depends on [theme].
BoxShadow boxShadow(final ThemeData theme) => BoxShadow(
      color: theme.colorScheme.shadow.withOpacity(1 / 10),
      blurRadius: 20,
    );

/// The [ColorScheme] used as a default.
const ColorScheme defaultColorScheme = ColorScheme.light(
  // background: Color(0xffE5E5E5),
  onBackground: Color(0xff1D1D27),
  primary: Color(0xffFD823E),
  secondary: Color(0xff5E8A4F),
  error: Color(0xffE74C3C),
  tertiary: Color(0xffF39C12),
  shadow: Color(0xff34343D),
  surfaceTint: Color(0xffF8F8F8),
  outline: Color(0xffC2C2C5),
);

/// The `Material3` [TextTheme] used as a default.
const TextTheme defaultTextTheme = TextTheme(
  /// Display
  displayLarge: TextStyle(
    fontFamily: 'Bright',
    fontSize: 64,
    height: 48 / 64,
    fontWeight: FontWeight.normal,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  displayMedium: TextStyle(
    fontFamily: 'Bright',
    fontSize: 48,
    height: 40 / 48,
    fontWeight: FontWeight.normal,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  displaySmall: TextStyle(
    fontFamily: 'Bright',
    fontSize: 36,
    height: 40 / 36,
    fontWeight: FontWeight.normal,
    leadingDistribution: TextLeadingDistribution.even,
  ),

  /// Headline
  headlineLarge: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 48,
    height: 48 / 48,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  headlineMedium: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  headlineSmall: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 30,
    height: 40 / 30,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),

  /// Title
  titleLarge: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 20,
    height: 32 / 20,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  titleMedium: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  titleSmall: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),

  /// Body
  bodyLarge: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.normal,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  bodyMedium: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.normal,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  bodySmall: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 14,
    height: 24 / 14,
    fontWeight: FontWeight.normal,
    leadingDistribution: TextLeadingDistribution.even,
  ),

  /// Label
  labelLarge: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 16,
    height: 16 / 16,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  labelMedium: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 14,
    height: 16 / 14,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),
  labelSmall: TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.bold,
    leadingDistribution: TextLeadingDistribution.even,
  ),
);

/// Apply additional properties on a [ThemeData].
extension CustomThemeData on ThemeData {
  /// Apply additional properties on a [ThemeData].
  ThemeData get custom => copyWith(
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        dividerColor: const Color(0xffEBEBEC),
        scaffoldBackgroundColor: colorScheme.background,
        disabledColor: colorScheme.outline,
        shadowColor: colorScheme.shadow,
        backgroundColor: colorScheme.background,
        splashColor: colorScheme.shadow.withOpacity(1 / 10),
        highlightColor: colorScheme.primary.withOpacity(1 / 10),
        textTheme: textTheme.apply(displayColor: colorScheme.onBackground),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: colorScheme.surface,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.outline,
          selectedLabelStyle: textTheme.labelSmall,
          unselectedLabelStyle: textTheme.labelSmall,
        ),
        buttonBarTheme: const ButtonBarThemeData(
          buttonPadding: EdgeInsets.all(8),
          layoutBehavior: ButtonBarLayoutBehavior.padded,
          alignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          buttonTextTheme: ButtonTextTheme.normal,
          overflowDirection: VerticalDirection.down,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: colorScheme.secondary,
          labelStyle: textTheme.titleLarge,
          unselectedLabelStyle: textTheme.titleLarge,
          unselectedLabelColor: colorScheme.shadow,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2,
                color: colorScheme.secondary,
              ),
            ),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: colorScheme.primary,
          selectionColor: colorScheme.primary,
          selectionHandleColor: colorScheme.primary,
        ),
        iconTheme: IconThemeData(size: 24, color: colorScheme.onSurface),
        tooltipTheme: TooltipThemeData(
          textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.surface),
          waitDuration: const Duration(seconds: 1),
          showDuration: const Duration(seconds: 5),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: <BoxShadow>[boxShadow(this)],
          ),
        ),
        radioTheme: RadioThemeData(
          splashRadius: 16,
          fillColor: MaterialStateProperty.all<Color?>(colorScheme.primary),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        buttonTheme: ButtonThemeData(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignedDropdown: true,
          minWidth: double.infinity,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          buttonColor: colorScheme.onSurface,
          disabledColor: colorScheme.outline,
          splashColor: colorScheme.shadow.withOpacity(1 / 10),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.primary),
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: colorScheme.primary),
            textStyle: textTheme.titleLarge,
          ).copyWith(
            elevation: MaterialStateProperty.all(0),
            foregroundColor: MaterialStateProperty.resolveWith(
              (final Set<MaterialState> states) =>
                  states.contains(MaterialState.disabled)
                      ? colorScheme.surfaceTint
                      : colorScheme.primary,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            backgroundColor: colorScheme.primary,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            textStyle: textTheme.titleLarge,
          ).copyWith(
            elevation: MaterialStateProperty.all(0),
            foregroundColor: MaterialStateProperty.resolveWith(
              (final Set<MaterialState> states) =>
                  states.contains(MaterialState.disabled)
                      ? colorScheme.surfaceTint
                      : colorScheme.surface,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            textStyle: textTheme.labelLarge,
          ).copyWith(
            elevation: MaterialStateProperty.all(0),
            foregroundColor: MaterialStateProperty.resolveWith(
              (final Set<MaterialState> states) =>
                  states.contains(MaterialState.disabled)
                      ? colorScheme.surfaceTint
                      : colorScheme.onSurface,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.error),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(width: 3 / 2, color: colorScheme.outline),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(width: 3 / 2, color: colorScheme.error),
          ),
          hintStyle: textTheme.titleMedium?.copyWith(
            color: colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
          errorStyle: textTheme.titleMedium,
          labelStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          helperStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          prefixStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          suffixStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          counterStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          floatingLabelStyle:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      );
}
