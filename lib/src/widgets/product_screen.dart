import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../generated/assets.g.dart';
import '../generated/i18n.g.dart';
import '../generated/icons.g.dart';
import '../generated/models.g.dart';
import '../hooks/sync_callback_hook.dart';
import '../models/cart_store.dart';
import '../providers/misc_providers.dart';
import '../routes.dart';
import '../styles.dart';
import 'store_screen.dart';

/// The screen used to show off a product from [provider].
class ProductScreen extends HookConsumerWidget {
  /// The screen used to show off a product from [provider].
  const ProductScreen({super.key});

  /// The provider of the product to show on this screen.
  static final StateProvider<StoreMenuProductsModel?> provider =
      StateProvider<StoreMenuProductsModel?>((final _) => null);

  /// The provider of the product to show on this screen.
  static final StateProvider<int> currentAmountProvider = StateProvider<int>(
    (final StateProviderRef<int> ref) => 1,
  );

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final StoreMenuProductsModel? product = ref.watch(provider);
    final SyncCallback syncCallback = useSyncCallback();
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
            height: 240,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.high,
                  imageUrl: product?.imgUrl ?? '',
                  errorWidget: (final _, final __, final ___) =>
                      Image.asset(assets.logo, fit: BoxFit.fitWidth),
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
                      onPressed: () async => syncCallback(navigator.maybePop),
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

                /// Gluten-Free Tag
                if (product?.tags
                        ?.map((final _) => _.tagName)
                        .contains('Gluten-Free') ??
                    false)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: theme.colorScheme.surface,
                          disabledForegroundColor: theme.colorScheme.secondary,
                          textStyle: theme.textTheme.titleSmall,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(40)),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8).copyWith(right: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: Icon(icons.gluten, size: 23),
                              ),
                              const SizedBox(width: 10),
                              const Flexible(child: Text('Gluten-Free')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// Name
          if (product?.name != null) ...<Widget>[
            const SizedBox(height: 16),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  product!.name!,
                  style: theme.textTheme.headlineMedium,
                  maxLines: 1,
                ),
              ),
            ),
          ],

          /// Description
          if (product?.description != null) ...<Widget>[
            const SizedBox(height: 16),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  product!.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                ),
              ),
            ),
          ],

          /// Additional Info
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton(
                onPressed: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text($.store.productScreen.additionalInfo),
                      ),
                      const SizedBox(width: 11),
                      Icon(icons.misc.arrowDown, size: 10)
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Counter
          const SizedBox(height: 24),
          const Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _ProductCounter(),
            ),
          ),

          /// Add to Cart / Remove from cart
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                // Consumer(
                //   builder: (final _, final WidgetRef ref, final Widget?
                // child) {
                //     final bool productInCart = ref.watch(
                //       amountProvider.select((final _) => (_.valueOrNull ??
                //0) != 0),
                //     );
                //     return
                ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(0),
              ),
              onPressed: () async => syncCallback(() async {
                final StoreModel? store = ref.read(StoreScreen.provider);
                if ((product != null && product.id != null) &&
                    (store != null && store.id != null)) {
                  final Isar isar = await ref.read(isarProvider.future);
                  await isar.writeTxn(() async {
                    final CartStore cartStore =
                        await isar.cartStores.get(store.id!) ??
                            (CartStore()..id = store.id!);
                    CartStoreProduct? $product;
                    for ($product in cartStore.products) {
                      if ($product.id != product.id) {
                        $product = null;
                        continue;
                      }

                      // if (productInCart) {
                      //   cartStore.products = <CartStoreProduct>[
                      //     for (final CartStoreProduct $product
                      //         in cartStore.products)
                      //       if ($product.id != product.id) $product
                      //   ];
                      // } else {
                      $product.amount = ref.read(currentAmountProvider);
                      // }
                      break;
                    }
                    if ($product == null) {
                      // if (!productInCart && $product == null) {
                      cartStore.products = <CartStoreProduct>[
                        ...cartStore.products,
                        CartStoreProduct()
                          ..id = product.id!
                          ..amount = ref.read(currentAmountProvider),
                      ];
                    }
                    await isar.cartStores.put(cartStore);
                  });
                }
                await navigator.maybePop();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text($.store.productScreen.addToCart),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProductCounter extends HookConsumerWidget {
  const _ProductCounter();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int amount = ref.watch(ProductScreen.currentAmountProvider);
    final StoreMenuProductsModel? product = ref.watch(ProductScreen.provider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              /// Minus
              Opacity(
                opacity: amount > 1 ? 1 : 1 / 2,
                child: IconButton(
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(40),
                    disabledForegroundColor: theme.colorScheme.shadow,
                    foregroundColor: theme.colorScheme.shadow,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: theme.colorScheme.shadow,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                  ),
                  icon: Icon(icons.minus, size: 12),
                  onPressed: amount > 1
                      ? () => ref
                          .read(ProductScreen.currentAmountProvider.notifier)
                          .state--
                      : null,
                ),
              ),

              /// Count
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: 9,
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
                    fixedSize: const Size.square(40),
                    disabledForegroundColor: theme.colorScheme.shadow,
                    foregroundColor: theme.colorScheme.shadow,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: theme.colorScheme.shadow,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                  ),
                  icon: Icon(icons.plus, size: 12),
                  onPressed: amount < 9
                      ? () => ref
                          .read(ProductScreen.currentAmountProvider.notifier)
                          .state++
                      : null,
                ),
              ),
            ],
          ),
        ),

        /// Price
        Flexible(
          child: Text(
            r'$' + ((product?.price ?? 0) * amount / 100).toStringAsFixed(2),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              height: 32 / 24,
            ),
            textAlign: TextAlign.end,
          ),
        )
      ],
    );
  }
}

/// The [StoreMenuProductsModel.name] property should not be null.
class ProductCard extends HookConsumerWidget {
  /// The [StoreMenuProductsModel.name] property should not be null.
  const ProductCard(this.product, {super.key});

  /// The product to diplay in this card.
  final StoreMenuProductsModel product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);
    final SyncCallback syncCallback = useSyncCallback();
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
                    fit: BoxFit.fitWidth,
                    height: 240,
                    filterQuality: FilterQuality.high,
                    errorWidget: (final _, final __, final ___) =>
                        Image.asset(assets.logo, fit: BoxFit.fitWidth),
                  ),
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
                    Flexible(
                      child: Text(
                        product.name!,
                        style: theme.textTheme.headlineMedium,
                        maxLines: 1,
                      ),
                    ),

                    /// Description
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        product.description ?? '',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Footer
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          /// Price
                          Flexible(
                            child: Text(
                              r'$' +
                                  ((product.price ?? 0) / 100)
                                      .toStringAsFixed(2),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 24,
                                height: 32 / 24,
                              ),
                            ),
                          ),

                          /// Add to Cart
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              textStyle: theme.textTheme.titleSmall,
                            ),
                            onPressed: () async => syncCallback(
                              () => Routes.product
                                  .push(rootNavigator, container, product),
                            ),
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
                    )
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
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(
      properties
        ..add(DiagnosticsProperty<StoreMenuProductsModel>('product', product)),
    );
  }
}
