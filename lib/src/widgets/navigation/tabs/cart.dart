import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../generated/assets.g.dart';
import '../../../generated/i18n.g.dart';
import '../../../generated/icons.g.dart';
import '../../../hooks/sync_callback_hook.dart';
import '../../../models/cart_store.dart';
import '../../../providers/misc.dart';
import '../../../routes.dart';

/// The callback with a [CartStoreProduct] product.
typedef ProductCallback = FutureOr<void> Function(CartStoreProduct product);

/// The screen used to display [cartProvider].
@immutable
class CartScreen extends HookConsumerWidget {
  /// The screen used to display [cartProvider].
  const CartScreen({this.onEmptyCartPressed, super.key});

  /// The callback on payment button when cart is empty.
  final VoidCallback? onEmptyCartPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final AsyncValue<Iterable<CartStore>> cart = ref.watch(cartProvider);
    final double subtotal =
        ref.watch(cartTotalProvider.select((final _) => _.valueOrNull ?? 0));
    final SyncCallback syncCallback = useSyncCallback();
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: CustomScrollView(
              physics: cart.asData?.value.isEmpty ?? true
                  ? const NeverScrollableScrollPhysics()
                  : null,
              slivers: <Widget>[
                /// Title
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(top: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        /// Title
                        Text(
                          $.cart.title,
                          style: theme.textTheme.displayMedium,
                          maxLines: 1,
                        ),

                        /// Clear Cart
                        if (cart.asData?.value.isNotEmpty ?? false)
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
                            onPressed: () async =>
                                rootNavigator.pushNamed(Routes.cartClear.name),
                          ),
                      ],
                    ),
                  ),
                ),

                if (cart.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                else if (cart.asData?.value.isEmpty ?? true)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    sliver: SliverFillRemaining(
                      child: Center(
                        child: Text(
                          $.cart.empty,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  for (final CartStore store in cart.value!) ...<Widget>[
                    SliverPadding(
                      padding: const EdgeInsets.all(16).copyWith(top: 24),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          store.store?.name ?? '',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Material(
                          clipBehavior: Clip.hardEdge,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          color: theme.colorScheme.surfaceTint,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: CartStoreProducts(
                              store,
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
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                const SliverPadding(
                    padding: EdgeInsets.symmetric(vertical: 12)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(0),
            ),
            onPressed: subtotal > 0
                ? () async => syncCallback(
                      () => rootNavigator.pushNamed(Routes.payment.name),
                    )
                : onEmptyCartPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                subtotal > 0
                    ? r'$' + subtotal.toStringAsFixed(2)
                    : $.cart.addItems,
                maxLines: 1,
              ),
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
          ..add(
            ObjectFlagProperty<VoidCallback>.has(
              'onEmptyCartPressed',
              onEmptyCartPressed,
            ),
          ),
      );
}

/// The widget used to show picked products in a [store].
@immutable
class CartStoreProducts extends HookConsumerWidget {
  /// The widget used to show picked products in a [store].
  const CartStoreProducts(
    this.store, {
    this.counterActive,
    this.onPressed,
    super.key,
  });

  /// The store to show products for.
  final CartStore store;

  /// If the counter should be active.
  final bool? counterActive;

  /// The callback on product's counter tap.
  final ProductCallback? onPressed;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final CartStoreProduct product in store.products)
          for (int index = 0;
              index < (product.amount / 99).ceil();
              index++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CartProductInformation(
                product,
                onPressed: onPressed,
                counterActive:
                    counterActive ?? index >= (product.amount / 99).ceil() - 1,
              ),
            ),
            Divider(height: 40, color: theme.colorScheme.shadow),
          ]
      ]..removeLast(),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<CartStore>('store', store))
          ..add(DiagnosticsProperty<bool>('counterActive', counterActive))
          ..add(
            ObjectFlagProperty<ProductCallback?>.has('onPressed', onPressed),
          ),
      );
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
                  Expanded(
                    child: Text(
                      product.product?.name ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.shadow,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  /// Remove From Cart
                  if (onPressed != null)
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
                      onPressed: () async => onPressed?.call(
                        product
                          ..amount -= counterActive && product.amount % 99 > 0
                              ? product.amount % 99
                              : 99,
                      ),
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
    final int amount = product.amount % 99 > 0 ? product.amount % 99 : 99;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          flex: 2,
          child: Row(
            children: <Widget>[
              /// Minus
              IconButton(
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
                onPressed: onPressed != null && amount > 1
                    ? () async => onPressed?.call(product..amount -= 1)
                    : null,
              ),

              /// Amount
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 34,
                  child: Text(
                    amount.toString(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.shadow,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),

              /// Plus
              IconButton(
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
                onPressed: onPressed != null && amount < 99
                    ? () async => onPressed?.call(product..amount += 1)
                    : null,
              ),
            ],
          ),
        ),

        /// Price
        Text(
          r'$' +
              ((product.product?.price ?? 0) * amount / 100).toStringAsFixed(2),
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.shadow,
          ),
          maxLines: 1,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.end,
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
          ),
      );
}

/// The screen used to clear a cart on [CartScreen].
@immutable
class CartClearScreen extends HookConsumerWidget {
  /// The screen used to clear a cart on [CartScreen].
  const CartClearScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// Title / Clear
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              $.alert.cartClear.title,
                              style: theme.textTheme.displaySmall,
                              textAlign: TextAlign.start,
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              fixedSize: const Size.square(30),
                              foregroundColor: theme.colorScheme.outline,
                              padding: const EdgeInsets.all(6),
                              shape: const CircleBorder(),
                            ),
                            icon: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Icon(icons.cross, size: 16),
                            ),
                            onPressed: () async =>
                                syncCallback(navigator.maybePop),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),

                      /// Body
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          $.alert.cartClear.body,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 5,
                          textAlign: TextAlign.start,
                        ),
                      ),

                      /// Actions
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: <Widget>[
                            /// Approve

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.surface,
                                  minimumSize: const Size.fromHeight(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  textStyle: theme.textTheme.titleSmall,
                                ),
                                onPressed: () async => syncCallback(() async {
                                  final Isar isar =
                                      await ref.read(isarProvider.future);
                                  await isar.writeTxn(isar.cartStores.clear);
                                  await navigator.maybePop();
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text($.alert.noteClear.approve),
                                ),
                              ),
                            ),

                            /// Deny
                            const SizedBox(width: 24),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.shadow,
                                  backgroundColor: theme.colorScheme.surface,
                                  minimumSize: const Size.fromHeight(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  textStyle: theme.textTheme.titleSmall,
                                ),
                                onPressed: () async =>
                                    syncCallback(navigator.maybePop),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text($.alert.cartClear.deny),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
