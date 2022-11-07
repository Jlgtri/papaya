import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

import '../generated/models.g.dart';
import '../models/address.dart';
import '../models/settings.dart';
import '../widgets/navigation.dart';

const Duration mockDuration = Duration(seconds: 3);

final FutureProvider<Iterable<StoreModel>> allStoresProvider =
    FutureProvider<Iterable<StoreModel>>(
  (final FutureProviderRef<Iterable<StoreModel>> ref) async => Future.delayed(
    mockDuration,
    () => const <StoreModel>[
      StoreModel(
        id: 1,
        name: 'Baar Baar',
        imgUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSyYrk80vz55bw4fpQvZBFs_izJN6EFpJWtq8VkSo6A&s',
        description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Mauris et orci metus.',
        priceRange: 3,
        cuisines: <StoreCuisinesModel>[StoreCuisinesModel(cuisine: 'Indian')],
        address: StoreAddressModel(
          displayLong:
              'Baar Baar, 109 St Johns Pl, Brooklyn, NY 11213, United States',
        ),
      ),
      StoreModel(
        id: 2,
        name: 'Baar Baar 2',
        imgUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSyYrk80vz55bw4fpQvZBFs_izJN6EFpJWtq8VkSo6A&s',
        description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Mauris et orci metus.',
        priceRange: 3,
        cuisines: <StoreCuisinesModel>[StoreCuisinesModel(cuisine: 'Indian')],
        address: StoreAddressModel(
          displayLong:
              'Baar Baar, 109 St Johns Pl, Brooklyn, NY 11213, United States',
        ),
      ),
    ],
  ),
);

final FutureProvider<Iterable<StoreModel>> nearbyStoresProvider =
    FutureProvider<Iterable<StoreModel>>(
  (final FutureProviderRef<Iterable<StoreModel>> ref) async =>
      Future.delayed(mockDuration, () => <StoreModel>[]),
);

final FutureProvider<Iterable<StoreModel>> storesProvider =
    FutureProvider<Iterable<StoreModel>>(
  (final FutureProviderRef<Iterable<StoreModel>> ref) async => await ref.watch(
    deliveryTypeProvider.selectAsync((final _) => _ == DeliveryType.delivery),
  )
      ? ref.watch(nearbyStoresProvider.future)
      : ref.watch(allStoresProvider.future),
  dependencies: <ProviderOrFamily>[
    deliveryTypeProvider,
    nearbyStoresProvider,
    allStoresProvider
  ],
);

final FutureProvider<Iterable<StoreModel>> filteredStoresProvider =
    FutureProvider<Iterable<StoreModel>>(
  (final FutureProviderRef<Iterable<StoreModel>> ref) async {
    final RegExp search = RegExp(
      ref.watch(SearchField.provider.select((final _) => _ ?? '')),
      caseSensitive: false,
    );
    return await ref.watch(
      storesProvider.future.select(
        (final Future<Iterable<StoreModel>> _) async => (await _).where(
          (final StoreModel store) => store.name?.contains(search) ?? false,
        ),
      ),
    );
  },
  dependencies: <ProviderOrFamily>[SearchField.provider, storesProvider],
);

final FutureProviderFamily<Iterable<StoreMenuModel>, int> storeMenuProvider =
    FutureProvider.family<Iterable<StoreMenuModel>, int>(
  (
    final FutureProviderRef<Iterable<StoreMenuModel>> ref,
    final int storeId,
  ) async =>
      Future.delayed(
    mockDuration,
    () => <StoreMenuModel>[
      for (int index = 1; index < 4; index++)
        StoreMenuModel(
          id: index,
          name: 'Papaya Picks $index',
          positionIndex: index,
          products: <StoreMenuProductsModel>[
            for (int productIndex = 1; productIndex < 4; productIndex++)
              StoreMenuProductsModel(
                id: index * productIndex,
                positionIndex: productIndex,
                name: 'Pollo Di Pastore $index.$productIndex',
                description:
                    'Mushroom, spinach, roasted red peppers with goat cheese, '
                    'rose sauce.',
                price: 1095,
                tags: const <StoreMenuProductsTagsModel>[
                  StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
                ],
              ),
          ],
        ),
    ],
  ),
);

final FutureProviderFamily<StoreEtaPickupModel?, int> storeEtaPickupProvider =
    FutureProvider.family<StoreEtaPickupModel?, int>(
  (
    final FutureProviderRef<StoreEtaPickupModel?> ref,
    final int storeId,
  ) async =>
      Future.delayed(
    mockDuration,
    () => const StoreEtaPickupModel(min: 10, max: 20),
  ),
);

final FutureProviderFamily<StoreEtaDeliveryModel?, int>
    storeEtaDeliveryProvider =
    FutureProvider.family<StoreEtaDeliveryModel?, int>(
  (
    final FutureProviderRef<StoreEtaDeliveryModel?> ref,
    final int storeId,
  ) async =>
      Future.delayed(mockDuration, () => null),
);

final FutureProviderFamily<StoreOperationDaysModel, int>
    storeWorkingTimeProvider =
    FutureProvider.family<StoreOperationDaysModel, int>(
  (
    final FutureProviderRef<StoreOperationDaysModel> ref,
    final int storeId,
  ) async =>
      Future.delayed(
    mockDuration,
    () => const StoreOperationDaysModel(
      storeRegularHours: <StoreOperationDaysStoreRegularHoursModel>[
        StoreOperationDaysStoreRegularHoursModel(
          day: 1,
          openTime: '08:00',
          closeTime: '19:00',
        ),
        StoreOperationDaysStoreRegularHoursModel(
          day: 2,
          openTime: '08:00',
          closeTime: '19:00',
        ),
        StoreOperationDaysStoreRegularHoursModel(
          day: 3,
          openTime: '08:00',
          closeTime: '19:00',
        ),
        StoreOperationDaysStoreRegularHoursModel(
          day: 4,
          openTime: '08:00',
          closeTime: '19:00',
        ),
        StoreOperationDaysStoreRegularHoursModel(
          day: 5,
          openTime: '08:00',
          closeTime: '19:00',
        ),
        StoreOperationDaysStoreRegularHoursModel(
          day: 6,
          openTime: '08:00',
          closeTime: '22:00',
        ),
        StoreOperationDaysStoreRegularHoursModel(
          day: 7,
          openTime: '08:00',
          closeTime: '22:00',
        ),
      ],
    ),
  ),
);

final FutureProviderFamily<StoreMenuProductsModel, int> storeProductProvider =
    FutureProvider.family<StoreMenuProductsModel, int>(
  (
    final FutureProviderRef<StoreMenuProductsModel> ref,
    final int productId,
  ) async =>
      Future.delayed(
    mockDuration,
    () => StoreMenuProductsModel(
      id: productId,
      positionIndex: productId % 3,
      name: 'Pollo Di Pastore ${productId ~/ 3}.${productId % 3}',
      description: 'Mushroom, spinach, roasted red peppers with goat cheese, '
          'rose sauce.',
      price: 1095,
      tags: const <StoreMenuProductsTagsModel>[
        StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
      ],
    ),
  ),
);

final FutureProvider<Iterable<UserAddressesModel>> addressesProvider =
    FutureProvider<Iterable<UserAddressesModel>>(
  (final FutureProviderRef<Iterable<UserAddressesModel>> ref) async =>
      Future.delayed(
    mockDuration,
    () => const <UserAddressesModel>[
      UserAddressesModel(
        lat: 0,
        lng: 0,
        defaultAddress: true,
        displayLong: '300 Main St, Rexford, Kansas, 67753, US',
      ),
      UserAddressesModel(
        lat: 0,
        lng: 0,
        displayLong: 'DIKI FLEX 300 Main St, Rexford, Kansas, 67753, US',
      )
    ],
  ),
);

final FutureProvider<Iterable<UserAddressesModel>> activeAddressesProvider =
    FutureProvider<Iterable<UserAddressesModel>>(
  (final FutureProviderRef<Iterable<UserAddressesModel>> ref) async =>
      await ref.watch(skippedAuthorizationProvider.future)
          ? await ref.watch(isarAddressesProvider.future)
          : await ref.watch(addressesProvider.future),
  dependencies: <ProviderOrFamily>[
    skippedAuthorizationProvider,
    isarAddressesProvider,
    addressesProvider
  ],
);

final FutureProvider<UserAddressesModel?> activeAddressProvider =
    FutureProvider<UserAddressesModel?>(
  (final FutureProviderRef<UserAddressesModel?> ref) async => await ref
          .watch(skippedAuthorizationProvider.future)
      ? await ref.watch(
          isarAddressesProvider.future.select(
            (final Future<Iterable<UserAddressesModel>> _) async => (await _)
                .firstWhereOrNull((final _) => _.defaultAddress ?? false),
          ),
        )
      : await ref.watch(
          addressesProvider.selectAsync(
            (final Iterable<UserAddressesModel> addresses) => addresses
                .firstWhereOrNull((final _) => _.defaultAddress ?? false),
          ),
        ),
  dependencies: <ProviderOrFamily>[
    skippedAuthorizationProvider,
    isarAddressesProvider,
    addressesProvider
  ],
);
