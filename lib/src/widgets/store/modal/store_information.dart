import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../const.dart';
import '../../../generated/assets.g.dart';
import '../../../generated/i18n.g.dart';
import '../../../generated/icons.g.dart';
import '../../../generated/models.g.dart';
import '../../../hooks/sync_callback_hook.dart';
import '../../../providers/api.dart';
import '../../../providers/location.dart';
import '../store.dart';

/// The screen used to show off a [store] information.
@immutable
class StoreInformationScreen extends HookConsumerWidget {
  /// The screen used to show off a [store] information.
  const StoreInformationScreen(this.store, {super.key});

  /// The store to show this screen for.
  final StoreModel store;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    final ValueNotifier<bool> viewWorkingHours = useState(false);
    final AnimationController animationController = useAnimationController(
      duration: const Duration(milliseconds: 350),
    );
    useMemoized(
      () => viewWorkingHours.addListener(
        () => viewWorkingHours.value
            ? animationController.forward()
            : animationController.reverse(),
      ),
    );
    final AsyncValue<Iterable<LatLng>>? storeLocation =
        store.address?.displayLong?.isNotEmpty ?? true
            ? null
            : ref.watch(locationProvider(store.address!.displayLong!));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
      ),
      child: SafeArea(
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: 280,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (storeLocation is AsyncLoading)
                      const Center(child: CircularProgressIndicator.adaptive())
                    else if (storeLocation?.valueOrNull?.firstOrNull == null)
                      CachedNetworkImage(
                        imageUrl: store.imgUrl ?? '',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorWidget: (final _, final __, final ___) =>
                            Image.asset(assets.logo, fit: BoxFit.cover),
                      )
                    else
                      FlutterMap(
                        options: MapOptions(
                          keepAlive: true,
                          zoom: 14,
                          center: storeLocation!.value!.first,
                          interactiveFlags: InteractiveFlag.none,
                        ),
                        children: <Widget>[
                          TileLayer(urlTemplate: mapTileUrl, minZoom: 4),
                          MarkerLayer(
                            markers: <Marker>[
                              Marker(
                                point: storeLocation.value!.first,
                                rotate: false,
                                builder: (final _) => Icon(
                                  icons.location,
                                  color: theme.colorScheme.primary,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    /// Close Button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: IconButton(
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(32),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.surface,
                          ),
                          icon: Icon(icons.crossBold, size: 13),
                          color: theme.colorScheme.primary,
                          onPressed: () async =>
                              syncCallback(navigator.maybePop),
                        ),
                      ),
                    ),

                    /// Grab Widget
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Material(
                          color: theme.colorScheme.onSurface,
                          clipBehavior: Clip.antiAlias,
                          borderRadius: BorderRadius.circular(4),
                          child: const SizedBox(height: 4, width: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Name
              if (store.name != null) ...<Widget>[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    store.name!,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 30,
                      height: 40 / 30,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],

              /// Description
              if (store.description != null) ...<Widget>[
                const SizedBox(height: 8),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      store.description!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.shadow,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Divider(height: 1, color: theme.colorScheme.outline),

              /// Address
              if (store.address?.displayLong != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.shadow,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                  ),
                  onPressed: () async =>
                      FlutterClipboard.copy(store.address!.displayLong!),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        icons.marker,
                        color: theme.colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 17.5),
                      Expanded(
                        child: Text(
                          store.address!.displayLong!,
                          style: theme.textTheme.bodyLarge,
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(width: 32),
                      Icon(
                        icons.copy,
                        color: theme.colorScheme.primary,
                        size: 24,
                      )
                    ],
                  ),
                ),

              /// Working Time
              Divider(height: 1, color: theme.colorScheme.outline),
              Flexible(
                child: Consumer(
                  builder: (
                    final _,
                    final WidgetRef ref,
                    final Widget? child,
                  ) =>
                      (ref.watch(storeOperationDaysProvider(store.id!))).when(
                    data: (final StoreOperationDaysModel? operationDays) =>
                        operationDays == null
                            ? const SizedBox.shrink()
                            : TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.shadow,
                                  shape: const RoundedRectangleBorder(),
                                ),
                                onPressed: () => viewWorkingHours.value =
                                    !viewWorkingHours.value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 24,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Icon(
                                        icons.clock,
                                        color: theme.colorScheme.secondary,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: AnimatedSize(
                                          duration:
                                              animationController.duration!,
                                          curve: Curves.fastOutSlowIn,
                                          alignment: Alignment.topCenter,
                                          child: StoreInformationOperationDays(
                                            operationDays,
                                            extended: viewWorkingHours.value,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      RotationTransition(
                                        turns:
                                            Tween<double>(begin: 0, end: 1 / 2)
                                                .animate(
                                          CurvedAnimation(
                                            parent: animationController,
                                            curve: viewWorkingHours.value
                                                ? Curves.easeOut
                                                : Curves.easeIn,
                                          ),
                                        ),
                                        child: Icon(
                                          icons.arrow.down,
                                          color: theme.colorScheme.shadow,
                                          size: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                    error: (final _, final __) => const SizedBox.shrink(),
                    loading: () => const SizedBox(
                      height: 72,
                      child:
                          Center(child: CircularProgressIndicator.adaptive()),
                    ),
                  ),
                ),
              ),
              if (!viewWorkingHours.value) const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties..add(DiagnosticsProperty<StoreModel>('store', store)),
      );
}

/// The widget used to display working hours information on a
/// [StoreInformationScreen].
@immutable
class StoreInformationOperationDays extends HookConsumerWidget {
  /// The widget used to display working hours information on a
  /// [StoreInformationScreen].
  const StoreInformationOperationDays(
    this.operationDays, {
    required this.extended,
    super.key,
  });

  /// The working hours information to show.
  final StoreOperationDaysModel operationDays;

  /// If the information should be extended.
  final bool extended;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final I18N $ = I18NLocalizations.of(context);

    String getWeekDayName(final int weekday) => DateFormat('EEEE').format(
          DateTime.fromMicrosecondsSinceEpoch(0).add(
            Duration(
              days: weekday + 3,
            ),
          ),
        );

    String getTime(final DateTime dateTime) =>
        DateFormat('hh:mm').format(dateTime);

    final String currentTime = useMemoized(
      () {
        DateTime fromHours(final DateTime now, final String? hours) {
          final Iterable<String> hoursParts =
              hours?.split(':') ?? const Iterable<String>.empty();
          return DateTime(
            now.year,
            now.month,
            now.day,
            int.tryParse(hoursParts.firstOrNull ?? '') ?? 0,
            hoursParts.length > 1
                ? int.tryParse(hoursParts.lastOrNull ?? '') ?? 0
                : 0,
          );
        }

        final DateTime now = DateTime.now();
        final StoreOperationDaysStoreRegularHoursModel? currentWorkingDay =
            operationDays.storeRegularHours?.firstWhereOrNull(
          (final _) => _.day == now.weekday,
        );

        final List<StoreOperationDaysStoreRegularHoursModel>?
            sortedWorkingDays = operationDays.storeRegularHours?.toList()
              ?..sort(
                (final _, final __) => ((_.day ?? -1) > now.weekday ? -1 : 1)
                    .compareTo((__.day ?? -1) > now.weekday ? -1 : 1),
              );
        final StoreOperationDaysStoreRegularHoursModel? nextOpenDay =
            sortedWorkingDays?.firstOrNull;

        final String? openTime = currentWorkingDay?.openTime != null
            ? getTime(currentWorkingDay!.openTime!)
            : null;
        final String? closeTime = currentWorkingDay?.closeTime != null
            ? getTime(currentWorkingDay!.closeTime!)
            : null;
        final DateTime openNow = fromHours(now, openTime);
        final DateTime closeNow = fromHours(now, closeTime);
        return now.isBefore(openNow)
            ? $.store.info.openAt(openTime ?? '00:00')
            : now.isBefore(closeNow)
                ? $.store.info.openUntil(
                    closeTime ?? '00:00',
                  )
                : $.store.info.openAtDay(
                    getWeekDayName(nextOpenDay?.day ?? now.weekday),
                    openTime ?? '00:00',
                  );
      },
      <Object?>[$.store.info, operationDays],
    );

    final Iterable<Iterable<StoreOperationDaysStoreRegularHoursModel>>
        currentDays = useMemoized(
      () {
        final List<List<StoreOperationDaysStoreRegularHoursModel>> currentDays =
            <List<StoreOperationDaysStoreRegularHoursModel>>[];
        final Iterable<StoreOperationDaysStoreRegularHoursModel> workingDays =
            (operationDays.storeRegularHours?.toList()
                  ?..sort((final _, final __) {
                    int value;
                    final int aGreater = _.day! > 0 ? -1 : 1;
                    final int bGreater = __.day! > 0 ? -1 : 1;
                    if ((value = aGreater.compareTo(bGreater)) != 0) {
                      return value;
                    }
                    return _.day!.compareTo(__.day!);
                  })) ??
                <StoreOperationDaysStoreRegularHoursModel>[];
        for (final StoreOperationDaysStoreRegularHoursModel day
            in workingDays) {
          if (day.day != null) {
            final String? openTime =
                day.openTime != null ? getTime(day.openTime!) : null;
            final String? closeTime =
                day.closeTime != null ? getTime(day.closeTime!) : null;
            final List<StoreOperationDaysStoreRegularHoursModel>
                localCurrentDays = <StoreOperationDaysStoreRegularHoursModel>[];
            for (final StoreOperationDaysStoreRegularHoursModel $day
                in workingDays) {
              final String? $openTime =
                  $day.openTime != null ? getTime($day.openTime!) : null;
              final String? $closeTime =
                  $day.closeTime != null ? getTime($day.closeTime!) : null;
              if ($openTime == openTime &&
                  $closeTime == closeTime &&
                  !currentDays.any((final _) => _.contains(day))) {
                localCurrentDays.add($day);
              }
            }
            if (localCurrentDays.isNotEmpty) {
              currentDays.add(localCurrentDays);
            }
          }
        }
        return currentDays;
      },
      <Object?>[operationDays],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Flexible(
          child: Text(
            currentTime,
            style: theme.textTheme.bodyLarge,
            maxLines: 1,
          ),
        ),
        if (extended)
          ...<Widget>[
            const SizedBox(height: 16),
            for (final Iterable<StoreOperationDaysStoreRegularHoursModel> days
                in currentDays) ...<Widget>[
              Flexible(
                child: Text(
                  <String>[
                    <String>[
                      getWeekDayName(days.first.day ?? 1),
                      if (days.length > 1)
                        getWeekDayName(
                          days.last.day ??
                              ((days.first.day ?? 1) + days.length - 1),
                        )
                    ].join(days.length == 2 ? ', ' : ' - '),
                    <String>[
                      if (days.first.openTime != null)
                        getTime(days.first.openTime!),
                      if (days.first.closeTime != null)
                        getTime(days.first.closeTime!)
                    ].join(' - ')
                  ].join(', '),
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
            ]
          ]..removeLast(),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(
            DiagnosticsProperty<StoreOperationDaysModel>(
              'operationDays',
              operationDays,
            ),
          )
          ..add(DiagnosticsProperty<bool>('extended', extended)),
      );
}

/// The screen used to notify about invalid store on [StoreScreen].
@immutable
class StoreInformationInvalidScreen extends HookConsumerWidget {
  /// The screen used to notify about invalid store on [StoreScreen].
  const StoreInformationInvalidScreen(this.store, {super.key});

  /// The store to show this screen for.
  final StoreModel store;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final SyncCallback syncCallback = useSyncCallback();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// Title / Clear
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              $.alert.storeInformationInvalid.title,
                              style: theme.textTheme.displaySmall,
                              textAlign: TextAlign.start,
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              fixedSize: const Size.square(30),
                              foregroundColor: theme.colorScheme.outline,
                              padding: const EdgeInsets.all(6),
                              shape: const CircleBorder(),
                            ),
                            icon: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Icon(icons.cross, size: 16),
                            ),
                            onPressed: () async =>
                                syncCallback(navigator.maybePop),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),

                      /// Body
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          $.alert.storeInformationInvalid.body,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 5,
                          textAlign: TextAlign.start,
                        ),
                      ),

                      /// Approve
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.surface,
                            minimumSize: const Size.fromHeight(0),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            textStyle: theme.textTheme.titleSmall,
                          ),
                          onPressed: () async =>
                              syncCallback(navigator.maybePop),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child:
                                Text($.alert.storeInformationInvalid.approve),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties..add(DiagnosticsProperty<StoreModel>('store', store)),
      );
}
