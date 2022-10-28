import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

import '../const.dart';
import '../providers/misc_providers.dart';

part 'settings.g.dart';

enum DeliveryType { delivery, pickup }

/// The basic app's settings.
@collection
class Settings {
  /// The unique id of these settings. Should always be `0`.
  final Id id = 0;

  /// The state of the onboarding screen.
  bool onboarding = true;

  /// The current picked delivery type.
  @enumerated
  DeliveryType deliveryType = DeliveryType.delivery;

  /// The current active tokens.
  List<Token> tokens = <Token>[];
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
    await isar.writeTxn<void>(silent: true, () async {
      if ((settings = await isar.settings.get(0)) == null) {
        await isar.settings.put(settings = Settings());
      }
    });
    yield settings!;
    yield* isar.settings.watchObject(0).where((final _) => _ != null).cast();
  },
  dependencies: <ProviderOrFamily>[isarProvider],
);

/// The current value of the [Settings.onboarding] property.
final AutoDisposeFutureProvider<bool> onboardingProvider =
    FutureProvider.autoDispose<bool>(
  (final AutoDisposeFutureProviderRef<bool> ref) async => await ref.watch(
    settingsProvider.future.select((final _) async => (await _).onboarding),
  ),
  dependencies: <ProviderOrFamily>[settingsProvider],
);

/// The current value of the [Settings.onboarding] property.
final AutoDisposeFutureProvider<DeliveryType> deliveryTypeProvider =
    FutureProvider.autoDispose<DeliveryType>(
  dependencies: <ProviderOrFamily>[settingsProvider],
  (final AutoDisposeFutureProviderRef<DeliveryType> ref) async =>
      await ref.watch(
    settingsProvider.future.select((final _) async => (await _).deliveryType),
  ),
);

/// Get the [Settings.tokens] property value and renew it if needed.
final AutoDisposeFutureProvider<Token?> tokenProvider =
    FutureProvider.autoDispose<Token?>(
  (final AutoDisposeFutureProviderRef<Token?> ref) async {
    final Token? currentToken = ref.watch(
      settingsProvider.select((final _) {
        final List<Token> tokens = _.valueOrNull?.tokens ?? Settings().tokens;
        return tokens.isEmpty ? null : tokens.first;
      }),
    );
    if (currentToken != null &&
        currentToken.accessTokenExpirationDateTime
            .isBefore(ref.read(serverTimeProvider))) {
      final TokenResponse? response = await const FlutterAppAuth().token(
        TokenRequest(
          authClientId,
          authRedirectUrl,
          issuer: 'https://$authDomain',
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
              ..tokens = <Token>[token],
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

/// Renew the value of the [Settings.tokens] property if needed.
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
          issuer: 'https://$authDomain',
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
              ..tokens = <Token>[token],
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
