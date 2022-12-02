import 'dart:async';

import 'package:catcher/catcher.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:isar/isar.dart';
import 'package:ntp/ntp.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';

import '../models/address.dart';
import '../models/cart_store.dart';
import '../models/search_entry.dart';
import '../models/settings.dart';

/// The provider of the [Isar] database.
final FutureProvider<Isar> isarProvider = FutureProvider<Isar>(
  (final FutureProviderRef<Isar> ref) async {
    final Isar isar = await Isar.open(
      <CollectionSchema<Object?>>[
        AddressSchema,
        CartStoreSchema,
        SearchEntrySchema,
        SettingsSchema,
      ],
      directory: (await getApplicationDocumentsDirectory()).path,
    );
    ref.onDispose(isar.close);
    return isar;
  },
);

/// The provider of the error [Report] inside the app.
final StateProvider<Report?> errorProvider = StateProvider<Report?>(
  (final StateProviderRef<Report?> ref) => null,
);

/// The provider of the current server time.
final AsyncNotifierProvider<ServerTimeNotifier, DateTime> serverTimeProvider =
    AsyncNotifierProvider<ServerTimeNotifier, DateTime>(ServerTimeNotifier.new);

/// The notifier of the current server time.
class ServerTimeNotifier extends AsyncNotifier<DateTime> {
  /// The notifier of the current server time.
  ServerTimeNotifier();

  final Completer<DateTime> _serverTime = Completer<DateTime>();
  final Stopwatch _stopwatch = Stopwatch();
  // ignore: cancel_subscriptions
  StreamSubscription<InternetConnectionStatus>? _subscription;

  @override
  FutureOr<DateTime> build() async {
    try {
      if (!_serverTime.isCompleted) {
        _serverTime
            .complete(await NTP.now(timeout: const Duration(seconds: 1)));
        _stopwatch.start();
      }
    } on Exception catch (_, __) {
      _subscription ??= (InternetConnectionChecker().onStatusChange)
          .listen((final InternetConnectionStatus status) async {
        if (status == InternetConnectionStatus.connected &&
            !_serverTime.isCompleted) {
          _serverTime
              .complete(await NTP.now(timeout: const Duration(seconds: 1)));
          _stopwatch.start();
          await _subscription!.cancel();
          _subscription = null;
        }
      });
    }
    return (await _serverTime.future).add(_stopwatch.elapsed);
  }
}
