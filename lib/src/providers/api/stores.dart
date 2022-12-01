part of '../api.dart';

/// The provider of all stores.
final AutoDisposeFutureProvider<Iterable<StoreModel>?> allStoresProvider =
    FutureProvider.autoDispose<Iterable<StoreModel>?>(
  (final AutoDisposeFutureProviderRef<Iterable<StoreModel>?> ref) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      '/public/store/all',
      options: Options(extra: <String, Object?>{'ref': ref}),
    );
    if (response.data is Iterable<Object?>) {
      ref.keepAlive();
      return (response.data! as Iterable<Object?>)
          .whereType<Map<String, Object?>>()
          .map(storeConverter.fromJson);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of nearby stores depending on [LatLng].
final AutoDisposeFutureProviderFamily<Iterable<StoreModel>?, LatLng>
    nearbyStoresProvider =
    FutureProvider.autoDispose.family<Iterable<StoreModel>?, LatLng>(
  (
    final AutoDisposeFutureProviderRef<Iterable<StoreModel>?> ref,
    final LatLng latLng,
  ) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      '/public/store/nearby',
      queryParameters: <String, Object?>{
        'lat': latLng.latitude,
        'lng': latLng.longitude,
      },
      options: Options(extra: <String, Object?>{'ref': ref}),
    );
    if (response.data is Iterable<Object?>) {
      ref.keepAlive();
      return (response.data! as Iterable<Object?>)
          .whereType<Map<String, Object?>>()
          .map(storeConverter.fromJson);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of stores depending on [deliveryTypeProvider].
///
/// * If delivery type is [DeliveryType.delivery], returns the
/// [nearbyStoresProvider] with the [currentAddressProvider] LatLng.
/// * If delivery type is [DeliveryType.pickup], returns the
/// [allStoresProvider].
final AutoDisposeFutureProvider<Iterable<StoreModel>?> storesProvider =
    FutureProvider.autoDispose<Iterable<StoreModel>?>(
  (final AutoDisposeFutureProviderRef<Iterable<StoreModel>?> ref) async {
    final Iterable<StoreModel>? stores;
    if (await ref.watch(
      deliveryTypeProvider.selectAsync((final _) => _ == DeliveryType.delivery),
    )) {
      final UserAddressesModel? currentAddress =
          await ref.watch(currentAddressProvider.future);
      if (currentAddress?.lat == null || currentAddress?.lng == null) {
        return null;
      }

      final LatLng latLng = LatLng(currentAddress!.lat!, currentAddress.lng!);
      stores = await ref.watch(nearbyStoresProvider(latLng).future);
    } else {
      stores = await ref.watch(allStoresProvider.future);
    }
    ref.keepAlive();
    return stores;
  },
  dependencies: <ProviderOrFamily>[
    deliveryTypeProvider,
    currentAddressProvider,
    nearbyStoresProvider,
    allStoresProvider
  ],
);

/// The provider of stores depending on [storesProvider] and search value from
/// [SearchField.provider].
final AutoDisposeFutureProvider<Iterable<StoreModel>?> filteredStoresProvider =
    FutureProvider.autoDispose<Iterable<StoreModel>?>(
  (final AutoDisposeFutureProviderRef<Iterable<StoreModel>?> ref) async {
    final RegExp search = RegExp(
      ref.watch(SearchField.provider.select((final _) => _ ?? '')),
      caseSensitive: false,
    );
    final Iterable<StoreModel>? stores = await ref.watch(
      storesProvider.selectAsync(
        (final Iterable<StoreModel>? stores) => stores?.where(
          (final StoreModel store) => store.name?.contains(search) ?? false,
        ),
      ),
    );
    ref.keepAlive();
    return stores;
  },
  dependencies: <ProviderOrFamily>[SearchField.provider, storesProvider],
);

/// The provider of the information for a specific store id.
final AutoDisposeFutureProviderFamily<StoreModel?, int> storeProvider =
    FutureProvider.autoDispose.family<StoreModel?, int>(
  (
    final AutoDisposeFutureProviderRef<StoreModel?> ref,
    final int storeId,
  ) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      '/public/store/$storeId',
      options: Options(extra: <String, Object?>{'ref': ref}),
    );
    if (response.data is Map<String, Object?>) {
      ref.keepAlive();
      return storeConverter.fromJson(response.data! as Map<String, Object?>);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of the menu for a specific store id.
final AutoDisposeFutureProviderFamily<Iterable<StoreMenuModel>?, int>
    storeMenuProvider =
    FutureProvider.autoDispose.family<Iterable<StoreMenuModel>?, int>(
  (
    final AutoDisposeFutureProviderRef<Iterable<StoreMenuModel>?> ref,
    final int storeId,
  ) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      '/public/store/menu',
      queryParameters: <String, Object?>{'store_id': storeId},
      options: Options(extra: <String, Object?>{'ref': ref}),
    );
    if (response.data is Iterable<Object?>) {
      ref.keepAlive();
      return (response.data! as Iterable<Object?>)
          .whereType<Map<String, Object?>>()
          .map(storeMenuConverter.fromJson);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of the operational days for a specific store id.
final AutoDisposeFutureProviderFamily<StoreOperationDaysModel?, int>
    storeOperationDaysProvider =
    FutureProvider.autoDispose.family<StoreOperationDaysModel?, int>(
  (
    final AutoDisposeFutureProviderRef<StoreOperationDaysModel?> ref,
    final int storeId,
  ) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      '/public/store/operation_days',
      queryParameters: <String, Object?>{'store_id': storeId},
      options: Options(extra: <String, Object?>{'ref': ref}),
    );
    if (response.data is Map<String, Object?>) {
      ref.keepAlive();
      return storeOperationDaysConverter
          .fromJson(response.data! as Map<String, Object?>);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of the pickup eta for a specific store id.
final AutoDisposeFutureProviderFamily<StoreEtaModel?, int>
    storeEtaPickupProvider =
    FutureProvider.autoDispose.family<StoreEtaModel?, int>(
  (
    final AutoDisposeFutureProviderRef<StoreEtaModel?> ref,
    final int storeId,
  ) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      '/public/store/eta/pickup',
      queryParameters: <String, Object?>{'storeId': storeId},
      options: Options(extra: <String, Object?>{'ref': ref}),
    );
    if (response.data is Map<String, Object?>) {
      ref.keepAlive();
      return storeEtaConverter.fromJson(response.data! as Map<String, Object?>);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of the delivery eta for a specific store id.
final AutoDisposeFutureProviderFamily<StoreEtaModel?, int>
    storeEtaDeliveryProvider =
    FutureProvider.autoDispose.family<StoreEtaModel?, int>(
  (
    final AutoDisposeFutureProviderRef<StoreEtaModel?> ref,
    final int storeId,
  ) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final UserAddressesModel? currentAddress =
        await ref.watch(currentAddressProvider.future);
    if (currentAddress?.lat != null && currentAddress?.lng != null) {
      final Response<Object?> response = await dio.get<Object?>(
        '/public/store/eta/delivery',
        queryParameters: <String, Object?>{
          'storeId': storeId,
          'lat': currentAddress!.lat,
          'lng': currentAddress.lng
        },
        options: Options(extra: <String, Object?>{'ref': ref}),
      );
      if (response.data is Map<String, Object?>) {
        ref.keepAlive();
        return storeEtaConverter
            .fromJson(response.data! as Map<String, Object?>);
      }
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of the information for a specific product id.
final AutoDisposeFutureProviderFamily<StoreMenuProductsModel?, int>
    storeProductProvider =
    FutureProvider.autoDispose.family<StoreMenuProductsModel?, int>(
  (
    final AutoDisposeFutureProviderRef<StoreMenuProductsModel?> ref,
    final int productId,
  ) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      '/public/menu/product/$productId',
      options: Options(extra: <String, Object?>{'ref': ref}),
    );
    if (response.data is Map<String, Object?>) {
      ref.keepAlive();
      return storeMenuProductsConverter
          .fromJson(response.data! as Map<String, Object?>);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);
