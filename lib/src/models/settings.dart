import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

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
