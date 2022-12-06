part of '../api.dart';

/// The provider of the current server time.
final AutoDisposeAsyncNotifierProvider<TokenNotifier, Token?> tokenProvider =
    AsyncNotifierProvider.autoDispose<TokenNotifier, Token?>(
  TokenNotifier.new,
  dependencies: <ProviderOrFamily>[settingsProvider, serverTimeProvider],
);

/// The notifier of the current server time.
class TokenNotifier extends AutoDisposeAsyncNotifier<Token?> {
  /// The notifier of the current server time.
  TokenNotifier();

  Future<void>? _refreshFuture;

  @override
  Future<Token?> build() async {
    final Token? currentToken = ref.watch(
      settingsProvider.select((final _) => _.valueOrNull?.token),
    );
    if (currentToken != null) {
      /// If token is not expired.
      if (await ref.watch(
        serverTimeProvider.future.select(
          (final _) async =>
              (await _).isBefore(currentToken.accessTokenExpirationDateTime),
        ),
      )) {
        /// Try again when token expires.
        _refreshFuture ??= Future<void>.delayed(
          currentToken.accessTokenExpirationDateTime
              .difference(await ref.read(serverTimeProvider.future)),
          () => ref.invalidate(serverTimeProvider),
        ).then((final _) => _refreshFuture = null);
        ref.keepAlive();
        return currentToken;
      } else if (currentToken.refreshToken.isEmpty) {
        return null;
      }

      /// Refresh the token.
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
        return _setToken(response);
      }
    }
    return currentToken;
  }

  /// Renew the value of the [Settings.token] property if needed.
  Future<Token?> authorize() async {
    final Token? token = await future;
    if (token == null) {
      if (state != const AsyncLoading<Token>()) {
        state = const AsyncLoading<Token>();
      }
      state = await AsyncValue.guard(() async {
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
        return response != null ? _setToken(response) : null;
      });
    }
    return token;
  }

  Future<Token> _setToken(final TokenResponse response) async {
    ref.keepAlive();
    final Token token = Token()
      ..accessToken = response.accessToken!
      ..accessTokenExpirationDateTime = response.accessTokenExpirationDateTime!
      ..idToken = response.idToken!
      ..refreshToken = response.refreshToken ?? ''
      ..tokenType = response.tokenType!;
    final Isar isar = await ref.read(isarProvider.future);
    final Settings settings = await ref.read(settingsProvider.future);
    await isar.writeTxn(() => isar.settings.put(settings..token = token));
    return token;
  }
}
