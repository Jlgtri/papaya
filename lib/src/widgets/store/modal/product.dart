import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:styled_text/styled_text.dart';

import '../../../generated/assets.g.dart';
import '../../../generated/i18n.g.dart';
import '../../../generated/icons.g.dart';
import '../../../generated/models.g.dart';
import '../../../hooks/sync_callback_hook.dart';
import '../../../models/cart_store.dart';
import '../../../providers/misc.dart';
import '../../../routes.dart';

/// The screen used to show off a [product] from the [store].
@immutable
class ProductScreen extends HookConsumerWidget {
  /// The screen used to show off a [product] from the [store].
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
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      imageUrl: product.imgUrl ?? '',
                      errorWidget: (final _, final __, final ___) =>
                          Image.asset(assets.logo, fit: BoxFit.cover),
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
                          icon: Icon(icons.crossBold, size: 13),
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
              if (product.name?.isNotEmpty ?? false) ...<Widget>[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    product.name!,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ],

              /// Description
              if (product.description?.isNotEmpty ?? false) ...<Widget>[
                const SizedBox(height: 16),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      product.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.shadow,
                      ),
                    ),
                  ),
                ),
              ],

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
                      await navigator.pushNamed(
                        Routes.productInvalid.name,
                        arguments: ProductInvalidScreen(store, product),
                      );
                      return;
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
@immutable
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
            style: theme.textTheme.headlineSmall,
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
@immutable
class ProductCounter extends HookConsumerWidget {
  /// The widget used to display a counter on [ProductScreen]
  const ProductCounter({
    required this.onPressed,
    final int? min,
    final int? max,
    final int? initial,
    super.key,
  })  : min = min ?? 1,
        max = max ?? 99,
        initial = initial ?? 1,
        assert(
          (min ?? 1) < (max ?? 99),
          'Minimum value should be less than maximum value.',
        ),
        assert(
          (initial ?? 1) >= (min ?? 1) && (initial ?? 1) <= (max ?? 99),
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
                side: BorderSide(color: theme.colorScheme.shadow),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            ),
            icon: Icon(
              Platform.isIOS ? icons.minusCircle : icons.minus,
              size: 12,
            ),
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
              width: 34,
              child: Text(
                amount.value.toString(),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
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
            icon:
                Icon(Platform.isIOS ? icons.plusCircle : icons.plus, size: 12),
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

/// The screen used to notify about invalid product added to a cart on
/// [ProductScreen].
@immutable
class ProductInvalidScreen extends HookConsumerWidget {
  /// The screen used to notify about invalid product added to a cart on
  /// [ProductScreen].
  const ProductInvalidScreen(this.store, this.product, {super.key});

  /// The store owner of the [product] to show off on this screen.
  final StoreModel store;

  /// The product to show off on this screen.
  final StoreMenuProductsModel product;

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
                              $.alert.storeAdded.title,
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
                        child: StyledText(
                          text: $.alert.storeAdded.body(store.name ?? ''),
                          style: theme.textTheme.bodyMedium,
                          maxLines: 5,
                          textAlign: TextAlign.start,
                          tags: <String, StyledTextTagBase>{
                            'bold': StyledTextTag(
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          },
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
                                  child: Text($.alert.storeAdded.approve),
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
                                  child: Text(
                                    $.alert.storeAdded.deny(store.name ?? ''),
                                  ),
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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(DiagnosticsProperty<StoreModel>('store', store))
          ..add(
            DiagnosticsProperty<StoreMenuProductsModel>('product', product),
          ),
      );
}
