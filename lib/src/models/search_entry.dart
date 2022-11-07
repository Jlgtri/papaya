import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

import '../providers/misc.dart';

part 'search_entry.g.dart';

/// The saved entered search value.
@collection
class SearchEntry {
  /// The unique id of this search entry.
  final Id id = Isar.autoIncrement;

  /// The entered value.
  late String value;

  /// The date and time the value was entered.
  late DateTime timestamp;
}

/// The provider of the recent search entries.
final StreamProvider<Iterable<String>> recentSearchEntriesProvider =
    StreamProvider<Iterable<String>>(
        (final StreamProviderRef<Iterable<String>> ref) async* {
  final Isar isar = await ref.watch(isarProvider.future);
  yield* isar.searchEntrys
      .where(distinct: true)
      .sortByTimestampDesc()
      .limit(5)
      .valueProperty()
      .watch(fireImmediately: true);
});
