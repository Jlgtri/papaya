import 'dart:async';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../generated/assets.g.dart';
import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../generated/models.g.dart';
import '../hooks/sync_callback_hook.dart';
import '../models/settings.dart';
import '../providers/api.dart';
import '../providers/misc.dart';
import '../routes.dart';
import '../styles.dart';
import 'modal/product.dart';
import 'modal/store_information.dart';

/// The screen used to show off a [store].
class StoreScreen extends HookConsumerWidget {
  /// The screen used to show off a [store].
  const StoreScreen(this.store, {super.key});

  /// The store to show this screen for.
  final StoreModel store;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();
    return WillPopScope(
      onWillPop: () async {
        if (navigator.canPop()) {
          return true;
        }
        WidgetsBinding.instance.addPostFrameCallback(
          (final _) => syncCallback(
            () async => navigator
                .pushReplacementNamed((await Routes.current(container)).name),
          ),
        );
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: theme.colorScheme.onBackground,
            body: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                /// Background Image
                CachedNetworkImage(
                  imageUrl: store.imgUrl ?? '',
                  imageBuilder:
                      (final _, final ImageProvider<Object> imageProvider) =>
                          DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        transform: const GradientRotation(0.096516707635),
                        stops: const <double>[
                          0,
                          715 / 375 * 0.2223,
                          715 / 375 * 0.9488
                        ],
                        colors: <Color>[
                          Colors.black.withOpacity(0.68),
                          Colors.black.withOpacity(0.73),
                          Colors.black.withOpacity(0)
                        ],
                      ),
                    ),
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  errorWidget: (final _, final __, final ___) =>
                      const SizedBox.shrink(),
                ),
                StoreContent(store),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties..add(DiagnosticsProperty<StoreModel>('store', store)),
      );
}

/// The widget used to show products for a [store].
class StoreContent extends HookConsumerWidget {
  /// The widget used to show products for a [store].
  const StoreContent(this.store, {super.key});

  /// The store to show products for.
  final StoreModel store;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final AsyncValue<Iterable<StoreMenuModel>> menu =
        ref.watch(storeMenuProvider(store.id!));

    final SyncCallback syncCallback = useSyncCallback();
    Future<void> onProductPressed(final StoreMenuProductsModel product) async =>
        syncCallback(() async {
          // CartStoreProduct? $$product;
          // outer:
          // for (final CartStore $store in await ref.read(cartProvider.future)) {
          //   if ($store.id == store.id) {
          //     for (final CartStoreProduct $product in $store.products) {
          //       if ($product.id == product.id) {
          //         $$product = $product;
          //         break outer;
          //       }
          //     }
          //   }
          // }
          await navigator.pushNamed(
            Routes.product.name,
            arguments: ProductScreen(
              store,
              product,
              // currentAmount: $$product?.amount,
            ),
          );
        });

    final List<Widget> storeInformation = <Widget>[
      SliverFillRemaining(
        child: Column(
          children: <Widget>[
            AppBar(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: theme.colorScheme.surface,
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 64,
              leadingWidth: double.infinity,
              leading: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.surface,
                    ),
                    onPressed: () async => syncCallback(navigator.maybePop),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(icons.misc.arrowLeft, size: 14),
                          const SizedBox(width: 12),
                          Flexible(child: Text($.store.back))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: StoreInformationLoader(store))
          ],
        ),
      ),
    ];

    final Widget scrollable;
    if (menu is! AsyncData || (menu.valueOrNull?.isEmpty ?? true)) {
      scrollable = CustomScrollView(slivers: storeInformation);
    } else {
      scrollable = NestedScrollView(
        headerSliverBuilder: (final _, final bool innerBoxIsScrolled) =>
            <Widget>[
          ...storeInformation,
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: theme.colorScheme.surface,
            ),
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(menu.isLoading ? 64 : 48),
              child: menu.isLoading
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : Material(
                      child: TabBar(
                        isScrollable: true,
                        indicatorPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        splashBorderRadius: BorderRadius.circular(8),
                        tabs: <Tab>[
                          for (final StoreMenuModel menu in menu.value!)
                            if (menu.name != null && menu.products != null)
                              Tab(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(menu.name!),
                                ),
                              ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: theme.colorScheme.surface,
          ),
          child: Material(
            child: TabBarView(
              children: <Widget>[
                for (final StoreMenuModel menu in menu.value!)
                  if (menu.name != null && menu.products != null)
                    StoreMenu(
                      menu,
                      onPressed: onProductPressed,
                      key: PageStorageKey<int?>(menu.id),
                    )
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: menu.valueOrNull?.length ?? 0,
      child: ScrollConfiguration(
        /// Fixes: https://github.com/flutter/flutter/issues/104798
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: mediaQuery.padding.bottom > 0
            ? SafeArea(top: false, child: scrollable)
            : scrollable,
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties..add(DiagnosticsProperty<StoreModel>('store', store)),
      );
}

/// The callback on [StoreMenuProductsModel].
typedef StoreProductCallback = FutureOr<void> Function(
  StoreMenuProductsModel product,
);

/// The widget to show a [menu].
class StoreMenu extends HookConsumerWidget {
  /// The widget to show a [menu].
  const StoreMenu(this.menu, {required this.onPressed, super.key});

  /// The menu to show in this widget.
  final StoreMenuModel menu;

  /// The callback on [StoreMenuModel.products].
  final StoreProductCallback? onPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 40),
          Flexible(
            child: Text(
              menu.name!,
              style: theme.textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 28),
          ...menu.products!.map(
            (final StoreMenuProductsModel product) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              child: StoreProductCard(
                product,
                onPressed:
                    onPressed != null ? () async => onPressed!(product) : null,
              ),
            ),
          ),
          SizedBox(height: mediaQuery.padding.bottom + 81),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<StoreMenuModel>('menu', menu))
          ..add(
            ObjectFlagProperty<StoreProductCallback?>.has(
              'onPressed',
              onPressed,
            ),
          ),
      );
}

/// The widget used to load information about a [store].
class StoreInformationLoader extends HookConsumerWidget {
  /// The widget used to load information about a [store].
  const StoreInformationLoader(this.store, {super.key});

  /// The store to show information for.
  final StoreModel store;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<DeliveryType> deliveryType = ref.watch(
      deliveryTypeProvider,
    );
    final DeliveryType? prevDeliveryType =
        usePrevious<DeliveryType?>(deliveryType.valueOrNull);
    return deliveryType.valueOrNull != null || prevDeliveryType != null
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: StoreInformation(
              store,
              deliveryType: deliveryType.valueOrNull ?? prevDeliveryType!,
            ),
          )
        : const Center(child: CircularProgressIndicator.adaptive());
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties..add(DiagnosticsProperty<StoreModel>('store', store)),
      );
}

/// The widget used to show information about a [store].
class StoreInformation extends HookConsumerWidget {
  /// The widget used to show information about a [store].
  const StoreInformation(this.store, {required this.deliveryType, super.key});

  /// The store to show information for.
  final StoreModel store;

  /// The current picked [DeliveryType].
  final DeliveryType deliveryType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final MediaQueryData rootMediaQuery = MediaQuery.of(rootNavigator.context);

    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            /// Limited Time
            Flexible(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  Text(
                    $.store.limitedTime,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.surface,
                    ),
                  ),
                  Positioned(
                    left: 1,
                    child: Text(
                      $.store.limitedTime,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// Name
            Flexible(
              child: Text(
                store.name ?? '',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.surface,
                ),
                maxLines: 1,
              ),
            ),

            /// Description
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                store.description ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.surface,
                ),
                maxLines: 4,
              ),
            ),

            /// Tags
            const SizedBox(height: 40),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      icons.vegan,
                      size: 24,
                      color: theme.colorScheme.surface,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      $.store.vegan,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.surface,
                      ),
                      maxLines: 1,
                    ),
                    if ((store.cuisines?.isNotEmpty ?? false) &&
                        store.cuisines?.first.cuisine != null) ...<Widget>[
                      const SizedBox(width: 48),
                      Icon(
                        icons.cuisine,
                        size: 24,
                        color: theme.colorScheme.surface,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        store.cuisines?.first.cuisine ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.surface,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            /// Additional Info
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.surface,
                  ),
                  onPressed: () async => syncCallback(
                    () async => rootNavigator.pushNamed(
                      Routes.storeInformation.name,
                      arguments: StoreInformationScreen(store),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Icon(icons.info, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            $.store.additionalInfo,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        /// Picker (Show loading state on error)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: rootMediaQuery.padding.bottom),
            child: Consumer(
              builder: (final _, final WidgetRef ref, final Widget? child) {
                final AsyncValue<StoreEtaDeliveryModel?> deliveryTime =
                    ref.watch(storeEtaDeliveryProvider(store.id!));
                final AsyncValue<StoreEtaPickupModel?> pickupTime =
                    ref.watch(storeEtaPickupProvider(store.id!));
                return (deliveryTime is AsyncData && pickupTime is AsyncData) &&
                        ref.watch(
                          storeMenuProvider(store.id!).select(
                            (final AsyncValue<Iterable<StoreMenuModel>> menu) =>
                                menu is AsyncData &&
                                (menu.valueOrNull?.isNotEmpty ?? false),
                          ),
                        )
                    ? StoreInformationDeliveryTypeSwitcher(
                        deliveryTime.valueOrNull,
                        pickupTime.valueOrNull,
                        deliveryType: deliveryType,
                      )
                    : const SizedBox(
                        height: 72,
                        child:
                            Center(child: CircularProgressIndicator.adaptive()),
                      );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<StoreModel>('store', store))
          ..add(EnumProperty<DeliveryType?>('deliveryType', deliveryType)),
      );
}

/// The switcher of [Settings.deliveryType] on [StoreScreen].
class StoreInformationDeliveryTypeSwitcher extends HookConsumerWidget {
  /// The switcher of [Settings.deliveryType] on [StoreScreen].
  const StoreInformationDeliveryTypeSwitcher(
    this.deliveryTime,
    this.pickupTime, {
    required this.deliveryType,
    super.key,
  });

  /// The delivery time to show in this switcher.
  final StoreEtaDeliveryModel? deliveryTime;

  /// The pickup time to show in this switcher.
  final StoreEtaPickupModel? pickupTime;

  /// The current active [DeliveryType].
  final DeliveryType deliveryType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final SyncCallback syncCallback = useSyncCallback(discard: false);
    return CustomAnimatedToggleSwitch<DeliveryType>(
      height: 72,
      values: DeliveryType.values,
      current: deliveryType,
      onChanged: (final DeliveryType $deliveryType) async =>
          syncCallback(() async {
        switch ($deliveryType) {
          case DeliveryType.delivery:
            if (deliveryTime == null) {
              return;
            }
            break;
          case DeliveryType.pickup:
            if (pickupTime == null) {
              return;
            }
            break;
        }
        final Isar isar = await ref.read(isarProvider.future);
        await isar.writeTxn(
          () async => isar.settings.put(
            await ref.read(settingsProvider.future)
              ..deliveryType = $deliveryType,
          ),
        );
      }),
      indicatorSize: Size.infinite,
      backgroundIndicatorBuilder: (final _, final __) => Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(40),
          color: theme.colorScheme.secondary,
          child: const SizedBox.expand(),
        ),
      ),
      wrapperBuilder: (final _, final __, final Widget child) => Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(40),
        color: theme.colorScheme.surface,
        child: child,
      ),
      iconBuilder: (final _, final __, final ___) => Align(
        child: FractionallySizedBox(
          widthFactor: 1 / 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Flexible(
                  child: Text(
                    (final DeliveryType deliveryType) {
                      switch (deliveryType) {
                        case DeliveryType.delivery:
                          return $.store.delivery;
                        case DeliveryType.pickup:
                          return $.store.pickup;
                      }
                    }(__.value),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ColorTween(
                        begin: theme.colorScheme.onBackground,
                        end: theme.colorScheme.surface,
                      ).transform(
                        __.value == DeliveryType.delivery
                            ? 1 - ___.position
                            : ___.position,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Flexible(
                  child: Consumer(
                    builder: (
                      final BuildContext context,
                      final WidgetRef ref,
                      final Widget? child,
                    ) =>
                        Text(
                      (final DeliveryType deliveryType) {
                        switch (deliveryType) {
                          case DeliveryType.delivery:
                            return deliveryTime?.min != null &&
                                    deliveryTime?.max != null
                                ? $.store.deliveryTime(
                                    deliveryTime!.min!,
                                    deliveryTime!.max!,
                                  )
                                : $.store.deliveryUnavailable;
                          case DeliveryType.pickup:
                            return pickupTime?.min != null &&
                                    pickupTime?.max != null
                                ? $.store.pickupTime(
                                    pickupTime!.min!,
                                    pickupTime!.max!,
                                  )
                                : $.store.pickupUnavailable;
                        }
                      }(__.value),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorTween(
                          begin: theme.colorScheme.onBackground,
                          end: theme.colorScheme.surface,
                        ).transform(
                          __.value == DeliveryType.delivery
                              ? 1 - ___.position
                              : ___.position,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(
            DiagnosticsProperty<StoreEtaDeliveryModel>(
              'deliveryTime',
              deliveryTime,
            ),
          )
          ..add(
            DiagnosticsProperty<StoreEtaPickupModel>(
              'pickupTime',
              pickupTime,
            ),
          )
          ..add(EnumProperty<DeliveryType?>('deliveryType', deliveryType)),
      );
}

/// The [StoreMenuProductsModel.name] property should not be null.
class StoreProductCard extends HookConsumerWidget {
  /// The [StoreMenuProductsModel.name] property should not be null.
  const StoreProductCard(this.product, {required this.onPressed, super.key});

  /// The product to diplay in this card.
  final StoreMenuProductsModel product;

  /// The callback on this card.
  final FutureOr<void> Function()? onPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: <BoxShadow>[boxShadow(theme)]),
      child: Material(
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            /// Image
            SizedBox(
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CachedNetworkImage(
                    imageUrl: product.imgUrl ?? '',
                    fit: BoxFit.fitWidth,
                    height: 240,
                    filterQuality: FilterQuality.high,
                    errorWidget: (final _, final __, final ___) =>
                        Image.asset(assets.logo, fit: BoxFit.fitWidth),
                  ),
                  if (product.tags
                          ?.map((final _) => _.tagName)
                          .contains('Gluten-Free') ??
                      false)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: IconButton(
                          icon: Padding(
                            padding: const EdgeInsets.all(8).copyWith(top: 6),
                            child: Icon(
                              icons.gluten,
                              color: theme.colorScheme.secondary,
                              size: 24,
                            ),
                          ),
                          style: IconButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: theme.colorScheme.surface,
                            disabledBackgroundColor: theme.colorScheme.surface,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: null,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /// Information
            const SizedBox(height: 16),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    /// Name
                    Flexible(
                      child: Text(
                        product.name!,
                        style: theme.textTheme.headlineMedium,
                        maxLines: 1,
                      ),
                    ),

                    /// Description
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        product.description ?? '',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Footer
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          /// Price
                          Flexible(
                            child: Text(
                              r'$' +
                                  ((product.price ?? 0) / 100)
                                      .toStringAsFixed(2),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 24,
                                height: 32 / 24,
                              ),
                            ),
                          ),

                          /// Add to Cart
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              textStyle: theme.textTheme.titleSmall,
                            ),
                            onPressed: onPressed,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Icon(icons.plus, size: 8),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text($.store.productCard.addToCart),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<StoreMenuProductsModel>('product', product))
          ..add(
            ObjectFlagProperty<FutureOr<void> Function()?>.has(
              'onPressed',
              onPressed,
            ),
          ),
      );
}
