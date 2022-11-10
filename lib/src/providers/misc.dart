import 'package:catcher/catcher.dart';
import 'package:isar/isar.dart';
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
final StateNotifierProvider<ServerTimeNotifier, DateTime> serverTimeProvider =
    StateNotifierProvider<ServerTimeNotifier, DateTime>(
  (final _) => throw Exception(),
);

/// The notifier of the current server time.
class ServerTimeNotifier extends StateNotifier<DateTime> {
  /// The notifier of the current server time.
  ServerTimeNotifier(super.serverTime);
  final Stopwatch _timer = Stopwatch()..start();

  /// Returns the current server time.
  @override
  DateTime get state => super.state.add(_timer.elapsed);
}
