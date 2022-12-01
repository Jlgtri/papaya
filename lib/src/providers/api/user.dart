part of '../api.dart';

/// The provider of the user's credit cards.
final AutoDisposeFutureProvider<Iterable<CreditCardModel>?>
    creditCardsProvider =
    FutureProvider.autoDispose<Iterable<CreditCardModel>?>(
  (final AutoDisposeFutureProviderRef<Iterable<CreditCardModel>?> ref) async {
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.idToken.isNotEmpty ?? false) {
      final Dio dio = await ref.watch(dioProvider.future);
      final Response<Object?> response = await dio.get<Object?>(
        '/user/profile/cards',
        options: Options(
          extra: <String, Object?>{'ref': ref},
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: 'Bearer ${token!.idToken}',
          },
        ),
      );
      if (response.data is Iterable<Object?>) {
        ref.keepAlive();
        return (response.data! as Iterable<Object?>)
            .whereType<Map<String, Object?>>()
            .map(creditCardConverter.fromJson);
      }
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider, tokenProvider],
);

/// The provider of the current authorized user's profile.
final AutoDisposeFutureProviderFamily<UserProfileModel?, UserProfileModel?>
    profileProvider =
    FutureProvider.family.autoDispose<UserProfileModel?, UserProfileModel?>(
  (
    final AutoDisposeFutureProviderRef<UserProfileModel?> ref,
    final UserProfileModel? profile,
  ) async {
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.idToken.isNotEmpty ?? false) {
      final Dio dio = await ref.watch(dioProvider.future);
      final Response<Object?> response = await dio.fetch(
        Options(
          method: profile == null ? 'GET' : 'PATCH',
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: 'Bearer ${token!.idToken}',
          },
        ).compose(
          dio.options,
          '/user/profile',
          data: profile != null
              ? <String, Object?>{
                  for (final MapEntry<String, Object?> entry
                      in profile.toMap().entries)
                    if (<String>{'given_name', 'family_name', 'phone', 'email'}
                            .contains(entry.key) &&
                        entry.value is String &&
                        (entry.value! as String).isNotEmpty)
                      entry.key: entry.value
                }
              : null,
          options: Options(extra: <String, Object?>{'ref': ref}),
        ),
      );
      if (response.data is Map<String, Object?>) {
        profile == null
            ? ref.keepAlive()
            : ref.invalidate(profileProvider(null));
        return userProfileConverter
            .fromJson(response.data! as Map<String, Object?>);
      }
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider, tokenProvider],
);

/// The provider of the current authorized user's addresses.
final AutoDisposeFutureProvider<Iterable<UserAddressesModel>?>
    addressesProvider =
    FutureProvider.autoDispose<Iterable<UserAddressesModel>?>(
  (
    final AutoDisposeFutureProviderRef<Iterable<UserAddressesModel>?> ref,
  ) async {
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.idToken.isNotEmpty ?? false) {
      final Dio dio = await ref.watch(dioProvider.future);
      final Response<Object?> response = await dio.get<Object?>(
        '/user/addresses',
        options: Options(
          extra: <String, Object?>{'ref': ref},
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: 'Bearer ${token!.idToken}',
          },
        ),
      );
      if (response.data is Iterable<Object?>) {
        ref.keepAlive();
        return (response.data! as Iterable<Object?>)
            .whereType<Map<String, Object?>>()
            .map(userAddressesConverter.fromJson)
            .map((final _) => _.convert().convert());
      }
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider, tokenProvider],
);

/// The provider of the current user's addresses.
final AutoDisposeFutureProvider<Iterable<UserAddressesModel>?>
    currentAddressesProvider =
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

/// The provider of the current user's default address.
final AutoDisposeFutureProvider<UserAddressesModel?> currentAddressProvider =
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
              addressesProvider.future.select(
                (final Future<Iterable<UserAddressesModel>?> _) async =>
                    (await _)?.firstWhereOrNull(
                  (final _) => _.defaultAddress ?? false,
                ),
              ),
            ),
  dependencies: <ProviderOrFamily>[
    skippedAuthorizationProvider,
    isarAddressesProvider,
    addressesProvider
  ],
);

/// The provider of the current user's default address.
final AutoDisposeFutureProviderFamily<int?, UserAddressesModel>
    addressProvider =
    FutureProvider.family.autoDispose<int?, UserAddressesModel>(
  (
    final AutoDisposeFutureProviderRef<int?> ref,
    final UserAddressesModel address,
  ) async {
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.idToken.isNotEmpty ?? false) {
      final Dio dio = await ref.watch(dioProvider.future);
      final Response<Object?> response = await dio.fetch(
        Options(
          method: address.addressId == null ? 'POST' : 'PATCH',
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: 'Bearer ${token!.idToken}',
          },
        ).compose(dio.options, '/user/address', data: address.toMap()),
      );
      if (response.data is Map<String, Object?>) {
        final Object? resultId =
            (response.data! as Map<String, Object?>).values.firstOrNull;
        final int? addressId = resultId is int ? resultId : null;
        if (addressId != null) {
          await ref.read(defaultAddressProvider(addressId).future);
        }
        ref.invalidate(addressesProvider);
        return addressId;
      }
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider, tokenProvider],
);

/// The provider of the deactivator for the address.
final AutoDisposeFutureProviderFamily<bool, int> activeAddressProvider =
    FutureProvider.family.autoDispose<bool, int>(
  (final AutoDisposeFutureProviderRef<bool> ref, final int addressId) async {
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.idToken.isNotEmpty ?? false) {
      final Dio dio = await ref.watch(dioProvider.future);
      final Response<Object?> response = await dio.patch(
        '/user/address/active/$addressId',
        options: Options(
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: 'Bearer ${token!.idToken}',
          },
        ),
        data: UserAddressesModel(userAddressId: addressId).toMap(),
      );
      ref.invalidate(addressesProvider);
      return response.statusCode == 200;
    }
    return false;
  },
  dependencies: <ProviderOrFamily>[dioProvider, tokenProvider],
);

/// The provider of the change request for default status of the address.
final AutoDisposeFutureProviderFamily<bool, int> defaultAddressProvider =
    FutureProvider.family.autoDispose<bool, int>(
  (final AutoDisposeFutureProviderRef<bool> ref, final int addressId) async {
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.idToken.isNotEmpty ?? false) {
      final Dio dio = await ref.watch(dioProvider.future);
      final Response<Object?> response = await dio.patch(
        '/user/address/default/$addressId',
        options: Options(
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: 'Bearer ${token!.idToken}',
          },
        ),
        data: UserAddressesModel(userAddressId: addressId).toMap(),
      );
      ref.invalidate(addressesProvider);
      return response.statusCode == 200;
    }
    return false;
  },
  dependencies: <ProviderOrFamily>[dioProvider, tokenProvider],
);
