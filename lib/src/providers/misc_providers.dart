import 'package:catcher/catcher.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';

import '../models/cart_store.dart';
import '../models/search_entry.dart';
import '../models/settings.dart';

/// The provider of the [Isar] database.
final FutureProvider<Isar> isarProvider = FutureProvider<Isar>(
  (final FutureProviderRef<Isar> ref) async => Isar.open(
    <CollectionSchema<Object?>>[
      SettingsSchema,
      SearchEntrySchema,
      CartStoreSchema
    ],
    directory: (await getApplicationDocumentsDirectory()).path,
  ),
);

/// The provider of the error [Report] inside the app.
final StateProvider<Report?> errorProvider = StateProvider<Report?>(
  (final StateProviderRef<Report?> ref) => null,
);

final StateNotifierProvider<ServerTimeNotifier, DateTime> serverTimeProvider =
    StateNotifierProvider<ServerTimeNotifier, DateTime>(
  (final _) => ServerTimeNotifier(),
);

/// The notifier of the current server time.
class ServerTimeNotifier extends StateNotifier<DateTime> {
  /// The notifier of the current server time.
  ServerTimeNotifier([final DateTime? serverTime])
      : _valueSet = serverTime != null,
        super(serverTime ?? DateTime.now()) {
    _timer.start();
  }
  final Stopwatch _timer = Stopwatch();

  /// If the custom value was set on this notifier.
  bool get valueSet => _valueSet;
  bool _valueSet;

  /// Returns the current server time.
  @override
  DateTime get state => super.state.add(_timer.elapsed);

  /// Sets the current server time.
  @override
  set state(final DateTime serverTime) {
    _timer.reset();
    super.state = serverTime;
    _timer.start();
    _valueSet = true;
  }
}
