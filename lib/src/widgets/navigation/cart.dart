import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../generated/assets.g.dart';
import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../models/cart_store.dart';
import '../../providers/misc.dart';
import '../navigation.dart';

/// The callback with a [CartStoreProduct] product.
typedef ProductCallback = FutureOr<void> Function(CartStoreProduct product);

/// The screen used to display [cartProvider].
@immutable
class CartScreen extends HookConsumerWidget {
  /// The screen used to display [cartProvider].
  const CartScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final num? price = ref.watch(
      cartProvider.select(
        (final _) => _.whenOrNull(
          data: (final List<CartStore> cart) => cart.fold<num>(
            0,
            (final num prevValue, final _) => _.products.fold<num>(
              prevValue,
              (final num prevValue, final _) =>
                  prevValue + (_.product?.price ?? 0) * (_.amount / 100),
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: price == null
              ? const CartStores()
              : const SingleChildScrollView(child: CartStores()),
        ),

        /// Payment
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(0),
            ),
            onPressed: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(r'$' + (price ?? 0).toStringAsFixed(2), maxLines: 1),
            ),
          ),
        ),
      ],
    );
  }
}

/// The widget used to display [CartStore] from [cartProvider].
@immutable
class CartStores extends HookConsumerWidget {
  /// The widget used to display [CartStore] from [cartProvider].
  const CartStores({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final AsyncValue<Iterable<CartStore>> cart = ref.watch(cartProvider);
    final SyncCallback syncCallback = useSyncCallback();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        /// Title
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              /// Title
              Flexible(
                child: Text(
                  $.cart.title,
                  style: theme.textTheme.displayMedium,
                  maxLines: 1,
                ),
              ),

              /// Clear Cart
              IconButton(
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(40),
                  foregroundColor: theme.colorScheme.outline,
                  padding: const EdgeInsets.all(8),
                  shape: const CircleBorder(),
                ),
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(icons.thrash, size: 24),
                ),
                onPressed: () async {
                  final StateController<bool> canPopNotifier = ref
                      .read(NavigationScreen.canPopProvider.notifier)
                    ..state = false;
                  return context
                      .showFlashDialog(
                        dismissCompleter: ref.read(
                          NavigationScreen.willPopCompleterProvider,
                        ),
                        title: Text($.alert.cartClear.title),
                        content: Text($.alert.cartClear.body),
                        negativeActionBuilder: (
                          final _,
                          final FlashController<void> controller,
                          final __,
                        ) =>
                            TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: () async => syncCallback(() async {
                            final Isar isar =
                                await ref.read(isarProvider.future);
                            await isar.writeTxn(
                              isar.cartStores.clear,
                            );
                            await controller.dismiss();
                          }),
                          child: Text($.alert.cartClear.approve),
                        ),
                        positiveActionBuilder: (
                          final _,
                          final FlashController<void> controller,
                          final __,
                        ) =>
                            TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: () => syncCallback(controller.dismiss),
                          child: Text($.alert.cartClear.deny),
                        ),
                      )
                      .then((final _) => canPopNotifier.state = true);
                },
              ),
            ],
          ),
        ),

        if (cart.isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        else if (cart is AsyncData && cart.valueOrNull != null) ...<Widget>[
          for (final CartStore store in cart.value!) ...<Widget>[
            const SizedBox(height: 24),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  store.store?.name ?? '',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                color: theme.colorScheme.surfaceTint,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final CartStoreProduct product in store.products)
                        for (int index = 0;
                            index < (product.amount / 9).ceil();
                            index++) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: CartProductInformation(
                              product,
                              onPressed:
                                  (final CartStoreProduct product) async =>
                                      syncCallback(() async {
                                if (product.amount <= 0) {
                                  store.products.remove(product);
                                }
                                final Isar isar =
                                    await ref.read(isarProvider.future);
                                await isar.writeTxn(
                                  () => store.products
                                          .any((final _) => _.amount > 0)
                                      ? isar.cartStores.put(store)
                                      : isar.cartStores.delete(store.id),
                                );
                              }),
                              counterActive:
                                  index >= (product.amount / 9).ceil() - 1,
                            ),
                          ),
                          Divider(height: 40, color: theme.colorScheme.shadow),
                        ]
                    ]..removeLast(),
                  ),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// The widget used to display information about [product].
@immutable
class CartProductInformation extends HookConsumerWidget {
  /// The widget used to display information about [product].
  const CartProductInformation(
    this.product, {
    this.counterActive = true,
    this.onPressed,
    super.key,
  });

  /// The product to display in this widget.
  final CartStoreProduct product;

  /// The callback on counter tap.
  final ProductCallback? onPressed;

  /// If the [CartProductCounter] is active on this widget.
  final bool counterActive;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        /// Image
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: CachedNetworkImage(
            imageUrl: product.product?.imgUrl ?? '',
            fit: BoxFit.cover,
            height: 72,
            width: 72,
            filterQuality: FilterQuality.high,
            errorWidget: (final _, final __, final ___) =>
                Image.asset(assets.logo, fit: BoxFit.cover),
          ),
        ),

        /// Information
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /// Name / Remove From Cart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  /// Name
                  Flexible(
                    child: Text(
                      product.product?.name ?? '',
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                    ),
                  ),

                  /// Remove From Cart
                  IconButton(
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(32),
                      foregroundColor: theme.colorScheme.outline,
                      padding: const EdgeInsets.all(6),
                      shape: const CircleBorder(),
                    ),
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Icon(icons.thrash, size: 20),
                    ),
                    onPressed: onPressed != null
                        ? () async => onPressed?.call(
                              product
                                ..amount -=
                                    counterActive && product.amount % 9 > 0
                                        ? product.amount % 9
                                        : 9,
                            )
                        : null,
                  ),
                ],
              ),

              /// Counter
              const SizedBox(height: 16),
              Flexible(
                child: CartProductCounter(
                  product,
                  onPressed: counterActive ? onPressed : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<CartStoreProduct>('product', product))
          ..add(
            ObjectFlagProperty<ProductCallback?>.has('onPressed', onPressed),
          )
          ..add(DiagnosticsProperty<bool>('counterActive', counterActive)),
      );
}

/// The widget used to display a counter on a [CartProductInformation].
@immutable
class CartProductCounter extends StatelessWidget {
  /// The widget used to display a counter on a [CartProductInformation].
  const CartProductCounter(this.product, {this.onPressed, super.key});

  /// The product to display in this widget.
  final CartStoreProduct product;

  /// The callback on counter tap.
  final ProductCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int amount =
        onPressed != null && product.amount % 9 > 0 ? product.amount % 9 : 9;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          flex: 2,
          child: Row(
            children: <Widget>[
              /// Minus
              Opacity(
                opacity: amount > 1 ? 1 : 1 / 2,
                child: IconButton(
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(32),
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.outline,
                    padding: const EdgeInsets.all(4),
                    shape: const CircleBorder(),
                  ),
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Icon(icons.minusCircle, size: 24),
                  ),
                  onPressed: amount > 1 && onPressed != null
                      ? () async => onPressed?.call(product..amount -= 1)
                      : null,
                ),
              ),

              /// Amount
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 8,
                    child: Text(
                      amount.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        height: 32 / 24,
                      ),
                    ),
                  ),
                ),
              ),

              /// Plus
              Opacity(
                opacity: amount < 9 ? 1 : 1 / 2,
                child: IconButton(
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(32),
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.outline,
                    padding: const EdgeInsets.all(4),
                    shape: const CircleBorder(),
                  ),
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Icon(icons.plusCircle, size: 24),
                  ),
                  onPressed: amount < 9 && onPressed != null
                      ? () async => onPressed?.call(product..amount += 1)
                      : null,
                ),
              ),
            ],
          ),
        ),

        /// Price
        Flexible(
          child: Text(
            r'$' +
                ((product.product?.price ?? 0) * amount / 100)
                    .toStringAsFixed(2),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.end,
          ),
        )
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<CartStoreProduct>('product', product))
          ..add(
            ObjectFlagProperty<ProductCallback?>.has('onPressed', onPressed),
          ),
      );
}
