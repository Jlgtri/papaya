import 'dart:async';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
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
@immutable
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
          child: Material(
            color: theme.colorScheme.onBackground,
            child: Stack(
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
@immutable
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
    final AsyncValue<Iterable<StoreMenuModel>?> menu =
        ref.watch(storeMenuProvider(store.id!));

    final Map<int, GlobalKey> menuKeys = useMemoized(() => <int, GlobalKey>{});
    final SyncCallback syncCallback = useSyncCallback();
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
    if (menu.asData?.value?.isEmpty ?? true) {
      scrollable = CustomScrollView(
        slivers: <Widget>[
          ...storeInformation,
          if (!menu.isLoading)
            SliverToBoxAdapter(
              child: Material(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    /// Title
                    const SizedBox(height: 64),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        $.store.empty,
                        style: theme.textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    /// Back Button
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 38),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        onPressed: navigator.maybePop,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(icons.misc.arrowLeft, size: 14),
                              ),
                              const SizedBox(width: 12),
                              Flexible(child: Text($.store.emptyReturn))
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
        ],
      );
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
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: TabBar(
                        isScrollable: true,
                        indicatorPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        splashBorderRadius: BorderRadius.circular(8),
                        onTap: (final int index) async {
                          final GlobalKey? menuKey =
                              menuKeys[menu.value?.elementAtOrNull(index)?.id];
                          final RenderObject? object =
                              menuKey?.currentContext?.findRenderObject();
                          if (object != null) {
                            final ScrollableState scrollable =
                                Scrollable.of(menuKey!.currentContext!)!;
                            await scrollable.position.ensureVisible(
                              object,
                              duration: const Duration(milliseconds: 333),
                            );
                          }
                        },
                        tabs: <Widget>[
                          for (final StoreMenuModel menu in menu.value!)
                            if (menu.name != null && menu.products != null)
                              Tab(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(menu.name!),
                                  ),
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
            child: NotificationListener<ScrollNotification>(
              onNotification: (final ScrollNotification notification) {
                // Retrieve the RenderObject, linked to a specific item
                final RenderObject? notificationObject =
                    notification.context?.findRenderObject();
                // Retrieve the viewport related to the scroll area
                final RenderNestedScrollViewViewport? viewport =
                    RenderAbstractViewport.of(notificationObject)
                        as RenderNestedScrollViewViewport?;
                final ScrollPosition? offset =
                    viewport?.offset as ScrollPosition?;
                if (viewport == null ||
                    // Fixes assertion error
                    offset!.pixels < offset.maxScrollExtent - 1) {
                  return false;
                }
                for (int index = 0;
                    index < (menu.valueOrNull?.length ?? 0);
                    index++) {
                  // Retrieve the RenderObject, linked to a specific item
                  final RenderObject? object =
                      menuKeys[menu.valueOrNull?.elementAt(index).id]
                          ?.currentContext
                          ?.findRenderObject();
                  if (object != null && object.attached) {
                    // Check if the item is in the viewport
                    final double deltaTop =
                        viewport.getOffsetToReveal(object, 0).offset -
                            notification.metrics.pixels;
                    final double deltaBottom =
                        deltaTop + object.semanticBounds.size.height;
                    if (deltaTop >= 0 &&
                            deltaTop < viewport.paintBounds.height ||
                        deltaBottom > 0 &&
                            deltaBottom < viewport.paintBounds.height) {
                      final TabController? tabController =
                          DefaultTabController.of(notification.context!);
                      if (tabController != null &&
                          tabController.index != index) {
                        tabController.animateTo(
                          index,
                          duration: const Duration(milliseconds: 233),
                        );
                      }
                      break;
                    }
                  }
                }
                return false;
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final StoreMenuModel $menu in menu.value!)
                        if ($menu.name != null &&
                            $menu.products != null) ...<Widget>[
                          Column(
                            key: menuKeys.putIfAbsent($menu.id!, GlobalKey.new),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 40),
                              Flexible(
                                child: Text(
                                  $menu.name!,
                                  style: theme.textTheme.displayMedium,
                                ),
                              ),
                              const SizedBox(height: 28),
                              ...$menu.products!.map(
                                (final StoreMenuProductsModel product) =>
                                    Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: StoreProductCard(
                                    product,
                                    onPressed: () async => syncCallback(
                                      () => navigator.pushNamed(
                                        Routes.product.name,
                                        arguments:
                                            ProductScreen(store, product),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      SizedBox(height: mediaQuery.padding.bottom + 81),
                    ],
                  ),
                ),
              ),
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

/// The widget used to load information about a [store].
@immutable
class StoreInformationLoader extends HookConsumerWidget {
  /// The widget used to load information about a [store].
  const StoreInformationLoader(this.store, {super.key});

  /// The store to show information for.
  final StoreModel store;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final DeliveryType? deliveryType =
        ref.watch(deliveryTypeProvider.select((final _) => _.valueOrNull));
    final DeliveryType? prevDeliveryType =
        usePrevious<DeliveryType?>(deliveryType);
    return deliveryType != null || prevDeliveryType != null
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: StoreInformation(
              store,
              deliveryType: deliveryType ?? prevDeliveryType!,
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
@immutable
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
    final IsMounted isMounted = useIsMounted();
    final SyncCallback syncCallback = useSyncCallback();
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /// Limited Time
              Stack(
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

              const SizedBox(height: 24),

              /// Name
              if (store.name?.isNotEmpty ?? false)
                Text(
                  store.name!,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.surface,
                  ),
                  maxLines: 2,
                ),

              /// Description
              if (store.description?.isNotEmpty ?? false) ...<Widget>[
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    store.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ),
              ],

              /// Tags
              const SizedBox(height: 40),
              Padding(
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
                      '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.surface,
                      ),
                      maxLines: 1,
                    ),
                    if (store.cuisines?.firstOrNull?.isNotEmpty ??
                        false) ...<Widget>[
                      const SizedBox(width: 48),
                      Icon(
                        icons.cuisine,
                        size: 24,
                        color: theme.colorScheme.surface,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        store.cuisines!.first,
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
                    onPressed: () async => syncCallback(() async {
                      final StoreModel? $store =
                          await ref.read(storeProvider(store.id!).future);
                      if ($store != null) {
                        await rootNavigator.pushNamed(
                          Routes.storeInformation.name,
                          arguments: StoreInformationScreen($store),
                        );
                      } else if (isMounted()) {
                        // ignore: use_build_context_synchronously
                        await rootNavigator.pushNamed(
                          Routes.storeInformationInvalid.name,
                          arguments: StoreInformationInvalidScreen(store),
                        );
                      }
                    }),
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
        ),

        /// Picker (Show loading state on error)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding:
                EdgeInsets.only(top: 64, bottom: rootMediaQuery.padding.bottom),
            child: StoreInformationDeliveryTypeSwitcherLoader(
              store,
              deliveryType: deliveryType,
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

/// The widget used to load a [StoreInformationDeliveryTypeSwitcher].
@immutable
class StoreInformationDeliveryTypeSwitcherLoader extends HookConsumerWidget {
  /// The widget used to load a [StoreInformationDeliveryTypeSwitcher].
  const StoreInformationDeliveryTypeSwitcherLoader(
    this.store, {
    required this.deliveryType,
    super.key,
  });

  /// The store to show information for.
  final StoreModel store;

  /// The current active [DeliveryType].
  final DeliveryType deliveryType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<StoreEtaModel?> deliveryTime =
        ref.watch(storeEtaDeliveryProvider(store.id!));
    final AsyncValue<StoreEtaModel?> pickupTime =
        ref.watch(storeEtaPickupProvider(store.id!));
    return (!deliveryTime.isLoading && !pickupTime.isLoading) &&
            ref.watch(
              storeMenuProvider(store.id!).select((final _) => !_.isLoading),
            )
        ? StoreInformationDeliveryTypeSwitcher(
            deliveryTime.valueOrNull,
            pickupTime.valueOrNull,
            deliveryType: deliveryType,
          )
        : const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator.adaptive()),
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
@immutable
class StoreInformationDeliveryTypeSwitcher extends HookConsumerWidget {
  /// The switcher of [Settings.deliveryType] on [StoreScreen].
  const StoreInformationDeliveryTypeSwitcher(
    this.deliveryTime,
    this.pickupTime, {
    required this.deliveryType,
    super.key,
  });

  /// The delivery time to show in this switcher.
  final StoreEtaModel? deliveryTime;

  /// The pickup time to show in this switcher.
  final StoreEtaModel? pickupTime;

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
        if (deliveryType == $deliveryType) {
          return;
        }
        switch ($deliveryType) {
          case DeliveryType.delivery:
            if (deliveryTime?.min == null || deliveryTime?.max == null) {
              return;
            }
            break;
          case DeliveryType.pickup:
            if (pickupTime?.min == null || pickupTime?.max == null) {
              return;
            }
            break;
        }
        final Isar isar = await ref.read(isarProvider.future);
        final Settings settings = await ref.read(settingsProvider.future)
          ..deliveryType = $deliveryType;
        await isar.writeTxn(() => isar.settings.put(settings));
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
                        begin: theme.colorScheme.shadow,
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
                          begin: theme.colorScheme.shadow,
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
            DiagnosticsProperty<StoreEtaModel>('deliveryTime', deliveryTime),
          )
          ..add(DiagnosticsProperty<StoreEtaModel>('pickupTime', pickupTime))
          ..add(EnumProperty<DeliveryType?>('deliveryType', deliveryType)),
      );
}

/// The [StoreMenuProductsModel.name] property should not be null.
@immutable
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
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorWidget: (final _, final __, final ___) =>
                        Image.asset(assets.logo, fit: BoxFit.cover),
                  ),

                  /// Image
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
                    if (product.name?.isNotEmpty ?? false)
                      Text(
                        product.name!,
                        style: theme.textTheme.headlineMedium,
                      ),

                    /// Description
                    if (product.description?.isNotEmpty ?? false) ...<Widget>[
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          product.description!,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    /// Footer
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        /// Price
                        Flexible(
                          child: Text(
                            r'$' +
                                ((product.price ?? 0) / 100).toStringAsFixed(2),
                            style: theme.textTheme.headlineSmall,
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
