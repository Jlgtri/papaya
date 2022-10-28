import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

import '../generated/models.g.dart';
import '../providers/api_providers.dart';
import '../providers/misc_providers.dart';
import '../widgets/product_screen.dart';
import '../widgets/store_screen.dart';

part 'cart_store.g.dart';

/// The basic app's settings.
@collection
class CartStore {
  /// The id of the store.
  late Id id;

  /// The current active tokens.
  List<CartStoreProduct> products = <CartStoreProduct>[];

  /// The store that the [id] references.
  @ignore
  StoreModel? store;
}

/// The basic app's settings.
@embedded
class CartStoreProduct {
  /// The id of the product in the store.
  late int id;

  /// The amount of this product.
  int amount = 1;

  /// The product that the [id] references.
  @ignore
  StoreMenuProductsModel? product;
}

/// The provider of the current cart state.
final StreamProvider<Iterable<CartStore>> cartProvider =
    StreamProvider<Iterable<CartStore>>(
  (final StreamProviderRef<Iterable<CartStore>> ref) async* {
    final Isar isar = await ref.watch(isarProvider.future);
    await for (final Iterable<CartStore> cart
        in isar.cartStores.where().watch(fireImmediately: true)) {
      final Iterable<StoreModel> stores =
          await ref.watch(storesProvider.future);
      for (final CartStore store in cart) {
        for (final StoreModel $store in stores) {
          if ($store.id == store.id) {
            store.store = $store;
            break;
          }
        }
        store.store = stores.firstWhere((final _) => _.id == store.id);
        final Iterable<StoreMenuModel> products =
            await ref.watch(storeMenuProvider(store.id).future);
        for (final CartStoreProduct product in store.products) {
          outer:
          for (final StoreMenuModel menu in products) {
            for (final StoreMenuProductsModel menuProduct
                in menu.products ?? <StoreMenuProductsModel>[]) {
              if (menuProduct.id == product.id) {
                product.product = menuProduct;
                break outer;
              }
            }
          }
        }
      }
      yield cart;
    }
  },
  dependencies: <ProviderOrFamily>[isarProvider],
);

/// The provider of the current product amount in the [cartProvider] state.
final FutureProvider<int> amountProvider = FutureProvider<int>(
  (final FutureProviderRef<int> ref) async {
    final int? storeId =
        ref.read(StoreScreen.provider.select((final _) => _?.id));
    final int? productId =
        ref.watch(ProductScreen.provider.select((final _) => _?.id));
    if (storeId == null || productId == null) {
      return 0;
    }
    return await ref.watch(
      cartProvider.future
          .select((final Future<Iterable<CartStore>> stores) async {
        for (final CartStore store in await stores) {
          if (store.id == storeId) {
            for (final CartStoreProduct product in store.products) {
              if (product.id == productId) {
                return product.amount;
              }
            }
          }
        }
        return 0;
      }),
    );
  },
  dependencies: <ProviderOrFamily>[
    StoreScreen.provider,
    ProductScreen.provider
  ],
);
