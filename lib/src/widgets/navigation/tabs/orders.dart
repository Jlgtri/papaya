import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../generated/assets.g.dart';
import '../../../generated/i18n.g.dart';
import '../../../generated/icons.g.dart';
import '../../../generated/models.g.dart';
import '../../../hooks/sync_callback_hook.dart';
import '../../../models/settings.dart';
import '../../../providers/api.dart';
import '../../../routes.dart';
import '../order.dart';

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
  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
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
                onPressed: () async => current
                    ? navigator.pushNamed(
                        Routes.order.name,
                        arguments: const OrderScreen(),
                      )
                    : showMore.value = !showMore.value,
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
                                    final String time = DateFormat('h:mm a')
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
                                : DateFormat('DD.MM.YYYY, h:mm a')
                                    .format(DateTime.now()),
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
                          horizontal: 16,
                          vertical: 4,
                        ),
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
                Padding(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 0),
                  child: const OrderDetails(),
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
