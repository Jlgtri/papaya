import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../generated/assets.g.dart';
import '../../../generated/i18n.g.dart';
import '../../../generated/icons.g.dart';
import '../../../generated/models.g.dart';
import '../../../hooks/sync_callback_hook.dart';
import '../../../models/cart_store.dart';
import '../../../models/settings.dart';
import '../../../providers/api.dart';
import '../../../providers/misc.dart';
import '../../../routes.dart';
import '../../../styles.dart';
import '../../store/store.dart';

/// The screen used to display advertisments and stores.
@immutable
class HomeScreen extends HookConsumerWidget {
  /// The screen used to display advertisments and stores.
  const HomeScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final I18N $ = I18NLocalizations.of(context);

    final bool isDelivery = ref.watch(
      deliveryTypeProvider
          .select((final _) => _.valueOrNull == DeliveryType.delivery),
    );
    final AsyncValue<Iterable<StoreModel>?> stores =
        ref.watch(filteredStoresProvider);
    final bool showAllStores = ref.watch(
      storesProvider.select(
        (final _) =>
            _.asData?.value != null &&
            stores.asData?.value != null &&
            _.value!.length != stores.value!.length,
      ),
    );
    final AsyncValue<CarouselModel?> carousel = ref.watch(carouselProvider);
    final Iterable<CarouselStoriesModel>? stories =
        carousel.valueOrNull?.stories;

    final SyncCallback syncCallback = useSyncCallback();
    final PageController pageController = usePageController(initialPage: 999);
    useMemoized(
      () => Timer.periodic(
        const Duration(seconds: 30),
        (final _) async => pageController.positions.isNotEmpty
            ? pageController.nextPage(
                duration: const Duration(milliseconds: 433),
                curve: Curves.ease,
              )
            : null,
      ),
    );
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
      child: CustomScrollView(
        slivers: <Widget>[
          if (isDelivery &&
              ref.watch(
                storesProvider.select(
                  (final AsyncValue<Iterable<StoreModel>?> stores) =>
                      stores.valueOrNull?.isEmpty ?? true,
                ),
              )) ...<Widget>[
            const SliverFillRemaining(
              hasScrollBody: false,
              child: StoresNotFoundUpper(),
            ),
            const SliverToBoxAdapter(child: StoresNotFoundLower())
          ] else ...<Widget>[
            /// Carousel With Indicator
            if (carousel.isLoading)
              SliverFillRemaining(
                child: ColoredBox(
                  color: theme.colorScheme.onBackground,
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              )
            else if (carousel.asData != null && stories != null)
              SliverFillRemaining(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  fit: StackFit.expand,
                  children: <Widget>[
                    /// Carousel
                    PageView.builder(
                      controller: pageController,
                      itemBuilder: (final _, final int index) {
                        final CarouselStoriesModel story =
                            stories.elementAt(index % stories.length);
                        return CarouselPage(
                          story,
                          navigateToStoreAtIndex: index % stories.length,
                          key: PageStorageKey<int?>(story.id),
                        );
                      },
                    ),

                    /// Indicator
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: SmoothPageIndicator(
                          controller: pageController,
                          count: stories.length,
                          effect: ColorTransitionEffect(
                            spacing: 12,
                            radius: 8,
                            dotColor: theme.colorScheme.surface,
                            activeDotColor: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            /// Stores Title / Show All Stores
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 40)
                        .copyWith(right: 14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        isDelivery ? $.home.storesNearby : $.home.storesAll,
                        style:
                            theme.textTheme.displayMedium?.copyWith(height: 1),
                      ),
                    ),
                    if (showAllStores)
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            textStyle: theme.textTheme.titleMedium,
                          ),
                          onPressed: () async => syncCallback(
                            () => rootNavigator.pushNamed(Routes.stores.name),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(icons.arrow.right, size: 14),
                                const SizedBox(width: 12),
                                Flexible(child: Text($.home.storesViewAll)),
                              ],
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),

            /// Stores List
            if (stores.valueOrNull != null)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (final _, final int index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16)
                        .copyWith(bottom: 24),
                    child: StoreCard(stores.value!.elementAt(index)),
                  ),
                  childCount: stores.value!.length,
                ),
              )
            else if (stores.isLoading)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 69)),
          ]
        ],
      ),
    );
  }
}

/// The widget used to display a carousel [story].
@immutable
class CarouselPage extends HookConsumerWidget {
  /// The widget used to display a carousel [story].
  const CarouselPage(this.story, {this.navigateToStoreAtIndex, super.key});

  /// The story to show on this page.
  final CarouselStoriesModel story;

  /// The index of the store to navigate to from this page.
  final int? navigateToStoreAtIndex;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);

    final SyncCallback syncCallback = useSyncCallback();
    return ColoredBox(
      color: theme.colorScheme.onBackground,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          /// Background Image
          CachedNetworkImage(
            imageUrl: story.content?.image?.filename ?? '',
            imageBuilder:
                (final _, final ImageProvider<Object> imageProvider) =>
                    DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  transform: const GradientRotation(0.284663201),
                  stops: const <double>[0.1723, 0.4654, 1],
                  colors: <Color>[
                    Colors.black.withOpacity(0.78),
                    Colors.black.withOpacity(0.69),
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

          /// Information Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 64,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (story.content?.header?.isNotEmpty ?? false)
                  Text(
                    story.content!.header!,
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: theme.colorScheme.surface,
                    ),
                    maxLines: 3,
                  ),
                if (story.content?.text?.isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: 24),
                  Flexible(
                    child: Text(
                      story.content!.text!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.surface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 0),
                  ),
                  onPressed: () async => syncCallback(() async {
                    if (story.content?.link?.isNotEmpty ?? false) {
                      await launchUrlString(story.content!.link!);
                    } else if (navigateToStoreAtIndex != null) {
                      final StoreModel? store = await ref.read(
                        allStoresProvider.selectAsync(
                          (final _) =>
                              _ != null && _.length > navigateToStoreAtIndex!
                                  ? _.elementAt(navigateToStoreAtIndex!)
                                  : null,
                        ),
                      );
                      if (store != null) {
                        await rootNavigator.pushNamed(
                          Routes.store.name,
                          arguments: StoreScreen(store),
                        );
                      }
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(story.content?.cta ?? $.home.viewDetail),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<CarouselStoriesModel>('story', story))
          ..add(IntProperty('navigateToStoreAtIndex', navigateToStoreAtIndex)),
      );
}

/// The upper part of a screen used when [nearbyStoresProvider] is empty.
@immutable
class StoresNotFoundUpper extends HookConsumerWidget {
  /// The upper part of a screen used when [nearbyStoresProvider] is empty.
  const StoresNotFoundUpper({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final I18N $ = I18NLocalizations.of(context);

    final AsyncValue<DeliveryType> isDelivery = ref.watch(deliveryTypeProvider);
    final AsyncValue<UserAddressesModel?> activeAddress =
        ref.watch(currentAddressProvider);
    final UserAddressesModel? prevActiveAddress =
        usePrevious<UserAddressesModel?>(activeAddress.valueOrNull);
    final UserAddressesModel? address =
        activeAddress.valueOrNull ?? prevActiveAddress;

    final StoreModel? store = ref.watch(
      cartProvider.select(
        (final _) =>
            _.whenOrNull<StoreModel?>(data: (final _) => _.firstOrNull?.store),
      ),
    );

    String? eta;
    if (address == null) {
      eta = $.home.addressHint;
    } else if (store?.id == null) {
      eta = $.home.storeHint;
    }
    final String? prevEta = usePrevious<String?>(eta);

    if (isDelivery is! AsyncData || isDelivery.valueOrNull == null) {
      eta ??= prevEta;
    } else if (address != null && store?.id != null) {
      switch (isDelivery.value!) {
        case DeliveryType.delivery:
          eta = ref.watch(
            storeEtaDeliveryProvider(store!.id!).select(
              (final _) =>
                  _.whenOrNull<String?>(
                    data: (final _) => _?.min != null && _?.max != null
                        ? $.delivery.deliveryToTime(
                            _!.min!,
                            _.max!,
                            address.displayLong!,
                          )
                        : null,
                  ) ??
                  $.home.storeHint,
            ),
          );
          break;

        case DeliveryType.pickup:
          eta = ref.watch(
            storeEtaPickupProvider(store!.id!).select(
              (final _) =>
                  _.whenOrNull<String?>(
                    data: (final _) => _?.min != null && _?.max != null
                        ? $.delivery.pickupFromTime(
                            _!.min!,
                            _.max!,
                            address.displayLong!,
                          )
                        : null,
                  ) ??
                  $.home.storeHint,
            ),
          );
      }
    }

    final SyncCallback syncCallback = useSyncCallback();
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        /// Background
        ColoredBox(
          color: theme.colorScheme.onBackground,
          child: const SizedBox.expand(),
        ),

        /// Image 1 (Bottom Right)
        Positioned(
          right: -69,
          child: Image.asset(assets.waitingList1),
        ),

        /// Information
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 56,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Title
              Text(
                $.home.searchNotFound.title,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.surface,
                ),
              ),

              /// Description
              const SizedBox(height: 24),
              Text(
                $.home.searchNotFound.description,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.surface,
                ),
              ),

              /// Delivery To
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    icons.marker,
                    color: theme.colorScheme.surface,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      eta ?? $.home.addressHint,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.surface,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),

              /// Change Delivery Address
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 0),
                ),
                onPressed: () async => syncCallback(
                  () => rootNavigator.pushNamed(Routes.delivery.name),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    $.home.searchNotFound.changeDeliveryAdress,
                  ),
                ),
              ),

              /// Switch to Pickup
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 0),
                  foregroundColor: theme.colorScheme.surface,
                  backgroundColor: theme.colorScheme.onBackground,
                  side: BorderSide(color: theme.colorScheme.surface),
                ),
                onPressed: () async => syncCallback(() async {
                  final Isar isar = await ref.read(isarProvider.future);
                  final Settings settings =
                      await ref.read(settingsProvider.future)
                        ..deliveryType = DeliveryType.pickup;
                  await isar.writeTxn(() => isar.settings.put(settings));
                }),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text($.home.searchNotFound.switchToPickup),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The lower part of a screen used when [nearbyStoresProvider] is empty.
@immutable
class StoresNotFoundLower extends HookConsumerWidget {
  /// The lower part of a screen used when [nearbyStoresProvider] is empty.
  const StoresNotFoundLower({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return Stack(
      alignment: Alignment.topRight,
      children: <Widget>[
        ColoredBox(
          color: theme.colorScheme.secondary,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 60),
                Flexible(
                  child: Text(
                    $.home.searchNotFound.joinWaitingListTitle,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Text(
                    $.home.searchNotFound.joinWaitingListDescription,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Text($.home.searchNotFound.joinWaitingList),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -69,
          child: Image.asset(assets.waitingList2),
        ),
      ],
    );
  }
}

/// The [StoreModel.name] property should not be null.
@immutable
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
    final SyncCallback syncCallback = useSyncCallback();
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: <BoxShadow>[boxShadow(theme)]),
      child: Material(
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: InkWell(
          onTap: () async => syncCallback(
            () => rootNavigator.pushNamed(
              Routes.store.name,
              arguments: StoreScreen(store),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /// Image
              CachedNetworkImage(
                imageUrl: store.imgUrl ?? '',
                fit: BoxFit.cover,
                height: 176,
                filterQuality: FilterQuality.high,
                errorWidget: (final _, final __, final ___) =>
                    Image.asset(assets.logo, fit: BoxFit.cover),
              ),

              /// Name
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  store.name!,
                  style: theme.textTheme.headlineMedium,
                  maxLines: 1,
                ),
              ),

              /// Description
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  store.description ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.shadow,
                  ),
                  maxLines: 2,
                ),
              ),

              /// Icons
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    /// Kitchen Type
                    if (store.kitchenType?.isNotEmpty ?? false)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            icons.vegan,
                            color: theme.colorScheme.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            store.kitchenType!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xff484850),
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),

                    /// Cuisines
                    if (store.cuisines != null)
                      for (final String cuisine in store.cuisines!)
                        if (cuisine.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Icon(
                                  icons.cuisine,
                                  color: theme.colorScheme.secondary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cuisine,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xff484850),
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),

                    /// Price Range
                    Flexible(
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
                                        color: theme.colorScheme.surface,
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
              ),
              const SizedBox(height: 16),
            ],
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
