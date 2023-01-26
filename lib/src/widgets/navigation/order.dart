import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../const.dart';
import '../../generated/assets.g.dart';
import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../models/cart_store.dart';
import '../../models/settings.dart';
import '../../providers/api.dart';
import '../../providers/location.dart';
import '../../routes.dart';

/// The screen used to display an ongoing [order].
@immutable
class OrderScreen extends HookConsumerWidget {
  /// The screen used to display an ongoing [order].
  const OrderScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final SyncCallback syncCallback = useSyncCallback();
    final StoreModel? store = ref.watch(
      allStoresProvider.select((final _) => _.valueOrNull?.firstOrNull),
    );
    const DeliveryType deliveryType = DeliveryType.delivery;
    final AsyncValue<Iterable<LatLng>>? storeLocation =
        store?.address?.displayLong?.isNotEmpty ?? true
            ? null
            : ref.watch(locationProvider(store!.address!.displayLong!));
    return WillPopScope(
      onWillPop: () async {
        if (navigator.canPop()) {
          return true;
        }
        WidgetsBinding.instance.addPostFrameCallback(
          (final _) => syncCallback(
            () async => navigator.pushReplacementNamed(
              (await Routes.current(container)).name,
            ),
          ),
        );
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: theme.colorScheme.surface,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: theme.colorScheme.surface,
        ),
        child: ColoredBox(
          color: theme.colorScheme.surface,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppBar(
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: theme.colorScheme.surface,
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light,
                    systemNavigationBarIconBrightness: Brightness.dark,
                    systemNavigationBarColor: theme.colorScheme.surface,
                  ),
                  leadingWidth: double.infinity,
                  leading: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: TextButton(
                        onPressed: () async => syncCallback(navigator.maybePop),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(icons.arrow.left, size: 14),
                              const SizedBox(width: 12),
                              Flexible(child: Text($.store.back))
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                /// Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(bottom: 24, top: 8),
                  child: Text(
                    $.orders.screen.title,
                    style: theme.textTheme.displayMedium,
                  ),
                ),

                /// Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: ColoredBox(
                      color: theme.colorScheme.surfaceTint,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            /// Store Name
                            const SizedBox(height: 24),
                            if (store?.name?.isNotEmpty ?? false) ...<Widget>[
                              Text(
                                store!.name!,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                            ],

                            /// Order Number
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                /// Title
                                Text(
                                  $.orders.screen.number,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '#12345',
                                  style: theme.textTheme.titleMedium,
                                )
                              ],
                            ),

                            /// Delivery Time
                            Text(
                              () {
                                final String time =
                                    DateFormat('h:mm a').format(DateTime.now());
                                switch (deliveryType) {
                                  case DeliveryType.delivery:
                                    return $.orders.card.estimate
                                        .delivery(time);
                                  case DeliveryType.pickup:
                                    return $.orders.card.estimate.pickup(time);
                                }
                              }(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            Divider(
                              height: 32,
                              color: theme.colorScheme.outline,
                            ),
                            if (storeLocation is AsyncLoading)
                              const Center(
                                child: CircularProgressIndicator.adaptive(),
                              )
                            else if (storeLocation?.valueOrNull?.firstOrNull ==
                                null)
                              ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                child: SizedBox(
                                  height: 232,
                                  child: CachedNetworkImage(
                                    imageUrl: store?.imgUrl ?? '',
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    errorWidget:
                                        (final _, final __, final ___) =>
                                            Image.asset(
                                      assets.logo,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                child: FlutterMap(
                                  options: MapOptions(
                                    keepAlive: true,
                                    zoom: 14,
                                    center: storeLocation!.value!.first,
                                    interactiveFlags: InteractiveFlag.none,
                                  ),
                                  children: <Widget>[
                                    TileLayer(
                                      urlTemplate: mapTileUrl,
                                      minZoom: 4,
                                    ),
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
                              ),
                            const SizedBox(height: 16),
                            Text(
                              $.orders.screen.trackTitle,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Text(
                                  'delivery.com/order123456',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    fixedSize: const Size.square(28),
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  onPressed: () async => FlutterClipboard.copy(
                                    'delivery.com/order123456',
                                  ),
                                  icon: Padding(
                                    padding: const EdgeInsets.only(bottom: 1),
                                    child: Icon(icons.copy, size: 16),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                )
                              ],
                            ),

                            /// Support / Add a Tip
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                /// Support
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text($.orders.screen.support),
                                    ),
                                  ),
                                ),

                                /// Add a Tip
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text($.orders.screen.tip),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            Divider(
                              height: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            const OrderDetails(),
                            Divider(
                              height: 32,
                              color: theme.colorScheme.outline,
                            ),

                            /// Total Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                /// Title
                                Text(
                                  $.orders.card.details.total,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  r'$59.80',
                                  style: theme.textTheme.titleLarge,
                                )
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: mediaQuery.padding.bottom + 150),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The widget used to display the details of an [order].
@immutable
class OrderDetails extends StatelessWidget {
  /// The widget used to display the details of an [order].
  const OrderDetails({super.key});

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Order Details Title
        Text(
          $.orders.card.details.title,
          style: theme.textTheme.titleMedium,
        ),

        /// Column Names
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            /// Title
            Text(
              $.orders.card.details.product.title,
              style: theme.textTheme.bodyLarge,
            ),

            /// Price
            Text(
              $.orders.card.details.product.price,
              style: theme.textTheme.bodyLarge,
            )
          ],
        ),

        /// Products
        const SizedBox(height: 8),
        for (final CartStoreProduct product in <CartStoreProduct>[])
          if (product.amount > 0) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                /// Image
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: CachedNetworkImage(
                    height: 52,
                    width: 52,
                    imageUrl: product.product?.imgUrl ?? '',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorWidget: (final _, final __, final ___) =>
                        Image.asset(assets.logo, fit: BoxFit.cover),
                  ),
                ),

                /// Name / Quantity
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        product.product?.name ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'x${product.amount}',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),

                /// Price
                const SizedBox(width: 16),
                Text(
                  r'$32.85',
                  style: theme.textTheme.bodyLarge,
                )
              ],
            ),
            const SizedBox(height: 8),
          ],

        /// Delivery Price
        if (true) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              /// Icon
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: ColoredBox(
                  color: theme.colorScheme.secondary,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      icons.delivery,
                      color: theme.colorScheme.surface,
                      size: 24,
                    ),
                  ),
                ),
              ),

              /// Name / Quantity
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  $.orders.card.details.delivery,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              /// Price
              const SizedBox(width: 16),
              Text(
                r'$8.00',
                style: theme.textTheme.titleMedium,
              )
            ],
          ),
          const SizedBox(height: 8),
        ],

        /// Tax
        if (true) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              /// Icon
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: ColoredBox(
                  color: theme.colorScheme.secondary,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      icons.tax,
                      color: theme.colorScheme.surface,
                      size: 24,
                    ),
                  ),
                ),
              ),

              /// Name / Quantity
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Text(
                      $.orders.card.details.tax,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    /// Tooltip
                    const SizedBox(width: 4),
                    IconButton(
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      onPressed: () {},
                      icon: Padding(
                        padding: const EdgeInsets.all(8).copyWith(bottom: 9),
                        child: Icon(icons.info, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              /// Price
              const SizedBox(width: 8),
              Text(
                r'$8.00',
                style: theme.textTheme.titleMedium,
              )
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
