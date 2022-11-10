import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod/riverpod.dart';

import '../generated/models.g.dart';
import '../models/address.dart';
import '../models/settings.dart';
import '../widgets/navigation.dart';

/// The provider of an API client.
final FutureProvider<Dio> dioProvider = FutureProvider<Dio>(
  (final _) => Dio(
    BaseOptions(
      baseUrl: 'https://papaya-staging.ue.r.appspot.com',
      sendTimeout: 5000,
      connectTimeout: 2500,
      receiveTimeout: 5000,
      validateStatus: (final int? status) => status == 200,
    ),
  ),
);

/// The provider of all stores.
final AutoDisposeFutureProvider<Iterable<StoreModel>?> allStoresProvider =
    FutureProvider.autoDispose<Iterable<StoreModel>?>(
        (final AutoDisposeFutureProviderRef<Iterable<StoreModel>?> ref) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final Response<Object?> response;
  try {
    response = await dio.get<Object?>('/public/store/all');
  } on DioError catch (_) {
    late final StreamSubscription<InternetConnectionStatus> subscription;
    subscription = (InternetConnectionChecker().onStatusChange)
        .listen((final InternetConnectionStatus status) async {
      if (status == InternetConnectionStatus.connected) {
        ref.invalidateSelf();
        await subscription.cancel();
      }
    });
    rethrow;
  }
  if (response.data is Iterable<Object?>) {
    ref.keepAlive();
    return (response.data! as Iterable<Object?>)
        .whereType<Map<String, Object?>>()
        .map(storeConverter.fromJson);
  }
  return null;
});

/// The provider of nearby stores depending on [LatLng].
final AutoDisposeFutureProviderFamily<Iterable<StoreModel>?, LatLng>
    nearbyStoresProvider =
    FutureProvider.autoDispose.family<Iterable<StoreModel>?, LatLng>((
  final AutoDisposeFutureProviderRef<Iterable<StoreModel>?> ref,
  final LatLng latLng,
) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final Response<Object?> response;
  try {
    response = await dio.get<Object?>(
      '/public/store/nearby',
      queryParameters: <String, Object?>{
        'lat': latLng.latitude,
        'lng': latLng.longitude,
      },
    );
  } on DioError catch (_) {
    late final StreamSubscription<InternetConnectionStatus> subscription;
    subscription = (InternetConnectionChecker().onStatusChange)
        .listen((final InternetConnectionStatus status) async {
      if (status == InternetConnectionStatus.connected) {
        ref.invalidateSelf();
        await subscription.cancel();
      }
    });
    rethrow;
  }
  if (response.data is Iterable<Object?>) {
    ref.keepAlive();
    return (response.data! as Iterable<Object?>)
        .whereType<Map<String, Object?>>()
        .map(storeConverter.fromJson);
  }
  return null;
});

/// The provider of stores depending on [deliveryTypeProvider].
///
/// * If delivery type is [DeliveryType.delivery], returns the
/// [nearbyStoresProvider] with the [activeAddressProvider] LatLng.
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
          await ref.watch(activeAddressProvider.future);
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
    activeAddressProvider,
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
    FutureProvider.autoDispose.family<StoreModel?, int>((
  final AutoDisposeFutureProviderRef<StoreModel?> ref,
  final int storeId,
) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final Response<Object?> response;
  try {
    response = await dio.get<Object?>('/public/store/$storeId');
  } on DioError catch (_) {
    late final StreamSubscription<InternetConnectionStatus> subscription;
    subscription = (InternetConnectionChecker().onStatusChange)
        .listen((final InternetConnectionStatus status) async {
      if (status == InternetConnectionStatus.connected) {
        ref.invalidateSelf();
        await subscription.cancel();
      }
    });
    rethrow;
  }
  if (response.data is Map<String, Object?>) {
    ref.keepAlive();
    return storeConverter.fromJson(response.data! as Map<String, Object?>);
  }
  return null;
});

/// The provider of the menu for a specific store id.
final AutoDisposeFutureProviderFamily<Iterable<StoreMenuModel>?, int>
    storeMenuProvider =
    FutureProvider.autoDispose.family<Iterable<StoreMenuModel>?, int>((
  final AutoDisposeFutureProviderRef<Iterable<StoreMenuModel>?> ref,
  final int storeId,
) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final Response<Object?> response;
  try {
    response = await dio.get<Object?>(
      '/public/store/menu',
      queryParameters: <String, Object?>{'store_id': storeId},
    );
  } on DioError catch (_) {
    late final StreamSubscription<InternetConnectionStatus> subscription;
    subscription = (InternetConnectionChecker().onStatusChange)
        .listen((final InternetConnectionStatus status) async {
      if (status == InternetConnectionStatus.connected) {
        ref.invalidateSelf();
        await subscription.cancel();
      }
    });
    rethrow;
  }
  if (response.data is Iterable<Object?>) {
    ref.keepAlive();
    return (response.data! as Iterable<Object?>)
        .whereType<Map<String, Object?>>()
        .map(storeMenuConverter.fromJson);
  }
  return null;
});

/// The provider of the operational days for a specific store id.
final AutoDisposeFutureProviderFamily<StoreOperationDaysModel?, int>
    storeOperationDaysProvider =
    FutureProvider.autoDispose.family<StoreOperationDaysModel?, int>((
  final AutoDisposeFutureProviderRef<StoreOperationDaysModel?> ref,
  final int storeId,
) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final Response<Object?> response;
  try {
    response = await dio.get<Object?>(
      '/public/store/operation_days',
      queryParameters: <String, Object?>{'store_id': storeId},
    );
  } on DioError catch (_) {
    late final StreamSubscription<InternetConnectionStatus> subscription;
    subscription = (InternetConnectionChecker().onStatusChange)
        .listen((final InternetConnectionStatus status) async {
      if (status == InternetConnectionStatus.connected) {
        ref.invalidateSelf();
        await subscription.cancel();
      }
    });
    rethrow;
  }
  if (response.data is Map<String, Object?>) {
    ref.keepAlive();
    return storeOperationDaysConverter
        .fromJson(response.data! as Map<String, Object?>);
  }
  return null;
});

/// The provider of the pickup eta for a specific store id.
final AutoDisposeFutureProviderFamily<StoreEtaPickupModel?, int>
    storeEtaPickupProvider =
    FutureProvider.autoDispose.family<StoreEtaPickupModel?, int>((
  final AutoDisposeFutureProviderRef<StoreEtaPickupModel?> ref,
  final int storeId,
) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final Response<Object?> response;
  try {
    response = await dio.get<Object?>(
      '/public/store/eta/pickup',
      queryParameters: <String, Object?>{'storeId': storeId},
    );
  } on DioError catch (_) {
    late final StreamSubscription<InternetConnectionStatus> subscription;
    subscription = (InternetConnectionChecker().onStatusChange)
        .listen((final InternetConnectionStatus status) async {
      if (status == InternetConnectionStatus.connected) {
        ref.invalidateSelf();
        await subscription.cancel();
      }
    });
    rethrow;
  }
  if (response.data is Map<String, Object?>) {
    ref.keepAlive();
    return storeEtaPickupConverter
        .fromJson(response.data! as Map<String, Object?>);
  }
  return null;
});

/// The provider of the delivery eta for a specific store id.
final AutoDisposeFutureProviderFamily<StoreEtaDeliveryModel?, int>
    storeEtaDeliveryProvider =
    FutureProvider.autoDispose.family<StoreEtaDeliveryModel?, int>((
  final AutoDisposeFutureProviderRef<StoreEtaDeliveryModel?> ref,
  final int storeId,
) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final UserAddressesModel? currentAddress =
      await ref.watch(activeAddressProvider.future);
  if (currentAddress?.lat != null && currentAddress?.lng != null) {
    final Response<Object?> response;
    try {
      response = await dio.get<Object?>(
        '/public/store/eta/delivery',
        queryParameters: <String, Object?>{
          'storeId': storeId,
          'lat': currentAddress!.lat,
          'lng': currentAddress.lng
        },
      );
    } on DioError catch (_) {
      late final StreamSubscription<InternetConnectionStatus> subscription;
      subscription = (InternetConnectionChecker().onStatusChange)
          .listen((final InternetConnectionStatus status) async {
        if (status == InternetConnectionStatus.connected) {
          ref.invalidateSelf();
          await subscription.cancel();
        }
      });
      rethrow;
    }
    if (response.data is Map<String, Object?>) {
      ref.keepAlive();
      return storeEtaDeliveryConverter
          .fromJson(response.data! as Map<String, Object?>);
    }
  }
  return null;
});

/// The provider of the information for a specific product id.
final AutoDisposeFutureProviderFamily<StoreMenuProductsModel?, int>
    storeProductProvider =
    FutureProvider.autoDispose.family<StoreMenuProductsModel?, int>((
  final AutoDisposeFutureProviderRef<StoreMenuProductsModel?> ref,
  final int productId,
) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final Response<Object?> response;
  try {
    response = await dio.get<Object?>('/public/menu/product/$productId');
  } on DioError catch (_) {
    late final StreamSubscription<InternetConnectionStatus> subscription;
    subscription = (InternetConnectionChecker().onStatusChange)
        .listen((final InternetConnectionStatus status) async {
      if (status == InternetConnectionStatus.connected) {
        ref.invalidateSelf();
        await subscription.cancel();
      }
    });
    rethrow;
  }
  if (response.data is Map<String, Object?>) {
    ref.keepAlive();
    return storeMenuProductsConverter
        .fromJson(response.data! as Map<String, Object?>);
  }
  return null;
});

final AutoDisposeFutureProvider<Iterable<UserAddressesModel>?>
    addressesProvider =
    FutureProvider.autoDispose<Iterable<UserAddressesModel>?>(
  (
    final AutoDisposeFutureProviderRef<Iterable<UserAddressesModel>?> ref,
  ) async {
    return [];
    final Dio dio = await ref.watch(dioProvider.future);
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.accessToken.isNotEmpty ?? false) {
      final Response<Object?> response = await dio.get<Object?>(
        '/user/addresses',
        options: Options(
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: token!.accessToken,
          },
        ),
      );
      if (response.data is Iterable<Object?>) {
        ref.keepAlive();
        return (response.data! as Iterable<Object?>)
            .whereType<Map<String, Object?>>()
            .map(userAddressesConverter.fromJson);
      }
    }
    return null;
  },
);

final AutoDisposeFutureProvider<Iterable<UserAddressesModel>?>
    activeAddressesProvider =
    FutureProvider.autoDispose<Iterable<UserAddressesModel>?>(
  (
    final AutoDisposeFutureProviderRef<Iterable<UserAddressesModel>?> ref,
  ) async =>
      await ref.watch(skippedAuthorizationProvider.future)
          ? await ref.watch(isarAddressesProvider.future)
          : await ref.watch(addressesProvider.future),
  dependencies: <ProviderOrFamily>[
    skippedAuthorizationProvider,
    isarAddressesProvider,
    addressesProvider
  ],
);

final AutoDisposeFutureProvider<UserAddressesModel?> activeAddressProvider =
    FutureProvider.autoDispose<UserAddressesModel?>(
  (final AutoDisposeFutureProviderRef<UserAddressesModel?> ref) async =>
      await ref.watch(skippedAuthorizationProvider.future)
          ? await ref.watch(
              isarAddressesProvider.future.select(
                (final Future<Iterable<UserAddressesModel>> _) async =>
                    (await _).firstWhereOrNull(
                  (final _) => _.defaultAddress ?? false,
                ),
              ),
            )
          : await ref.watch(
              addressesProvider.selectAsync(
                (final Iterable<UserAddressesModel>? addresses) => addresses
                    ?.firstWhereOrNull((final _) => _.defaultAddress ?? false),
              ),
            ),
  dependencies: <ProviderOrFamily>[
    skippedAuthorizationProvider,
    isarAddressesProvider,
    addressesProvider
  ],
);

/// The provider of the carousel.
final AutoDisposeFutureProvider<CarouselModel?> carouselProvider =
    FutureProvider.autoDispose<CarouselModel?>((
  final AutoDisposeFutureProviderRef<CarouselModel?> ref,
) async {
  final Dio dio = await ref.watch(dioProvider.future);
  final Response<Object?> response;
  try {
    response = await dio.get<Object?>(
      'https://api.storyblok.com/v1/cdn/stories',
      queryParameters: <String, Object?>{
        'page1': null,
        'version': 'draft',
        'starts_with': 'app/discover/hero/',
        'token': 'bZerHxmHcQKtM5rM2oE8Lwtt'
      },
      options: Options(responseType: ResponseType.plain),
    );
  } on DioError catch (_) {
    late final StreamSubscription<InternetConnectionStatus> subscription;
    subscription = (InternetConnectionChecker().onStatusChange)
        .listen((final InternetConnectionStatus status) async {
      if (status == InternetConnectionStatus.connected) {
        ref.invalidateSelf();
        await subscription.cancel();
      }
    });
    rethrow;
  }
  Object? responseData = response.data;
  if (responseData is String) {
    responseData = json.decode(responseData);
  }
  if (responseData is Map<String, Object?>) {
    ref.keepAlive();
    return carouselConverter.fromJson(responseData);
  }
  return null;
});
