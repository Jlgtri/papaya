import 'package:riverpod/riverpod.dart';

import '../generated/models.g.dart';
import '../widgets/navigation_screen.dart';

final FutureProvider<Iterable<StoreModel>> storesProvider =
    FutureProvider<Iterable<StoreModel>>(
  (final FutureProviderRef<Iterable<StoreModel>> ref) async =>
      const <StoreModel>[
    StoreModel(
      id: 1,
      name: 'Baar Baar',
      imgUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSyYrk80vz55bw4fpQvZBFs_izJN6EFpJWtq8VkSo6A&s',
      description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
          'Mauris et orci metus.',
      priceRange: 3,
      cuisines: <StoreCuisinesModel>[StoreCuisinesModel(cuisine: 'Indian')],
      address: <StoreAddressModel>[
        StoreAddressModel(
          displayLong:
              'Baar Baar, 109 St Johns Pl, Brooklyn, NY 11213, United States',
        ),
      ],
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
      address: <StoreAddressModel>[
        StoreAddressModel(
          displayLong:
              'Baar Baar, 109 St Johns Pl, Brooklyn, NY 11213, United States',
        ),
      ],
    ),
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
      storesProvider.selectAsync(
        (final Iterable<StoreModel> stores) => stores.where(
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
      const <StoreMenuModel>[
    StoreMenuModel(
      name: 'Papaya Picks',
      positionIndex: 1,
      products: <StoreMenuProductsModel>[
        StoreMenuProductsModel(
          id: 1,
          positionIndex: 1,
          name: 'Pollo Di Pastore 1.1',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
        StoreMenuProductsModel(
          id: 2,
          positionIndex: 2,
          name: 'Pollo Di Pastore 1.2',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
        StoreMenuProductsModel(
          id: 3,
          positionIndex: 3,
          name: 'Pollo Di Pastore 1.3',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
      ],
    ),
    StoreMenuModel(
      name: 'Diki Flex 1',
      positionIndex: 2,
      products: <StoreMenuProductsModel>[
        StoreMenuProductsModel(
          id: 4,
          positionIndex: 1,
          name: 'Pollo Di Pastore 2.1',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
        StoreMenuProductsModel(
          id: 5,
          positionIndex: 2,
          name: 'Pollo Di Pastore 2.2',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
        StoreMenuProductsModel(
          id: 6,
          positionIndex: 3,
          name: 'Pollo Di Pastore 2.3',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
      ],
    ),
    StoreMenuModel(
      name: 'Diki Flex 2',
      positionIndex: 3,
      products: <StoreMenuProductsModel>[
        StoreMenuProductsModel(
          id: 7,
          positionIndex: 1,
          name: 'Pollo Di Pastore 3.1',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
        StoreMenuProductsModel(
          id: 8,
          positionIndex: 2,
          name: 'Pollo Di Pastore 3.2',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
        StoreMenuProductsModel(
          id: 9,
          positionIndex: 3,
          name: 'Pollo Di Pastore 3.3',
          description:
              'Mushroom, spinach, roasted red peppers with goat cheese, '
              'rose sauce.',
          price: 1095,
          tags: <StoreMenuProductsTagsModel>[
            StoreMenuProductsTagsModel(tagName: 'Gluten-Free'),
          ],
        ),
      ],
    ),
  ],
);

final FutureProviderFamily<StoreEtaPickupModel, int> storeEtaPickupProvider =
    FutureProvider.family<StoreEtaPickupModel, int>(
  (
    final FutureProviderRef<StoreEtaPickupModel> ref,
    final int storeId,
  ) async =>
      const StoreEtaPickupModel(min: 10, max: 20),
);

final FutureProviderFamily<StoreEtaDeliveryModel, int>
    storeEtaDeliveryProvider =
    FutureProvider.family<StoreEtaDeliveryModel, int>(
  (
    final FutureProviderRef<StoreEtaDeliveryModel> ref,
    final int storeId,
  ) async =>
      const StoreEtaDeliveryModel(min: 30, max: 40),
);

final FutureProviderFamily<StoreOperationDaysModel, int>
    storeWorkingTimeProvider =
    FutureProvider.family<StoreOperationDaysModel, int>(
  (
    final FutureProviderRef<StoreOperationDaysModel> ref,
    final int storeId,
  ) async =>
      const StoreOperationDaysModel(
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
);

final FutureProvider<Iterable<UserAddressesModel>> addressesProvider =
    FutureProvider<Iterable<UserAddressesModel>>(
  (final FutureProviderRef<Iterable<UserAddressesModel>> ref) async =>
      const <UserAddressesModel>[
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
);

final FutureProvider<UserAddressesModel?> activeAddressProvider =
    FutureProvider<UserAddressesModel?>(
  (final FutureProviderRef<UserAddressesModel?> ref) async => await ref.watch(
    addressesProvider.selectAsync(
      (final Iterable<UserAddressesModel> addresses) =>
          (addresses.whereType<UserAddressesModel?>()).firstWhere(
        (final _) => _?.defaultAddress ?? false,
        orElse: () => null,
      ),
    ),
  ),
  dependencies: <ProviderOrFamily>[addressesProvider],
);
