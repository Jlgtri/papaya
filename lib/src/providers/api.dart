import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:isar/isar.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod/riverpod.dart';

import '../const.dart';
import '../generated/models.g.dart';
import '../models/address.dart';
import '../models/settings.dart';
import '../providers/misc.dart';
import '../widgets/navigation/navigation.dart';

part 'api/auth0.dart';
part 'api/flags.dart';
part 'api/order.dart';
part 'api/payment.dart';
part 'api/stores.dart';
part 'api/user.dart';

/// The provider of an API client.
final FutureProvider<Dio> dioProvider = FutureProvider<Dio>(
  (final _) => Dio(
    BaseOptions(
      baseUrl: 'https://papaya-staging.ue.r.appspot.com',
      sendTimeout: 5000,
      connectTimeout: 5000,
      receiveTimeout: 5000,
      validateStatus: (final int? status) => status == 200,
    ),
  )..interceptors.add(_ExceptionInterceptor()),
);

class _ExceptionInterceptor extends Interceptor {
  @override
  Future<void> onError(
    final DioError error,
    final ErrorInterceptorHandler handler,
  ) async {
    if (error.requestOptions.method == 'GET') {
      final Object? ref = error.requestOptions.extra['ref'];
      if (ref is Ref && !await InternetConnectionChecker().hasConnection) {
        late final StreamSubscription<InternetConnectionStatus> subscription;
        subscription = (InternetConnectionChecker().onStatusChange)
            .listen((final InternetConnectionStatus status) async {
          subscription.pause();
          if (status == InternetConnectionStatus.connected) {
            ref.invalidateSelf();
            await subscription.cancel();
          } else {
            subscription.resume();
          }
        });
      }
    }
    handler.next(
      DioError(
        requestOptions: error.requestOptions,
        error: error.response,
        response: error.response,
        type: error.type,
      ),
    );
  }
}

/// The provider of the carousel.
final AutoDisposeFutureProvider<CarouselModel?> carouselProvider =
    FutureProvider.autoDispose<CarouselModel?>(
  (final AutoDisposeFutureProviderRef<CarouselModel?> ref) async {
    final Dio dio = await ref.watch(dioProvider.future);
    final Response<Object?> response = await dio.get<Object?>(
      'https://api.storyblok.com/v1/cdn/stories',
      queryParameters: <String, Object?>{
        'page1': null,
        'version': 'draft',
        'starts_with': 'app/discover/hero/',
        'token': 'bZerHxmHcQKtM5rM2oE8Lwtt'
      },
      options: Options(
        responseType: ResponseType.plain,
        extra: <String, Object?>{'ref': ref},
      ),
    );
    Object? responseData = response.data;
    if (responseData is String) {
      responseData = json.decode(responseData);
    }
    if (responseData is Map<String, Object?>) {
      ref.keepAlive();
      return carouselConverter.fromJson(responseData);
    }
    return null;
  },
);
