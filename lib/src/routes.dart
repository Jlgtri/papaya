import 'package:catcher/catcher.dart';
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
import 'widgets/modal/address.dart';
import 'widgets/modal/payment_method.dart';
import 'widgets/modal/payment_note.dart';
import 'widgets/modal/product.dart';
import 'widgets/modal/profile_edit.dart';
import 'widgets/modal/store_information.dart';
import 'widgets/navigation.dart';
import 'widgets/navigation/cart.dart';
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
              child: child!,
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
  /// **Can** be provided with [OnboardingScreen] as an argument.
  onboarding('onboarding'),

  /// The screen that authorizes a user.
  ///
  /// **Can** be provided with [AuthorizationScreen] as an argument.
  authorization('authorization'),

  /// The screen that lets a user pick location.
  ///
  /// **Can** be provided with [MapScreen] as an argument.
  map('/map'),

  /// The screen that notifies a user about denied location permission.
  ///
  /// **Can** be provided with [MapLocationDeniedScreen] as an argument.
  mapLocationDenied('/map/location_denied'),

  /// The screen that notifies a user about disabled location services.
  ///
  /// **Can** be provided with [MapLocationDisabledScreen] as an argument.
  mapLocationDisabled('/map/location_disabled'),

  /// The screen that notifies a user about invalid location.
  ///
  /// **Must** be provided with [MapLocationInvalidScreen] as an argument.
  mapLocationInvalid('/map/location_invalid'),

  /// The screen that lets user to edit an address.
  ///
  /// **Must** be provided with [AddressScreen] as an argument.
  address('/address'),

  /// The screen that lets a user to remove an address.
  ///
  /// **Must** be provided with [AddressRemoveScreen] as an argument.
  addressRemove('/address/remove'),

  /// The screen that notifies a user about an error while editing an address.
  ///
  /// **Must** be provided with [AddressErrorScreen] as an argument.
  addressError('/address/error'),

  /// The main navigation screen.
  ///
  /// **Can** be provided with [NavigationScreen] as an argument.
  navigation('/'),

  /// The screen used to clear a cart.
  ///
  /// **Can** be provided with [CartClearScreen] as an argument.
  cartClear('/cart_clear'),

  /// The screen that lets a user to pick a [DeliveryType] or access [map].
  ///
  /// **Can** be provided with [DeliveryScreen] as an argument.
  delivery('/delivery'),

  /// The screen that shows all stores to user.
  ///
  /// **Can** be provided with [StoresScreen] as an argument.
  stores('/stores'),

  /// The screen that shows a particular store to user.
  ///
  /// **Must** be provided with [StoreScreen] as an argument.
  store('/store'),

  /// The screen that shows information about a particular store to user.
  ///
  /// **Must** be provided with [StoreInformationScreen] as an argument.
  storeInformation('/store/information'),

  /// The screen that notifies about an invalid store to a user.
  ///
  /// **Must** be provided with [StoreInformationInvalidScreen] as an argument.
  storeInformationInvalid('/store/information_invalid'),

  /// The screen that shows information about a particular product to user.
  ///
  /// **Must** be provided with [ProductScreen] as an argument.
  product('/store/product'),

  /// The screen that shows information about a particular product to user.
  ///
  /// **Must** be provided with [ProductInvalidScreen] as an argument.
  productInvalid('/store/product/invalid'),

  /// The screen that allows user to edit his profile information.
  ///
  /// **Must** be provided with [ProfileEditScreen] as an argument.
  profileEdit('/profile_edit'),

  /// The screen that notifies user abount an error editing his profile
  /// information.
  ///
  /// **Must** be provided with [ProfileEditErrorScreen] as an argument.
  profileEditError('/profile_edit/error'),

  /// The screen that allows user to proceed with payment.
  ///
  /// **Can** be provided with [PaymentScreen] as an argument.
  payment('/payment'),

  /// The screen that allows user to create/edit credit card credentials.
  ///
  /// **Can** be provided with [PaymentMethodScreen] as an argument.
  paymentMethod('/payment_method'),

  /// The screen that allows user to write a note to the order.
  ///
  /// **Can** be provided with [PaymentNoteScreen] as an argument.
  paymentNote('/payment/note'),

  /// The screen that allows user to clear a note to the order.
  ///
  /// **Can** be provided with [PaymentNoteClearScreen] as an argument.
  paymentNoteClear('/payment/note/clear'),

  /// The screen that allows user to select delivery address for the order.
  ///
  /// **Can** be provided with [PaymentAddressScreen] as an argument.
  paymentAddress('/payment/address');

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
        await container.read(currentAddressProvider.future) == null) {
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

      case mapLocationDenied:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments is MapLocationDeniedScreen
                  ? arguments
                  : const MapLocationDeniedScreen(),
        );

      case mapLocationDisabled:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments is MapLocationDisabledScreen
                  ? arguments
                  : const MapLocationDisabledScreen(),
        );

      case mapLocationInvalid:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments! as MapLocationInvalidScreen,
        );

      case address:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          transitionBackgroundColor: Colors.transparent,
          modalBarrierColor: Colors.black26,
          builder: (final _) => arguments! as AddressScreen,
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case addressRemove:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments! as AddressRemoveScreen,
        );

      case addressError:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments! as AddressErrorScreen,
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

      case cartClear:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments is CartClearScreen
                  ? arguments
                  : const CartClearScreen(),
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
          child: arguments! as StoreScreen,
        );

      case storeInformation:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          builder: (final _) => arguments! as StoreInformationScreen,
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case storeInformationInvalid:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments! as StoreInformationInvalidScreen,
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

      case productInvalid:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments! as ProductInvalidScreen,
        );

      case profileEdit:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          transitionBackgroundColor: Colors.transparent,
          modalBarrierColor: Colors.black26,
          builder: (final _) => arguments! as ProfileEditScreen,
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case profileEditError:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments! as ProfileEditErrorScreen,
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

      case paymentMethod:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          transitionBackgroundColor: Colors.transparent,
          modalBarrierColor: Colors.black26,
          builder: (final _) => arguments is PaymentMethodScreen
              ? arguments
              : const PaymentMethodScreen(),
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case paymentNote:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          transitionBackgroundColor: Colors.transparent,
          modalBarrierColor: Colors.black26,
          builder: (final _) => arguments is PaymentNoteScreen
              ? arguments
              : const PaymentNoteScreen(),
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case paymentNoteClear:
        return RawDialogRoute<T>(
          settings: settings,
          barrierColor: Colors.black26,
          pageBuilder: (final _, final __, final ___) =>
              arguments is PaymentNoteClearScreen
                  ? arguments
                  : const PaymentNoteClearScreen(),
        );

      case paymentAddress:
        return CupertinoModalBottomSheetRoute<T>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          transitionBackgroundColor: Colors.transparent,
          modalBarrierColor: Colors.black26,
          builder: (final _) => arguments is PaymentAddressScreen
              ? arguments
              : const PaymentAddressScreen(),
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );
    }
  }
}
