import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../../generated/assets.g.dart';
import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../models/cart_store.dart';
import '../../providers/misc.dart';
import '../navigation.dart';

/// The screen used to show off a [product].
class ProductScreen extends HookConsumerWidget {
  /// The screen used to show off a [product].
  const ProductScreen(
    this.store,
    this.product, {
    this.currentAmount,
    super.key,
  });

  /// The store owner of the [product] to show off on this screen.
  final StoreModel store;

  /// The product to show off on this screen.
  final StoreMenuProductsModel product;

  /// The current amount of [product] in the [cartProvider].
  final int? currentAmount;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final IsMounted isMounted = useIsMounted();
    final SyncCallback syncCallback = useSyncCallback();
    final ObjectRef<int> currentAmount = useRef(this.currentAmount ?? 1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: SafeArea(
        child: Material(
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
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      imageUrl: product.imgUrl ?? '',
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
                          onPressed: () async =>
                              syncCallback(navigator.maybePop),
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
                    if (product.tags
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
                              disabledBackgroundColor:
                                  theme.colorScheme.surface,
                              disabledForegroundColor:
                                  theme.colorScheme.secondary,
                              textStyle: theme.textTheme.titleSmall,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(40)),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(8).copyWith(right: 16),
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
              if (product.name != null) ...<Widget>[
                const SizedBox(height: 16),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      product.name!,
                      style: theme.textTheme.headlineMedium,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],

              /// Description
              if (product.description != null) ...<Widget>[
                const SizedBox(height: 16),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      product.description!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],

              /// More Info
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ProductCounterWithPrice(
                    product,
                    onPressed: (final int value) => currentAmount.value = value,
                    initial: currentAmount.value,
                  ),
                ),
              ),

              /// Add to Cart / Remove from cart
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(0),
                  ),
                  onPressed: () async => syncCallback(() async {
                    final Isar isar = await ref.read(isarProvider.future);
                    final CartStore? cartStore;
                    final int count = await isar.txn(isar.cartStores.count);
                    if (count == 0) {
                      cartStore = CartStore()..id = store.id!;
                    } else if (count > 1 ||
                        (cartStore = await isar
                                .txn(() => isar.cartStores.get(store.id!))) ==
                            null) {
                      if (!isMounted()) {
                        return;
                      }
                      final StateController<bool> canPopNotifier = ref
                          .read(NavigationScreen.canPopProvider.notifier)
                        ..state = false;
                      // ignore: use_build_context_synchronously
                      return context
                          .showFlashDialog(
                            dismissCompleter: ref.read(
                              NavigationScreen.willPopCompleterProvider,
                            ),
                            title: Text($.alert.storeAdded.title),
                            content: Text($.alert.storeAdded.body),
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
                                await isar.writeTxn(isar.cartStores.clear);
                                await controller.dismiss();
                              },
                              child: Text($.alert.storeAdded.approve),
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
                              child: Text($.alert.storeAdded.deny),
                            ),
                          )
                          .then((final _) => canPopNotifier.state = true);
                    }

                    final CartStoreProduct? $product = cartStore!.products
                        .firstWhereOrNull((final _) => _.id == product.id);
                    if ($product != null) {
                      $product.amount += currentAmount.value;
                    } else {
                      cartStore.products = <CartStoreProduct>[
                        ...cartStore.products,
                        CartStoreProduct()
                          ..id = product.id!
                          ..amount += currentAmount.value,
                      ];
                    }
                    await isar.writeTxn(() => isar.cartStores.put(cartStore!));
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
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<StoreModel>('store', store))
          ..add(
            DiagnosticsProperty<StoreMenuProductsModel>('product', product),
          )
          ..add(IntProperty('currentAmount', currentAmount)),
      );
}

/// The widget used to display a counter with price on a [ProductScreen].
class ProductCounterWithPrice extends HookConsumerWidget {
  /// The widget used to display a counter with price on a [ProductScreen].
  const ProductCounterWithPrice(
    this.product, {
    required this.onPressed,
    this.min,
    this.max,
    this.initial,
    super.key,
  });

  /// The product to show off in this counter.
  final StoreMenuProductsModel product;

  /// The callback on this counter.
  final FutureOr<void> Function(int value)? onPressed;

  /// The minimum value for this counter.
  final int? min;

  /// The maximum value for this counter.
  final int? max;

  /// The initial value for this counter.
  final int? initial;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ValueNotifier<int?> amount = useState(null);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        /// Counter
        Expanded(
          child: ProductCounter(
            onPressed: onPressed != null
                ? (final int value) async => onPressed!(amount.value = value)
                : null,
            initial: initial,
            min: min,
            max: max,
          ),
        ),

        /// Price
        Flexible(
          child: Text(
            r'$' +
                ((product.price ?? 0) * (amount.value ?? 1) / 100)
                    .toStringAsFixed(2),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              height: 32 / 24,
            ),
            textAlign: TextAlign.end,
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
            DiagnosticsProperty<StoreMenuProductsModel>('product', product),
          )
          ..add(IntProperty('min', min))
          ..add(IntProperty('max', max))
          ..add(IntProperty('initial', initial))
          ..add(
            ObjectFlagProperty<FutureOr<void> Function(int value)?>.has(
              'onPressed',
              onPressed,
            ),
          ),
      );
}

/// The widget used to display a counter on [ProductScreen]
class ProductCounter extends HookConsumerWidget {
  /// The widget used to display a counter on [ProductScreen]
  const ProductCounter({
    required this.onPressed,
    final int? min,
    final int? max,
    final int? initial,
    super.key,
  })  : min = min ?? 1,
        max = max ?? 9,
        initial = initial ?? 1,
        assert(
          (min ?? 1) < (max ?? 9),
          'Minimum value should be less than maximum value.',
        ),
        assert(
          (initial ?? 1) >= (min ?? 1) && (initial ?? 1) <= (max ?? 9),
          'Initial value should be in bounds with minimum and maximum values.',
        );

  /// The callback on this counter.
  final FutureOr<void> Function(int value)? onPressed;

  /// The minimum value for this counter.
  final int min;

  /// The maximum value for this counter.
  final int max;

  /// The initial value for this counter.
  final int initial;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ValueNotifier<int> amount = useState(initial);
    return Row(
      children: <Widget>[
        /// Minus
        Opacity(
          opacity: amount.value > min ? 1 : 1 / 2,
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
            onPressed: amount.value > min && onPressed != null
                ? () async => onPressed!(amount.value -= 1)
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
                amount.value.toString(),
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
          opacity: amount.value < max ? 1 : 1 / 2,
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
            onPressed: amount.value < max && onPressed != null
                ? () async => onPressed!(amount.value += 1)
                : null,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(IntProperty('min', min))
          ..add(IntProperty('max', max))
          ..add(IntProperty('initial', initial))
          ..add(
            ObjectFlagProperty<FutureOr<void> Function(int value)?>.has(
              'onPressed',
              onPressed,
            ),
          ),
      );
}
