import 'package:catcher/catcher.dart';
import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:page_transition/page_transition.dart';

import 'generated/i18n.g.dart';
import 'models/settings.dart';
import 'providers/api.dart';
import 'styles.dart';
import 'widgets/authorization.dart';
import 'widgets/misc/delivery.dart';
import 'widgets/misc/map.dart';
import 'widgets/misc/stores.dart';
import 'widgets/modal/product.dart';
import 'widgets/modal/profile_edit.dart';
import 'widgets/modal/store_information.dart';
import 'widgets/navigation.dart';
import 'widgets/onboarding.dart';
import 'widgets/payment.dart';
import 'widgets/store.dart';

/// The wrapper around [MaterialApp] to support hot reload.
@immutable
class RoutesApp extends StatelessWidget {
  /// The wrapper around [MaterialApp] to support hot reload.
  const RoutesApp(this.route, {super.key});

  /// The current app's route.
  final Routes route;

  @override
  Widget build(final BuildContext context) => MaterialApp(
        title: 'Papaya',
        debugShowCheckedModeBanner: false,
        navigatorKey: Catcher.navigatorKey,
        locale: I18NLocale.enUS.locale,
        supportedLocales: I18NLocale.values.map((final _) => _.locale),
        localizationsDelegates: const <LocalizationsDelegate<Object?>>[
          I18NLocalizations.delegate,
        ],
        theme: ThemeData.from(
          useMaterial3: true,
          colorScheme: defaultColorScheme,
          textTheme: defaultTextTheme,
        ).custom,
        builder: (final BuildContext context, final Widget? child) {
          final ThemeData theme = Theme.of(context);
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaleFactor: 1),
            child: DefaultTextStyle(
              style: theme.textTheme.titleMedium ?? const TextStyle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              child: FlashTheme(
                flashBarTheme: FlashBarThemeData(
                  brightness: Brightness.light,
                  boxShadows: <BoxShadow>[boxShadow(Theme.of(context))],
                ),
                flashDialogTheme: FlashDialogThemeData(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  titleStyle: theme.textTheme.titleMedium,
                  contentStyle: theme.textTheme.bodyMedium,
                  backgroundColor: theme.colorScheme.surface,
                  constraints: BoxConstraints(
                    maxWidth: mediaQuery.size.width,
                    maxHeight: mediaQuery.size.height,
                  ),
                ),
                child: child!,
              ),
            ),
          );
        },
        useInheritedMediaQuery: true,
        initialRoute: route.name,
        onGenerateRoute: (final RouteSettings settings) =>
            settings.name != null ? Routes.from<void>(settings) : null,
      );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties..add(EnumProperty<Routes>('route', route)),
      );
}

/// The route in the app.
enum Routes {
  /// The greeting screen.
  ///
  /// Can be provided with [OnboardingScreen] as an argument.
  onboarding('onboarding'),

  /// The screen that authorizes a user.
  ///
  /// Can be provided with [AuthorizationScreen] as an argument.
  authorization('authorization'),

  /// The screen that lets a user pick location.
  ///
  /// Can be provided with [MapScreen] as an argument.
  map('/map'),

  /// The main navigation screen.
  ///
  /// Can be provided with [NavigationScreen] as an argument.
  navigation('/'),

  /// The screen that lets a user to pick a [DeliveryType] or access [map].
  ///
  /// Can be provided with [DeliveryScreen] as an argument.
  delivery('/delivery'),

  /// The screen that shows all stores to user.
  ///
  /// Can be provided with [StoresScreen] as an argument.
  stores('/stores'),

  /// The screen that shows a particular store to user.
  ///
  /// Must be provided with [StoreScreen], [StoreInformationScreen] or
  /// [ProductScreen] as an argument.
  store('/store'),

  /// The screen that shows information about a particular store to user.
  ///
  /// Must be provided with [StoreScreen] or [StoreInformationScreen] as an
  /// argument.
  storeInformation('/store/information'),

  /// The screen that shows information about a particular product to user.
  ///
  /// Must be provided with [ProductScreen] as an argument.
  product('/store/product'),

  /// The screen that allows user to edit his profile information.
  ///
  /// Can be provided with [ProfileEditScreen] as an argument.
  profileEdit('/profileEdit'),

  /// The screen that allows user to proceed with payment.
  ///
  /// Can be provided with [PaymentScreen] as an argument.
  payment('/payment');

  /// The route in the app.
  const Routes(this.name);

  /// The path of this route.
  final String name;

  /// Return the current route depending on app's state.
  static Future<Routes> current(final ProviderContainer container) async {
    if (await container.read(onboardingProvider.future)) {
      return onboarding;
    } else if (!await container.read(skippedAuthorizationProvider.future) &&
        await container.read(tokenProvider.future) == null) {
      return authorization;
    } else if (!await container.read(skippedDefaultAddressProvider.future) &&
        await container.read(activeAddressProvider.future) == null) {
      return map;
    } else {
      return navigation;
    }
  }

  /// Return the [Route] from [settings].
  static Route<T> from<T extends Object?>(final RouteSettings settings) {
    final Object? arguments = settings.arguments;
    switch (values.firstWhere((final Routes _) => _.name == settings.name)) {
      case onboarding:
        return PageTransition<T>(
          settings: settings,
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: arguments is OnboardingScreen
              ? arguments
              : const OnboardingScreen(),
        );

      case authorization:
        return PageTransition<T>(
          settings: settings,
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: arguments is AuthorizationScreen
              ? arguments
              : const AuthorizationScreen(),
        );

      case map:
        return PageTransition<T>(
          settings: settings,
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: arguments is MapScreen ? arguments : const MapScreen(),
        );

      case navigation:
        return PageTransition<T>(
          settings: settings,
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: arguments is NavigationScreen
              ? arguments
              : const NavigationScreen(),
        );

      case delivery:
        return PageTransition<T>(
          settings: settings,
          alignment: Alignment.topLeft,
          type: PageTransitionType.scale,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child:
              arguments is DeliveryScreen ? arguments : const DeliveryScreen(),
        );

      case stores:
        return PageTransition<T>(
          settings: settings,
          alignment: Alignment.centerRight,
          type: PageTransitionType.scale,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: arguments is StoresScreen ? arguments : const StoresScreen(),
        );

      case store:
        return PageTransition<T>(
          settings: settings,
          alignment: Alignment.center,
          type: PageTransitionType.scale,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: arguments is ProductScreen
              ? StoreScreen(arguments.store)
              : arguments is StoreInformationScreen
                  ? StoreScreen(arguments.store)
                  : arguments! as StoreScreen,
        );

      case storeInformation:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          builder: (final _) => arguments is StoreScreen
              ? StoreInformationScreen(arguments.store)
              : arguments! as StoreInformationScreen,
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case product:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          transitionBackgroundColor: Colors.transparent,
          modalBarrierColor: Colors.black26,
          builder: (final _) => arguments! as ProductScreen,
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case profileEdit:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          transitionBackgroundColor: Colors.transparent,
          modalBarrierColor: Colors.black26,
          builder: (final _) => arguments is ProfileEditScreen
              ? arguments
              : const ProfileEditScreen(),
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case payment:
        return PageTransition<T>(
          settings: settings,
          alignment: Alignment.center,
          type: PageTransitionType.bottomToTop,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: arguments is PaymentScreen ? arguments : const PaymentScreen(),
        );
    }
  }
}
