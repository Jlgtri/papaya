import 'package:collection/collection.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

import '../generated/models.g.dart';
import '../providers/api.dart';
import '../providers/misc.dart';

part 'cart_store.g.dart';

/// The store in the cart.
@collection
class CartStore {
  /// The id of the store.
  late Id id;

  /// The products in this store.
  List<CartStoreProduct> products = <CartStoreProduct>[];

  /// The store that the [id] references.
  @ignore
  StoreModel? store;
}

/// The product in the [CartStore].
@embedded
class CartStoreProduct {
  /// The id of the product in the [CartStore].
  late int id;

  /// The amount of this product.
  int amount = 0;

  /// The product that the [id] references.
  @ignore
  StoreMenuProductsModel? product;
}

/// The provider of the current cart state.
final StreamProvider<List<CartStore>> cartProvider =
    StreamProvider<List<CartStore>>(
  (final StreamProviderRef<List<CartStore>> ref) async* {
    final Isar isar = await ref.watch(isarProvider.future);
    await for (final List<CartStore> cart
        in isar.cartStores.where().watch(fireImmediately: true)) {
      if (cart.isNotEmpty) {
        final Iterable<StoreModel>? stores =
            await ref.read(storesProvider.future);
        for (int index = 0; index < cart.length; index++) {
          final CartStore store = cart.elementAt(index);
          final int initialStoreProductLength = store.products.length;
          store.store = stores?.firstWhereOrNull((final _) => _.id == store.id);

          final Iterable<StoreMenuModel>? storeMenu =
              ref.read(storeMenuProvider(store.id)).valueOrNull;
          if (store.store != null && initialStoreProductLength > 0) {
            store.products = (await Future.wait(<Future<CartStoreProduct?>>[
              for (final CartStoreProduct product in store.products)
                Future<CartStoreProduct?>(() async {
                  if (storeMenu != null) {
                    outer:
                    for (final StoreMenuModel menu in storeMenu) {
                      if (menu.products != null) {
                        for (final StoreMenuProductsModel menuProduct
                            in menu.products!) {
                          if (menuProduct.id == product.id) {
                            product.product = menuProduct;
                            break outer;
                          }
                        }
                      }
                    }
                  }
                  product.product ??=
                      await ref.read(storeProductProvider(product.id).future);
                  return product.product == null ? null : product;
                })
            ]))
                .whereNotNull()
                .toList();
          }
          if (store.store == null || initialStoreProductLength == 0) {
            cart.removeAt(index--);
            await isar.writeTxn(() => isar.cartStores.delete(store.id));
          } else if (initialStoreProductLength != store.products.length) {
            await isar.writeTxn(() => isar.cartStores.put(store));
          }
        }
      }
      yield cart;
    }
  },
  dependencies: <ProviderOrFamily>[
    isarProvider,
    storesProvider,
    storeMenuProvider
  ],
);
