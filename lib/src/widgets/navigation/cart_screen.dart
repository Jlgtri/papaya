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
import '../../models/cart_store.dart';
import '../../providers/misc_providers.dart';
import '../navigation_screen.dart';

/// The callback with a [CartStoreProduct] product.
typedef ProductCallback = FutureOr<void> Function(CartStoreProduct product);

/// The screen used to display information from [cartProvider].
class CartScreen extends HookConsumerWidget {
  /// The screen used to display information from [cartProvider].
  const CartScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final AsyncValue<Iterable<CartStore>> cart = ref.watch(cartProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                /// Title
                const SizedBox(height: 24),
                Flexible(
                  child: Padding(
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
                          onPressed: () async => context.showFlashDialog(
                            dismissCompleter: ref.read(
                              NavigationScreen.willPopCompleterProvider,
                            ),
                            title: Text($.alert.clearCart.title),
                            content: Text($.alert.clearCart.body),
                            negativeActionBuilder: (
                              final _,
                              final FlashController<void> controller,
                              final __,
                            ) =>
                                TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                              ),
                              onPressed: () async {
                                final Isar isar =
                                    await ref.read(isarProvider.future);
                                await isar.writeTxn(
                                  isar.cartStores.clear,
                                );
                                await controller.dismiss();
                              },
                              child: Text($.alert.clearCart.approve),
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
                              onPressed: controller.dismiss,
                              child: Text($.alert.clearCart.deny),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (cart.isLoading)
                  const Center(child: CircularProgressIndicator.adaptive())
                else if (cart is AsyncData &&
                    cart.valueOrNull != null) ...<Widget>[
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
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        color: theme.colorScheme.surfaceTint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              for (final CartStoreProduct product
                                  in store.products) ...<Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: _CartProductInformation(
                                    product,
                                    onPressed: (
                                      final CartStoreProduct $product,
                                    ) async {
                                      product.amount = $product.amount;
                                      final Isar isar =
                                          await ref.read(isarProvider.future);
                                      await isar.writeTxn(
                                        () => isar.cartStores.put(store),
                                      );
                                    },
                                  ),
                                ),
                                Divider(
                                  height: 40,
                                  color: theme.colorScheme.shadow,
                                ),
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
            ),
          ),
        ),

        /// Payment
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(0),
            ),
            onPressed: () {
              if (cart is AsyncData && cart.valueOrNull != null) {}
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                cart is AsyncData && cart.valueOrNull != null
                    ? r'$' +
                        cart.value!
                            .fold<num>(
                              0,
                              (
                                final num previousValue,
                                final CartStore store,
                              ) =>
                                  store.products.fold<num>(
                                previousValue,
                                (
                                  final num previousValue,
                                  final CartStoreProduct product,
                                ) =>
                                    previousValue +
                                    (product.product?.price ?? 0) *
                                        (product.amount / 100),
                              ),
                            )
                            .toStringAsFixed(2)
                    : '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The widget used to display information about [product].
class _CartProductInformation extends StatelessWidget {
  /// The widget used to display information about [product].
  const _CartProductInformation(this.product, {this.onPressed});

  /// The product to display in this widget.
  final CartStoreProduct product;

  /// The callback on counter tap.
  final ProductCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        /// Image
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: CachedNetworkImage(
            imageUrl: product.product?.imgUrl ?? '',
            fit: BoxFit.fitWidth,
            height: 72,
            width: 72,
            filterQuality: FilterQuality.high,
            errorWidget: (final _, final __, final ___) =>
                Image.asset(assets.logo, fit: BoxFit.fitWidth),
          ),
        ),

        /// Information
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              /// Name
              Flexible(
                child: Text(
                  product.product?.name ?? '',
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                ),
              ),

              ///
              const SizedBox(height: 16),
              Flexible(
                child: _CartProductCounter(product, onPressed: onPressed),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties
        ..add(DiagnosticsProperty<CartStoreProduct>('product', product))
        ..add(ObjectFlagProperty<ProductCallback?>.has('onPressed', onPressed)),
    );
  }
}

class _CartProductCounter extends StatelessWidget {
  const _CartProductCounter(this.product, {this.onPressed});

  /// The product to display in this widget.
  final CartStoreProduct product;

  /// The callback on counter tap.
  final ProductCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          flex: 2,
          child: Row(
            children: <Widget>[
              /// Minus
              Opacity(
                opacity: product.amount > 1 ? 1 : 1 / 2,
                child: IconButton(
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(24),
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.outline,
                    padding: const EdgeInsets.all(4),
                    shape: const CircleBorder(),
                  ),
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Icon(icons.minusCircle, size: 24),
                  ),
                  onPressed: product.amount > 1
                      ? () async => onPressed?.call(product..amount -= 1)
                      : null,
                ),
              ),

              /// Amount
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 8,
                    child: Text(
                      product.amount.toString(),
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
                opacity: product.amount < 9 ? 1 : 1 / 2,
                child: IconButton(
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(24),
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.outline,
                    padding: const EdgeInsets.all(4),
                    shape: const CircleBorder(),
                  ),
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Icon(icons.plusCircle, size: 24),
                  ),
                  onPressed: product.amount < 9
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
                ((product.product?.price ?? 0) * product.amount / 100)
                    .toStringAsFixed(2),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.end,
          ),
        )
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties
        ..add(DiagnosticsProperty<CartStoreProduct>('product', product))
        ..add(ObjectFlagProperty<ProductCallback?>.has('onPressed', onPressed)),
    );
  }
}
