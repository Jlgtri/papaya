import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../generated/assets.g.dart';
import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../models/cart_store.dart';
import '../../models/settings.dart';
import '../../providers/api.dart';
import '../../providers/misc.dart';
import '../../routes.dart';
import '../../styles.dart';
import '../store.dart';

/// The screen used to display advertisments and stores.
class HomeScreen extends HookConsumerWidget {
  /// The screen used to display advertisments and stores.
  const HomeScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final MediaQueryData rootMediaQuery = MediaQuery.of(rootNavigator.context);
    final I18N $ = I18NLocalizations.of(context);

    final SyncCallback syncCallback = useSyncCallback();

    final AsyncValue<Iterable<StoreModel>> stores =
        ref.watch(filteredStoresProvider);
    final bool showAllStores = ref.watch(
      storesProvider.select(
        (final _) =>
            (_ is AsyncData && _.valueOrNull != null) &&
            (stores is AsyncData && stores.valueOrNull != null) &&
            _.value!.length != stores.value!.length,
      ),
    );
    return CustomScrollView(
      slivers: <Widget>[
        if ((ref.watch(
              nearbyStoresProvider.select(
                (final AsyncValue<Iterable<StoreModel>> stores) =>
                    stores.valueOrNull?.isEmpty ?? false,
              ),
            )) &&
            ref.watch(
              deliveryTypeProvider
                  .select((final _) => _.valueOrNull == DeliveryType.delivery),
            )) ...<Widget>[
          const SliverFillRemaining(
            hasScrollBody: false,
            child: StoresNotFoundUpper(),
          ),
          const SliverToBoxAdapter(child: StoresNotFoundLower())
        ] else ...<Widget>[
          /// Carousel with indicator
          SliverFillRemaining(
            child: Stack(
              alignment: Alignment.bottomCenter,
              fit: StackFit.expand,
              children: <Widget>[
                /// Carousel
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onBackground,
                    image: false
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(''),
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 64,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            'BKLYN Wild - Time Out Market',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.colorScheme.surface,
                            ),
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Flexible(
                          child: Text(
                            'Short promotion description goes here',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.surface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 0),
                          ),
                          onPressed: () {},
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text($.home.viewDetail),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Indicator
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: DotsIndicator(
                      dotsCount: 1,
                      position: 0,
                      decorator: DotsDecorator(
                        size: const Size.square(16),
                        activeSize: const Size.square(16),
                        spacing: const EdgeInsets.symmetric(horizontal: 6),
                        color: theme.colorScheme.surface,
                        activeColor: theme.colorScheme.secondary,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40)
                  .copyWith(right: 14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      showAllStores ? $.home.storesAll : $.home.storesNearby,
                      style: theme.textTheme.displayMedium?.copyWith(height: 1),
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
                              Icon(icons.misc.arrowRight, size: 14),
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
          if (stores is AsyncData && stores.valueOrNull != null)
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
          else
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 69)),
        ]
      ],
    );
  }
}

/// The upper part of a screen used when [nearbyStoresProvider] is empty.
class StoresNotFoundUpper extends HookConsumerWidget {
  /// The upper part of a screen used when [nearbyStoresProvider] is empty.
  const StoresNotFoundUpper({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final I18N $ = I18NLocalizations.of(context);

    final AsyncValue<DeliveryType> deliveryType =
        ref.watch(deliveryTypeProvider);
    final AsyncValue<UserAddressesModel?> activeAddress =
        ref.watch(activeAddressProvider);
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

    if (deliveryType is! AsyncData || deliveryType.valueOrNull == null) {
      eta ??= prevEta;
    } else if (address != null && store?.id != null) {
      switch (deliveryType.value!) {
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  height: 32 / 24,
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
                  await isar.writeTxn(
                    () async => isar.settings.put(
                      await ref.read(settingsProvider.future)
                        ..deliveryType = DeliveryType.pickup,
                    ),
                  );
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      height: 32 / 24,
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
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties..add(DiagnosticsProperty<StoreModel>('store', store)),
      );
}
