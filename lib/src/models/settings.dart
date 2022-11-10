import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

import '../const.dart';
import '../providers/misc.dart';

part 'settings.g.dart';

/// The delivery type to use in the app.
enum DeliveryType {
  /// Means the product will be delivered to user.
  delivery,

  /// Means the user will pick up the product.
  pickup
}

/// The basic app's settings.
@collection
class Settings {
  /// The unique id of these settings. Should always be `0`.
  final Id id = 0;

  /// The state of the onboarding screen.
  bool onboarding = true;

  /// If the user skipped authorization.
  bool skippedAuthorization = false;

  /// If the user skipped setting up a default address.
  bool skippedDefaultAddress = false;

  /// The current picked delivery type.
  @enumerated
  DeliveryType deliveryType = DeliveryType.delivery;

  /// The current active token.
  Token? token;
}

@embedded
class Token {
  late String accessToken;

  late String refreshToken;

  late DateTime accessTokenExpirationDateTime;

  late String idToken;

  late String tokenType;
}

/// The stream of the current app's settings.
final StreamProvider<Settings> settingsProvider = StreamProvider<Settings>(
  (final StreamProviderRef<Settings> ref) async* {
    final Isar isar = await ref.watch(isarProvider.future);
    Settings? settings;
    await isar.writeTxn<void>(
      () async => isar.settings.put(
        /// Fail-safe method to keep settings valid when upgrading the app.
        settings = await isar.settings.get(0) ?? Settings(),
      ),
      silent: true,
    );
    yield settings!;
    yield* isar.settings.watchObject(0).where((final _) => _ != null).cast();
  },
  dependencies: <ProviderOrFamily>[isarProvider],
);

/// The current value of the [Settings.onboarding] property.
final FutureProvider<bool> onboardingProvider = FutureProvider<bool>(
  (final FutureProviderRef<bool> ref) async => await ref.watch(
    settingsProvider.future.select((final _) async => (await _).onboarding),
  ),
  dependencies: <ProviderOrFamily>[settingsProvider],
);

/// The current value of the [Settings.skippedAuthorization] property.
final FutureProvider<bool> skippedAuthorizationProvider = FutureProvider<bool>(
  (final FutureProviderRef<bool> ref) async => await ref.watch(
    settingsProvider.future
        .select((final _) async => (await _).skippedAuthorization),
  ),
  dependencies: <ProviderOrFamily>[settingsProvider],
);

/// The current value of the [Settings.skippedDefaultAddress] property.
final FutureProvider<bool> skippedDefaultAddressProvider = FutureProvider<bool>(
  (final FutureProviderRef<bool> ref) async => await ref.watch(
    settingsProvider.future
        .select((final _) async => (await _).skippedDefaultAddress),
  ),
  dependencies: <ProviderOrFamily>[settingsProvider],
);

/// The current value of the [Settings.onboarding] property.
final FutureProvider<DeliveryType> deliveryTypeProvider =
    FutureProvider<DeliveryType>(
  (final FutureProviderRef<DeliveryType> ref) async => await ref.watch(
    settingsProvider.future.select((final _) async => (await _).deliveryType),
  ),
  dependencies: <ProviderOrFamily>[settingsProvider],
);

/// Get the [Settings.token] property value and renew it if needed.
final AutoDisposeFutureProvider<Token?> tokenProvider =
    FutureProvider.autoDispose<Token?>(
  (final AutoDisposeFutureProviderRef<Token?> ref) async {
    final Token? currentToken = ref.watch(
      settingsProvider.select((final _) => _.valueOrNull?.token),
    );

    final DateTime serverTime;
    try {
      serverTime = ref.read(serverTimeProvider);
    } on Exception {
      return currentToken;
    }

    if (currentToken != null &&
        serverTime.isAfter(currentToken.accessTokenExpirationDateTime)) {
      final TokenResponse? response = await const FlutterAppAuth().token(
        TokenRequest(
          authClientId,
          authRedirectUrl,
          issuer: authDomain,
          scopes: <String>['openid', 'profile', 'offline_access'],
          refreshToken: currentToken.refreshToken,
        ),
      );
      if (response != null) {
        final Token token = Token()
          ..accessToken = response.accessToken ?? currentToken.accessToken
          ..accessTokenExpirationDateTime =
              response.accessTokenExpirationDateTime ??
                  currentToken.accessTokenExpirationDateTime
          ..idToken = response.idToken ?? currentToken.idToken
          ..refreshToken = response.refreshToken ?? currentToken.refreshToken
          ..tokenType = response.tokenType ?? currentToken.tokenType;
        final Isar isar = await ref.read(isarProvider.future);
        await isar.writeTxn(
          () async => isar.settings.put(
            await ref.read(settingsProvider.future)
              ..token = token,
          ),
        );
        ref.keepAlive();
        return token;
      }
    }
    return currentToken;
  },
  dependencies: <ProviderOrFamily>[settingsProvider, serverTimeProvider],
);

/// Renew the value of the [Settings.token] property if needed.
final AutoDisposeFutureProvider<Token?> authTokenProvider =
    FutureProvider.autoDispose<Token?>(
  (final AutoDisposeFutureProviderRef<Token?> ref) async {
    final Token? currentToken = await ref.watch(tokenProvider.future);
    if (currentToken == null) {
      final AuthorizationTokenResponse? response =
          await const FlutterAppAuth().authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          authClientId,
          authRedirectUrl,
          issuer: authDomain,
          scopes: <String>['openid', 'profile', 'offline_access'],
          promptValues: <String>['login'],
        ),
      );
      if (response != null) {
        final Token token = Token()
          ..accessToken = response.accessToken!
          ..accessTokenExpirationDateTime =
              response.accessTokenExpirationDateTime!
          ..idToken = response.idToken!
          ..refreshToken = response.refreshToken!
          ..tokenType = response.tokenType!;
        final Isar isar = await ref.read(isarProvider.future);
        await isar.writeTxn(
          () async => isar.settings.put(
            await ref.read(settingsProvider.future)
              ..token = token,
          ),
        );
        ref.keepAlive();
        return token;
      }
    }
    return currentToken;
  },
  dependencies: <ProviderOrFamily>[tokenProvider],
);
