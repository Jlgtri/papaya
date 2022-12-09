import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../generated/assets.g.dart';
import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../models/cart_store.dart';
import '../../models/settings.dart';
import '../../providers/api.dart';

/// The screen used to display a list of orders.
@immutable
class OrdersScreen extends HookConsumerWidget {
  /// The screen used to display a list of orders.
  const OrdersScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(overscroll: false),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Text(
                $.orders.title,
                style: theme.textTheme.displayMedium,
                maxLines: 1,
              ),
            ),

            /// Current
            if (true) ...<Widget>[
              Padding(
                padding: const EdgeInsets.all(16).copyWith(top: 0),
                child: Text(
                  $.orders.currentTitle,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: OrderCard(
                  current: true,
                  deliveryType: DeliveryType.delivery,
                ),
              ),
              const SizedBox(height: 32),
            ],

            /// History
            if (true) ...<Widget>[
              Padding(
                padding: const EdgeInsets.all(16).copyWith(top: 0),
                child: Text(
                  $.orders.historyTitle,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 174),
            ],
          ],
        ),
      ),
    );
  }
}

/// The widget used to display an [order].
@immutable
class OrderCard extends HookConsumerWidget {
  /// The widget used to display an [order].
  const OrderCard({
    required this.current,
    required this.deliveryType,
    super.key,
  });

  final bool current;
  final DeliveryType deliveryType;

  static final DateFormat _currentDateFormat = DateFormat('h:mm a');
  static final DateFormat _historyDateFormat = DateFormat('DD.MM.YYYY, h:mm a');

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final StoreModel? store = ref.watch(
      allStoresProvider.select((final _) => _.valueOrNull?.firstOrNull),
    );
    final currentAddress = ref.watch(currentAddressProvider);
    final SyncCallback syncCallback = useSyncCallback();
    final ValueNotifier<bool> showMore = useState(false);
    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: ColoredBox(
          color: theme.colorScheme.surfaceTint,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextButton(
                style:
                    TextButton.styleFrom(shape: const RoundedRectangleBorder()),
                onPressed: () => showMore.value = !showMore.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// Store Image
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 116,
                        child: SizedBox.expand(
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            child: CachedNetworkImage(
                              imageUrl: store?.imgUrl ?? '',
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorWidget: (final _, final __, final ___) =>
                                  Image.asset(assets.logo, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Quick Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          /// Status
                          Text(
                            current
                                ? $.orders.card.status.current
                                : $.orders.card.status.completed,
                            style: theme.textTheme.bodySmall,
                          ),

                          /// Dot
                          Material(
                            color: theme.colorScheme.shadow,
                            type: MaterialType.circle,
                            child: const SizedBox(height: 4, width: 4),
                          ),

                          /// Delivery Time
                          Text(
                            current
                                ? () {
                                    final String time = _currentDateFormat
                                        .format(DateTime.now());
                                    switch (deliveryType) {
                                      case DeliveryType.delivery:
                                        return $.orders.card.estimate
                                            .delivery(time);
                                      case DeliveryType.pickup:
                                        return $.orders.card.estimate
                                            .pickup(time);
                                    }
                                  }()
                                : _historyDateFormat.format(DateTime.now()),
                            style: theme.textTheme.bodySmall,
                          ),

                          if (deliveryType == DeliveryType.delivery)
                            if (currentAddress
                                    .asData?.value?.displayLong?.isNotEmpty ??
                                false) ...<Widget>[
                              /// Dot
                              Material(
                                color: theme.colorScheme.shadow,
                                type: MaterialType.circle,
                                child: const SizedBox(height: 4, width: 4),
                              ),

                              /// Delivery Addess

                              Text(
                                currentAddress.value!.displayLong!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                        ],
                      ),
                    ),

                    /// Store Name
                    if (store?.name?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Text(
                          store!.name!,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),

                    /// Product Names
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Pollo Di Pastore, Arugula with Avocado',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),

                    /// Total
                    Padding(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                      child: Text(
                        r'$59.80',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),

                    /// More/Less Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            showMore.value
                                ? $.orders.card.less
                                : $.orders.card.more,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          AnimatedRotation(
                            turns: showMore.value ? 0 : -1 / 4,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                            child: Icon(
                              icons.arrow.down,
                              color: theme.colorScheme.primary,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showMore.value) ...<Widget>[
                Divider(height: 0, color: theme.colorScheme.outline),

                /// Order Details Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    $.orders.card.details.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),

                /// Column Names
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(bottom: 8),
                  child: Row(
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
                ),

                /// Products
                for (final CartStoreProduct product in <CartStoreProduct>[])
                  if (product.amount > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          /// Image
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
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
                    ),

                /// Delivery Price
                if (true)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        /// Icon
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
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
                  ),

                /// Tax
                if (true)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        /// Icon
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
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
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(icons.misc.search, size: 20),
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
                  ),

                /// Total Price
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                ),

                /// Order Number
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      /// Title
                      Text(
                        $.orders.card.details.number,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#12345',
                        style: theme.textTheme.titleMedium,
                      )
                    ],
                  ),
                ),

                /// Contact Support
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text($.orders.card.details.support),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 0, color: theme.colorScheme.outline),

                /// Repeat / Add a Tip
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Row(
                    children: <Widget>[
                      /// Repeat
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text($.orders.card.details.repeat),
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
                            child: Text($.orders.card.details.tipsAdd),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
