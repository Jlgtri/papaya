import 'dart:async';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../const.dart';
import '../generated/assets.g.dart';
import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../generated/models.g.dart';
import '../models/settings.dart';
import '../providers/location_providers.dart';
import '../routes.dart';
import '../styles.dart';
import 'product_screen.dart';

/// The screen used to show off a store from [provider].
class StoreScreen extends HookConsumerWidget {
  /// The screen used to show off a store from [provider].
  const StoreScreen({this.deliveryType, super.key});

  /// The initial delivery type to show on this screen.
  final DeliveryType? deliveryType;

  /// The provider of the store to show on this screen.
  static final StateProvider<StoreModel?> provider =
      StateProvider<StoreModel?>((final _) => null);

  /// The provider of the [provider]'s eta for [DeliveryType.delivery].
  static final StateProvider<StoreEtaDeliveryModel?> etaDeliveryProvider =
      StateProvider<StoreEtaDeliveryModel?>((final _) => null);

  /// The provider of the [provider]'s eta for [DeliveryType.pickup].
  static final StateProvider<StoreEtaPickupModel?> etaPickupProvider =
      StateProvider<StoreEtaPickupModel?>((final _) => null);

  /// The provider of the [provider]'s eta for [DeliveryType.pickup].
  static final StateProvider<StoreOperationDaysModel?> workingTimeProvider =
      StateProvider<StoreOperationDaysModel?>((final _) => null);

  /// The provider of the [StoreMenuModel]'s for [provider].
  static final StateProvider<Iterable<StoreMenuModel>> menuProvider =
      StateProvider<Iterable<StoreMenuModel>>(
    (final _) => const Iterable<StoreMenuModel>.empty(),
  );

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final Iterable<StoreMenuModel> menu = ref.watch(menuProvider);
    final String storeImg =
        ref.watch(provider.select((final _) => _?.imgUrl ?? ''));
    return WillPopScope(
      onWillPop: () async {
        if (navigator.canPop()) {
          return true;
        }
        await Routes.navigation.pushReplacement(navigator, ref);
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: theme.colorScheme.surface,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: theme.colorScheme.onBackground,
          body: DefaultTabController(
            length: menu.length,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(
                  imageUrl: storeImg,
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

                /// Fixes: https://github.com/flutter/flutter/issues/104798
                ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(overscroll: false),
                  child: NestedScrollView(
                    headerSliverBuilder:
                        (final _, final bool innerBoxIsScrolled) => <Widget>[
                      SliverAppBar(
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
                              onPressed: navigator.maybePop,
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
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StoreInformation(deliveryType: deliveryType),
                      ),
                      if (menu.isNotEmpty) ...<Widget>[
                        SliverAppBar(
                          pinned: true,
                          backgroundColor: theme.colorScheme.surface,
                          systemOverlayStyle: const SystemUiOverlayStyle(
                            statusBarColor: Colors.transparent,
                            statusBarIconBrightness: Brightness.dark,
                            statusBarBrightness: Brightness.light,
                            systemNavigationBarIconBrightness: Brightness.dark,
                            systemNavigationBarColor: Colors.transparent,
                          ),
                          automaticallyImplyLeading: false,
                          toolbarHeight: 0,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(48),
                            child: Material(
                              child: TabBar(
                                isScrollable: true,
                                indicatorPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                splashBorderRadius: BorderRadius.circular(8),
                                tabs: <Tab>[
                                  for (final StoreMenuModel menu in menu)
                                    if (menu.name != null &&
                                        menu.products != null)
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
                    ],
                    body: Material(
                      child: TabBarView(
                        children: <Widget>[
                          for (final StoreMenuModel menu in menu)
                            if (menu.name != null && menu.products != null)
                              SingleChildScrollView(
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
                                    ...menu.products!.map(ProductCard.new).map(
                                          (final Widget child) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: child,
                                          ),
                                        ),
                                    const SizedBox(height: 81),
                                  ],
                                ),
                              ),
                        ],
                      ),
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
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties
        ..add(EnumProperty<DeliveryType?>('deliveryType', deliveryType)),
    );
  }
}

class _StoreInformation extends HookConsumerWidget {
  const _StoreInformation({this.deliveryType});

  final DeliveryType? deliveryType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final IsMounted isMounted = useIsMounted();
    final ValueNotifier<DeliveryType> deliveryType =
        useState(this.deliveryType ?? Settings().deliveryType);

    unawaited(
      useMemoized(() async {
        if (this.deliveryType == null) {
          final DeliveryType $deliveryType =
              await ref.read(deliveryTypeProvider.future);
          if (isMounted()) {
            deliveryType.value = $deliveryType;
          }
        }
      }),
    );

    final StoreModel? store = ref.read(StoreScreen.provider);
    if (store == null || store.name == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
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
                  store.name!,
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
                    onPressed: () async =>
                        Routes.storeInformation.push(navigator, ref, store),
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

          /// Picker
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomAnimatedToggleSwitch<DeliveryType>(
              height: 72,
              values: DeliveryType.values,
              current: deliveryType.value,
              onChanged: (final DeliveryType $deliveryType) =>
                  deliveryType.value = $deliveryType,
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
              wrapperBuilder: (final _, final __, final Widget child) =>
                  Material(
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
                                    final StoreEtaDeliveryModel deliveryTime =
                                        ref.watch(
                                      StoreScreen.etaDeliveryProvider,
                                    )!;
                                    return $.store.deliveryTime(
                                      deliveryTime.min!,
                                      deliveryTime.max!,
                                    );
                                  case DeliveryType.pickup:
                                    final StoreEtaPickupModel pickupTime =
                                        ref.watch(
                                      StoreScreen.etaPickupProvider,
                                    )!;
                                    return $.store.deliveryTime(
                                      pickupTime.min!,
                                      pickupTime.max!,
                                    );
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties
        ..add(EnumProperty<DeliveryType?>('deliveryType', deliveryType)),
    );
  }
}

/// The [StoreModel.name] property should not be null.
class StoreCard extends HookConsumerWidget {
  /// The [StoreModel.name] property should not be null.
  const StoreCard(this.store, {super.key});

  /// The store to diplay in this card.
  final StoreModel store;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: <BoxShadow>[boxShadow(theme)]),
      child: Material(
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: InkWell(
          onTap: () async => Routes.store.push(rootNavigator, ref, store),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /// Image
              CachedNetworkImage(
                imageUrl: store.imgUrl ?? '',
                fit: BoxFit.fitWidth,
                height: 176,
                filterQuality: FilterQuality.high,
                errorWidget: (final _, final __, final ___) =>
                    Image.asset(assets.logo, fit: BoxFit.fitWidth),
              ),

              const SizedBox(height: 16),

              /// Information
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      /// Name
                      Text(
                        store.name!,
                        style: theme.textTheme.headlineMedium,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),

                      /// Description
                      Text(
                        store.description ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.shadow,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      /// Icons
                      Flexible(
                        child: Row(
                          children: <Widget>[
                            /// Cuisine
                            if ((store.cuisines?.isNotEmpty ?? false) &&
                                store.cuisines?.first.cuisine !=
                                    null) ...<Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Icon(
                                  icons.cuisine,
                                  color: theme.colorScheme.secondary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  store.cuisines?.first.cuisine ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ] else
                              const Expanded(child: SizedBox()),

                            /// Price Range
                            Flexible(
                              fit: FlexFit.tight,
                              child: SizedBox(
                                height: 28,
                                child: Stack(
                                  fit: StackFit.passthrough,
                                  alignment: AlignmentDirectional.centerEnd,
                                  children: <Widget>[
                                    for (int i = (store.priceRange ?? 0) - 1;
                                        i >= 0;
                                        i--)
                                      Positioned(
                                        right: i * 16,
                                        child: IconButton(
                                          style: IconButton.styleFrom(
                                            fixedSize: const Size.square(28),
                                            disabledBackgroundColor:
                                                theme.colorScheme.surfaceTint,
                                            disabledForegroundColor:
                                                theme.colorScheme.secondary,
                                            padding: const EdgeInsets.all(8),
                                            shape: CircleBorder(
                                              side: BorderSide(
                                                color:
                                                    theme.colorScheme.surface,
                                              ),
                                            ),
                                          ),
                                          icon: Icon(icons.price, size: 12),
                                          onPressed: null,
                                        ),
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
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties..add(DiagnosticsProperty<StoreModel>('store', store)),
    );
  }
}

/// The screen used to show off a store information from [StoreScreen.provider].
class StoreInformationScreen extends HookConsumerWidget {
  /// The screen used to show off a store information from
  /// [StoreScreen.provider].
  const StoreInformationScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);

    final StoreModel? store = ref.watch(StoreScreen.provider);
    final ValueNotifier<bool> viewWorkingHours = useState(false);
    final AnimationController animationController = useAnimationController(
      duration: const Duration(milliseconds: 350),
    );
    useMemoized(
      () => viewWorkingHours.addListener(
        () => viewWorkingHours.value
            ? animationController.forward()
            : animationController.reverse(),
      ),
    );
    final String address = store?.address?.firstOrNull?.displayLong ?? '';
    final AsyncValue<Iterable<LatLng>>? storeLocation =
        address.isEmpty ? null : ref.watch(locationProvider(address));
    return Material(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (storeLocation is AsyncLoading)
                  const Center(child: CircularProgressIndicator.adaptive())
                else if (storeLocation?.valueOrNull?.firstOrNull == null)
                  CachedNetworkImage(
                    imageUrl: store?.imgUrl ?? '',
                    fit: BoxFit.fitWidth,
                    filterQuality: FilterQuality.high,
                    errorWidget: (final _, final __, final ___) =>
                        Image.asset(assets.logo, fit: BoxFit.fitWidth),
                  )
                else
                  FlutterMap(
                    options: MapOptions(
                      keepAlive: true,
                      zoom: 14,
                      center: storeLocation!.value!.first,
                      interactiveFlags: InteractiveFlag.none,
                    ),
                    children: <Widget>[
                      TileLayer(urlTemplate: mapTileUrl, minZoom: 4),
                      MarkerLayer(
                        markers: <Marker>[
                          Marker(
                            point: storeLocation.value!.first,
                            rotate: false,
                            builder: (final _) => Icon(
                              icons.location,
                              color: theme.colorScheme.primary,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                /// Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        fixedSize: const Size.square(32),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.surface,
                      ),
                      icon: Icon(icons.close, size: 13),
                      color: theme.colorScheme.primary,
                      onPressed: navigator.maybePop,
                    ),
                  ),
                ),

                /// Grab Widget
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: theme.colorScheme.onSurface,
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(4),
                      child: const SizedBox(height: 4, width: 36),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Name
          if (store?.name != null) ...<Widget>[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                store!.name!,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  height: 40 / 30,
                ),
                maxLines: 1,
              ),
            ),
          ],

          /// Description
          if (store?.description != null) ...<Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                store!.description!,
                style: theme.textTheme.bodyLarge,
                maxLines: 1,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 0, color: theme.colorScheme.outline),

          /// Address
          TextButton(
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            ),
            onPressed: () async =>
                store?.address?.firstOrNull?.displayLong != null
                    ? FlutterClipboard.copy(
                        store!.address!.firstOrNull!.displayLong!,
                      )
                    : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  icons.marker,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 17.5),
                Expanded(
                  child: Text(
                    store?.address?.firstOrNull?.displayLong ?? '',
                    style: theme.textTheme.bodyLarge,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 32),
                Icon(
                  icons.copy,
                  color: theme.colorScheme.primary,
                  size: 24,
                )
              ],
            ),
          ),

          /// Working Time
          Divider(height: 0, color: theme.colorScheme.outline),
          Flexible(
            child: TextButton(
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: () => viewWorkingHours.value = !viewWorkingHours.value,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      icons.clock,
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedSize(
                        duration: animationController.duration!,
                        curve: Curves.fastOutSlowIn,
                        alignment: Alignment.topCenter,
                        child: _StoreInformationWorkingHours(
                          extended: viewWorkingHours.value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    RotationTransition(
                      turns: Tween<double>(begin: 0, end: 1 / 2).animate(
                        CurvedAnimation(
                          parent: animationController,
                          curve: viewWorkingHours.value
                              ? Curves.easeOut
                              : Curves.easeIn,
                        ),
                      ),
                      child: Icon(
                        icons.misc.arrowDown,
                        color: theme.colorScheme.shadow,
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!viewWorkingHours.value) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StoreInformationWorkingHours extends HookConsumerWidget {
  const _StoreInformationWorkingHours({required this.extended});

  /// If the information should be extended.
  final bool extended;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);

    final StoreOperationDaysModel? workingTime =
        ref.watch(StoreScreen.workingTimeProvider);

    String getWeekDayName(final int weekday) => DateFormat('EEEE').format(
          DateTime.fromMicrosecondsSinceEpoch(0).add(
            Duration(
              days: weekday + 3,
            ),
          ),
        );
    final String currentTime = useMemoized(
      () {
        DateTime fromHours(final DateTime now, final String? hours) {
          final Iterable<String> hoursParts =
              hours?.split(':') ?? const Iterable<String>.empty();
          return DateTime(
            now.year,
            now.month,
            now.day,
            int.tryParse(hoursParts.firstOrNull ?? '') ?? 0,
            hoursParts.length > 1
                ? int.tryParse(hoursParts.lastOrNull ?? '') ?? 0
                : 0,
          );
        }

        final DateTime now = DateTime.now();
        final StoreOperationDaysStoreRegularHoursModel? currentWorkingDay =
            workingTime?.storeRegularHours?.firstWhereOrNull(
          (final _) => _.day == now.weekday,
        );

        final List<StoreOperationDaysStoreRegularHoursModel>?
            sortedWorkingDays = workingTime?.storeRegularHours?.toList()
              ?..sort(
                (final _, final __) => ((_.day ?? -1) > now.weekday ? -1 : 1)
                    .compareTo((__.day ?? -1) > now.weekday ? -1 : 1),
              );
        final StoreOperationDaysStoreRegularHoursModel? nextOpenDay =
            sortedWorkingDays?.firstOrNull;

        final DateTime openNow = fromHours(now, currentWorkingDay?.openTime);
        final DateTime closeNow = fromHours(now, currentWorkingDay?.closeTime);
        return now.isBefore(openNow)
            ? $.store.info.openAt(currentWorkingDay?.openTime ?? '00:00')
            : now.isBefore(closeNow)
                ? $.store.info
                    .openUntil(currentWorkingDay?.closeTime ?? '00:00')
                : $.store.info.openAt(
                    getWeekDayName(nextOpenDay?.day ?? now.weekday) +
                        (nextOpenDay?.openTime ?? '00:00'),
                  );
      },
      <Object?>[$.store.info, workingTime],
    );

    final Iterable<Iterable<StoreOperationDaysStoreRegularHoursModel>>
        currentDays = useMemoized(
      () {
        final List<List<StoreOperationDaysStoreRegularHoursModel>> currentDays =
            <List<StoreOperationDaysStoreRegularHoursModel>>[];
        final Iterable<StoreOperationDaysStoreRegularHoursModel> workingDays =
            (workingTime?.storeRegularHours?.toList()
                  ?..sort(
                    (
                      final StoreOperationDaysStoreRegularHoursModel a,
                      final StoreOperationDaysStoreRegularHoursModel b,
                    ) =>
                        a.day!.compareTo(b.day!),
                  )) ??
                <StoreOperationDaysStoreRegularHoursModel>[];
        for (final StoreOperationDaysStoreRegularHoursModel day
            in workingDays) {
          if (day.day != null) {
            final List<StoreOperationDaysStoreRegularHoursModel>
                localCurrentDays = <StoreOperationDaysStoreRegularHoursModel>[];
            for (final StoreOperationDaysStoreRegularHoursModel $day
                in workingDays) {
              if (day.day != null &&
                  $day.openTime == day.openTime &&
                  $day.closeTime == day.closeTime &&
                  !currentDays.any((final _) => _.contains(day))) {
                localCurrentDays.add($day);
              }
            }
            if (localCurrentDays.isNotEmpty) {
              currentDays.add(localCurrentDays);
            }
          }
        }
        return currentDays;
      },
      <Object?>[workingTime],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Flexible(
          child: Text(
            currentTime,
            style: theme.textTheme.bodyLarge,
            maxLines: 1,
          ),
        ),
        if (extended)
          ...<Widget>[
            const SizedBox(height: 16),
            for (final Iterable<StoreOperationDaysStoreRegularHoursModel> days
                in currentDays) ...<Widget>[
              Flexible(
                child: Text(
                  <String>[
                    <String>[
                      getWeekDayName(days.first.day ?? 1),
                      if (days.length > 1)
                        getWeekDayName(
                          days.last.day ??
                              ((days.first.day ?? 1) + days.length - 1),
                        )
                    ].join(days.length == 2 ? ', ' : ' - '),
                    <String>[
                      days.first.openTime ?? '',
                      days.first.closeTime ?? ''
                    ].join(' - ')
                  ].join(', '),
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
            ]
          ]..removeLast(),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties..add(DiagnosticsProperty<bool>('extended', extended)),
    );
  }
}
