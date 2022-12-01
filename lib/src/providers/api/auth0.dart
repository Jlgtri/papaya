part of '../api.dart';

/// Get the [Settings.token] property value and renew it if needed.
final AutoDisposeFutureProvider<Token?> tokenProvider =
    FutureProvider.autoDispose<Token?>(
  (final AutoDisposeFutureProviderRef<Token?> ref) async {
    final Token? currentToken = ref.watch(
      settingsProvider.select((final _) => _.valueOrNull?.token),
    );
    if (currentToken != null &&
        ref.watch(
          serverTimeProvider.select(
            (final _) =>
                _.valueOrNull
                    ?.isAfter(currentToken.accessTokenExpirationDateTime) ??
                false,
          ),
        )) {
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
        final Settings settings = await ref.read(settingsProvider.future);
        await isar.writeTxn(() => isar.settings.put(settings..token = token));
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
        final Settings settings = await ref.read(settingsProvider.future);
        await isar.writeTxn(() => isar.settings.put(settings..token = token));
        ref.keepAlive();
        return token;
      }
    }
    return currentToken;
  },
  dependencies: <ProviderOrFamily>[tokenProvider],
);
