part of '../api.dart';

/// The provider of all stores.
final AutoDisposeFutureProvider<FlagsModel?> flagsProvider =
    FutureProvider.autoDispose<FlagsModel?>(
  (final AutoDisposeFutureProviderRef<FlagsModel?> ref) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      '/public/flags',
      options: Options(extra: <String, Object?>{'ref': ref}),
    );
    if (response.data is Map<String, Object?>) {
      ref.keepAlive();
      return FlagsModel.fromMap(response.data! as Map<String, Object?>);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of all stores.
final AutoDisposeFutureProvider<FlagsModel?> flagsFailSafeProvider =
    FutureProvider.autoDispose<FlagsModel?>(
  (final AutoDisposeFutureProviderRef<FlagsModel?> ref) async {
    try {
      return await ref.watch(flagsProvider.future);
    } on Exception catch (_, __) {
      return null;
    }
  },
  dependencies: <ProviderOrFamily>[flagsProvider],
);
