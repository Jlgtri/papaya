part of '../api.dart';

/// The provider of the order price for the specified
/// [OrderCalculateRequestModel].
final AutoDisposeFutureProviderFamily<PaymentIntentModel?,
        PaymentIntentRequestModel> paymentIntentProvider =
    FutureProvider.family
        .autoDispose<PaymentIntentModel?, PaymentIntentRequestModel>(
  (
    final AutoDisposeFutureProviderRef<PaymentIntentModel?> ref,
    final PaymentIntentRequestModel request,
  ) async {
    final Token? token = await ref.watch(tokenProvider.future);
    if (token?.idToken.isNotEmpty ?? false) {
      final Dio dio = await ref.watch(dioProvider.future);
      final Response<Object?> response = await dio.post<Object?>(
        '/public/payment/intent',
        data: request.toMap(),
        options: Options(
          headers: <String, Object?>{
            HttpHeaders.authorizationHeader: 'Bearer ${token!.idToken}',
          },
        ),
      );
      if (response.data is Map<String, Object?>) {
        ref.keepAlive();
        return paymentIntentConverter
            .fromJson(response.data! as Map<String, Object?>);
      }
    }
    return null;
  },
  dependencies: <ProviderOrFamily>[tokenProvider, dioProvider],
);
