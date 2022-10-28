import 'package:catcher/catcher.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:page_transition/page_transition.dart';

import 'generated/models.g.dart';
import 'models/cart_store.dart';
import 'models/settings.dart';
import 'providers/api_providers.dart';
import 'widgets/authorization_screen.dart';
import 'widgets/misc/delivery_screen.dart';
import 'widgets/misc/map_screen.dart';
import 'widgets/misc/stores_screen.dart';
import 'widgets/navigation_screen.dart';
import 'widgets/onboarding_screen.dart';
import 'widgets/product_screen.dart';
import 'widgets/store_screen.dart';

enum Routes {
  onboarding,
  authorization,
  map,
  navigation,
  delivery,
  stores,
  store,
  storeInformation,
  product;

  Future<T?> _push<T extends Object?>(
    final NavigatorState navigator,
    final WidgetRef ref, {
    required final bool isReplacement,
    final Object? argument,
  }) async {
    Future<T?> push(final String name) => isReplacement
        ? navigator.pushReplacementNamed(name, arguments: ref.context)
        : navigator.pushNamed(name, arguments: ref.context);

    switch (this) {
      case Routes.onboarding:
      case Routes.authorization:
      case Routes.map:
      case Routes.navigation:
      case Routes.stores:
        return push(name);

      case Routes.delivery:
        return push(
          <String>[
            Routes.delivery.name,
            (await ref.read(deliveryTypeProvider.future)).name
          ].join('/'),
        );
      case Routes.store:
        assert(
          argument is StoreModel,
          'You must provide a StoreModel to push.',
        );
        final StoreModel store = argument! as StoreModel;
        ref.read(StoreScreen.provider.notifier).state = store;
        ref.read(StoreScreen.menuProvider.notifier).state =
            await ref.read(storeMenuProvider(store.id!).future);
        ref.read(StoreScreen.etaDeliveryProvider.notifier).state =
            await ref.read(storeEtaDeliveryProvider(store.id!).future);
        ref.read(StoreScreen.etaPickupProvider.notifier).state =
            await ref.read(storeEtaPickupProvider(store.id!).future);
        return push(
          <String>[name, (await ref.read(deliveryTypeProvider.future)).name]
              .join('/'),
        );
      case Routes.storeInformation:
        assert(
          argument is StoreModel,
          'You must provide a StoreModel to push.',
        );
        final StoreModel store = argument! as StoreModel;
        ref.read(StoreScreen.provider.notifier).state = store;
        ref.read(StoreScreen.workingTimeProvider.notifier).state =
            await ref.read(storeWorkingTimeProvider(store.id!).future);
        return push(name);
      case Routes.product:
        assert(
          argument is StoreMenuProductsModel,
          'You must provide a StoreMenuProductsModel to push.',
        );
        final StoreMenuProductsModel product =
            argument! as StoreMenuProductsModel;
        ref.read(ProductScreen.provider.notifier).state = product;
        ref.read(ProductScreen.currentAmountProvider.notifier).state =
            (await ref.read(amountProvider.future)).clamp(1, 9);
        return push(name);
    }
  }

  Future<T?> push<T extends Object?>(
    final NavigatorState navigator,
    final WidgetRef ref, [
    final Object? argument,
  ]) async =>
      _push(navigator, ref, argument: argument, isReplacement: false);

  Future<T?> pushReplacement<T extends Object?>(
    final NavigatorState navigator,
    final WidgetRef ref, [
    final Object? argument,
  ]) async =>
      _push(navigator, ref, argument: argument, isReplacement: true);

  /// Return the current route depending on app's state.
  static Future<Routes> current(final ProviderContainer container) async {
    if (await container.read(onboardingProvider.future)) {
      return onboarding;
    } else if (await container.read(tokenProvider.future) == null) {
      return authorization;
    } else if (await container.read(activeAddressProvider.future) == null) {
      return map;
    } else {
      return navigation;
    }
  }

  /// Return the [Route] from [settings].
  static Route<Object?> from(final RouteSettings settings) {
    final BuildContext? rootContext = Catcher.navigatorKey?.currentContext;
    final BuildContext? context = settings.arguments is BuildContext
        ? settings.arguments! as BuildContext
        : null;
    final Iterable<String> parts = settings.name!.split('/');
    switch (values.firstWhere((final Routes _) => _.name == parts.first)) {
      case onboarding:
        return PageTransition<Object?>(
          settings: settings,
          ctx: context ?? rootContext,
          inheritTheme: rootContext != null,
          childCurrent: context?.widget,
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: const OnboardingScreen(),
        );

      case authorization:
        return PageTransition<Object?>(
          settings: settings,
          ctx: context ?? rootContext,
          inheritTheme: rootContext != null,
          childCurrent: context?.widget,
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: const AuthorizationScreen(),
        );

      case map:
        return PageTransition<Object?>(
          settings: settings,
          ctx: context ?? rootContext,
          inheritTheme: rootContext != null,
          childCurrent: context?.widget,
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: const MapScreen(),
        );

      case navigation:
        return PageTransition<Object?>(
          settings: settings,
          ctx: context ?? rootContext,
          inheritTheme: rootContext != null,
          childCurrent: context?.widget,
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: const NavigationScreen(),
        );

      case delivery:
        return PageTransition<Object?>(
          settings: settings,
          ctx: context ?? rootContext,
          inheritTheme: rootContext != null,
          childCurrent: context?.widget,
          alignment: Alignment.topLeft,
          type: PageTransitionType.scale,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: DeliveryScreen(
            deliveryType: parts.length > 1
                ? (DeliveryType.values.whereType<DeliveryType?>()).firstWhere(
                    (final _) => _?.name == parts.elementAt(1),
                    orElse: () => null,
                  )
                : null,
          ),
        );

      case stores:
        return PageTransition<Object?>(
          settings: settings,
          ctx: context ?? rootContext,
          inheritTheme: rootContext != null,
          childCurrent: context?.widget,
          alignment: Alignment.centerRight,
          type: PageTransitionType.scale,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: const StoresScreen(),
        );

      case store:
        return PageTransition<Object?>(
          settings: settings,
          ctx: context ?? rootContext,
          inheritTheme: rootContext != null,
          childCurrent: context?.widget,
          alignment: Alignment.center,
          type: PageTransitionType.scale,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          child: StoreScreen(
            deliveryType: parts.length > 1
                ? (DeliveryType.values.whereType<DeliveryType?>()).firstWhere(
                    (final _) => _?.name == parts.elementAt(1),
                    orElse: () => null,
                  )
                : null,
          ),
        );

      case storeInformation:
        return CupertinoModalBottomSheetRoute<Object?>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          builder: (final _) => const StoreInformationScreen(),
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );

      case product:
        return CupertinoModalBottomSheetRoute<Object?>(
          settings: settings,
          topRadius: Radius.zero,
          expanded: false,
          bounce: false,
          transitionBackgroundColor: Colors.transparent,
          modalBarrierColor: Colors.black26,
          builder: (final _) => const ProductScreen(),
          duration: const Duration(milliseconds: 500),
          animationCurve: Curves.easeOutQuad,
        );
    }
  }
}
