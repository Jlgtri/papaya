part of '../api.dart';

/// The provider of the order price for the specified
/// [OrderCalculateRequestModel].
final AutoDisposeFutureProviderFamily<OrderCalculateModel?,
        OrderCalculateRequestModel> orderCalculateProvider =
    FutureProvider.family
        .autoDispose<OrderCalculateModel?, OrderCalculateRequestModel>(
  (
    final AutoDisposeFutureProviderRef<OrderCalculateModel?> ref,
    final OrderCalculateRequestModel request,
  ) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.put<Object?>(
      '/public/order/calculate',
      data: request.toMap(),
    );
    if (response.data is Map<String, Object?>) {
      ref.keepAlive();
      return orderCalculateConverter
          .fromJson(response.data! as Map<String, Object?>);
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[dioProvider],
);

/// The provider of the order price for the specified
/// [OrderCalculateRequestModel].
final AutoDisposeFutureProviderFamily<Object?, OrderRequestModel>
    orderProvider =
    FutureProvider.family.autoDispose<Object?, OrderRequestModel>(
  (
    final AutoDisposeFutureProviderRef<Object?> ref,
    final OrderRequestModel request,
  ) async {
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.idToken.isNotEmpty ?? false) {
      final Dio dio = await ref.watch(dioProvider.future);
      print(request.toJson());
      final Response<Object?> response = await dio.post<Object?>(
        '/public/order',
        data: request.toMap(),
        options: Options(
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: 'Bearer ${token!.idToken}',
          },
        ),
      );
      if (response.data is Map<String, Object?>) {
        ref.keepAlive();
        return response.data! as Map<String, Object?>;
      }
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[tokenProvider, dioProvider],
);




// /// The provider of the order for the specified [OrderRequestModel].
// final AutoDisposeFutureProviderFamily<OrderModel?, OrderRequestModel>
//     orderProvider =
//     FutureProvider.family.autoDispose<OrderModel?, OrderRequestModel>(
//   (
//     final AutoDisposeFutureProviderRef<OrderModel?> ref,
//     final OrderRequestModel request,
//   ) async {
//     final Dio dio = await ref.watch(dioProvider.future);
//     final Response<Object?> response;
//     try {
//       response =
//           await dio.post<Object?>('/public/order', data: request.toMap());
//     } on DioError catch (_, __) {
//       late final StreamSubscription<InternetConnectionStatus> subscription;
//       subscription = (InternetConnectionChecker().onStatusChange)
//           .listen((final InternetConnectionStatus status) async {
//         if (status == InternetConnectionStatus.connected) {
//           ref.invalidateSelf();
//           await subscription.cancel();
//         }
//       });
//       rethrow;
//     }
//     if (response.data is Map<String, Object?>) {
//       ref.keepAlive();
//       return OrderModel.fromMap(response.data! as Map<String, Object?>);
//     }
//     return null;
//   },
//   dependencies: <ProviderOrFamily>[dioProvider],
// );
