import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:latlong2/latlong.dart';

import '../../const.dart';
import '../../generated/i18n.g.dart';
import '../../generated/icons.g.dart';
import '../../generated/models.g.dart';
import '../../hooks/sync_callback_hook.dart';
import '../../hooks/widget_state_hook.dart';
import '../../models/address.dart';
import '../../models/settings.dart';
import '../../providers/api.dart';
import '../../providers/location.dart';
import '../../providers/misc.dart';
import '../../routes.dart';
import '../modal/address.dart';

/// The screen used to select an address on map.
@immutable
class MapScreen extends HookConsumerWidget {
  /// The screen used to select an address on map.
  const MapScreen({this.initialAddress, super.key});

  /// The initial location to show on map.
  final UserAddressesModel? initialAddress;

  /// The default location to show on map.
  static final LatLng defaultLatLng = LatLng(40.730610, -73.935242);

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final I18N $ = I18NLocalizations.of(context);
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);

    final IsMounted isMounted = useIsMounted();
    final SyncCallback syncCallback = useSyncCallback();
    final bool addressValid =
        initialAddress?.lat != null && initialAddress?.lng != null;
    final TextEditingController addressController = useTextEditingController(
      text: addressValid
          ? initialAddress?.displayLong ?? initialAddress?.displayShort
          : null,
    );
    final ValueNotifier<LatLng?> customLatLng = useState<LatLng?>(
      addressValid ? LatLng(initialAddress!.lat!, initialAddress!.lng!) : null,
    );
    final MapController controller = useMemoized(MapController.new);
    useWidgetState(dispose: controller.dispose);

    final ObjectRef<Tween<double>?> latitudeTween =
        useRef<Tween<double>?>(null);
    final ObjectRef<Tween<double>?> longtitudeTween =
        useRef<Tween<double>?>(null);
    final ObjectRef<Tween<double>?> zoomTween = useRef<Tween<double>?>(null);
    final AnimationController mapAnimationController =
        useAnimationController(duration: const Duration(milliseconds: 750));
    useMemoized(
      () => mapAnimationController.addListener(() {
        final Tween<double>? latitude = latitudeTween.value;
        final Tween<double>? longtitude = longtitudeTween.value;
        final Tween<double>? zoom = zoomTween.value;
        if (latitude != null && longtitude != null && zoom != null) {
          final Animation<double> animation = CurvedAnimation(
            parent: mapAnimationController,
            curve: Curves.fastOutSlowIn,
          );
          controller.move(
            LatLng(
              latitude.evaluate(animation),
              longtitude.evaluate(animation),
            ),
            zoom.evaluate(animation),
          );
        }
      }),
    );

    Future<void> animateTo(
      final LatLng latLng, {
      final double zoom = 14,
      final bool isLowerZoomNeutral = true,
    }) async {
      latitudeTween.value = Tween<double>(
        begin: controller.center.latitude,
        end: latLng.latitude,
      );
      longtitudeTween.value = Tween<double>(
        begin: controller.center.longitude,
        end: latLng.longitude,
      );
      double $zoom = isLowerZoomNeutral ? controller.zoom : zoom;
      if (isLowerZoomNeutral) {
        $zoom = $zoom.clamp(zoom, $zoom < zoom ? zoom : $zoom);
      }

      zoomTween.value = Tween<double>(begin: controller.zoom, end: $zoom);
      try {
        mapAnimationController.reset();
        return await mapAnimationController.forward();
      } finally {
        latitudeTween.value = longtitudeTween.value = zoomTween.value = null;
      }
    }

    final StreamController<LatLng> animateStream =
        useMemoized(StreamController<LatLng>.broadcast);
    late final StreamSubscription<LatLng> animateStreamSubscription;
    animateStreamSubscription = useMemoized(
      () => animateStream.stream.listen(
        (final LatLng latLng) async {
          animateStreamSubscription.pause();
          await Future.wait(<Future<void>>[
            (ref.read(placemarksProvider(latLng).future)).then(
              (final Iterable<Placemark> placemarks) async {
                final UserAddressesModel? address =
                    placemarks.firstOrNull?.convert().convert();
                if (address?.state?.shortName?.isEmpty ?? true) {
                  await navigator.pushNamed(
                    Routes.mapLocationInvalid.name,
                    arguments: MapLocationInvalidScreen(address),
                  );

                  if (customLatLng.value != null) {
                    animateStream.add(customLatLng.value!);
                  }
                } else {
                  customLatLng.value = latLng;
                  addressController.text = address?.displayLong ?? '';
                }
              },
            ),
            animateTo(latLng),
          ]).then((final _) => animateStreamSubscription.resume());
        },
      ),
    );

    /// * If location permission is not granted, request the permission.
    /// * If location services are disabled, request to enable the services.
    Future<LatLng?> getCurrentLocation() async {
      try {
        return await ref.read(latLngProvider.future);
      } on PermissionDeniedException catch (_, __) {
        final LocationPermission permission =
            await Geolocator.requestPermission();
        if (!isMounted()) {
          return null;
        } else if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.unableToDetermine) {
          await navigator.pushNamed(Routes.mapLocationDenied.name);
        }
      } on LocationServiceDisabledException catch (_, __) {
        await navigator.pushNamed(Routes.mapLocationDisabled.name);
      }
      if (isMounted()) {
        final LocationPermission permission =
            await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          return await ref.refresh(latLngProvider.future);
        }
      }
      return null;
    }

    useMemoized(
      () => !addressValid ||
              ((initialAddress?.displayLong ?? initialAddress?.displayShort)
                      ?.isEmpty ??
                  true)
          ? WidgetsBinding.instance.addPostFrameCallback((final _) async {
              if (addressValid) {
                animateStream.add(customLatLng.value!);
              } else {
                animateStream.add(defaultLatLng);
                final LatLng? currentLocation = await getCurrentLocation();
                if (currentLocation != null) {
                  animateStream.add(currentLocation);
                }
              }
            })
          : null,
    );
    return WillPopScope(
      onWillPop: () async {
        if (!addressValid) {
          await syncCallback(() async {
            final Settings settings = await ref.read(settingsProvider.future);
            if (!settings.skippedDefaultAddress &&
                await ref.read(currentAddressProvider.future) == null) {
              final Isar isar = await ref.read(isarProvider.future);
              await isar.writeTxn(
                () => isar.settings.put(settings..skippedDefaultAddress = true),
              );
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
          });
        }
        try {
          if (navigator.canPop()) {
            return true;
          }
          WidgetsBinding.instance.addPostFrameCallback(
            (final _) async => navigator
                .pushReplacementNamed((await Routes.current(container)).name),
          );
          return false;
        } finally {
          await animateStreamSubscription.cancel();
          await animateStream.close();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: theme.colorScheme.surface,
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: theme.colorScheme.surface,
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            leadingWidth: double.infinity,
            leading: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: TextButton(
                  onPressed: () async => syncCallback(navigator.maybePop),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(icons.misc.arrowLeft, size: 14),
                        const SizedBox(width: 12),
                        Flexible(child: Text($.map.back))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AutoSizeText(
                  $.map.title,
                  style: theme.textTheme.displayMedium,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                    keepAlive: true,
                    zoom: 14,
                    maxZoom: 18,
                    minZoom: 3.5,
                    center: customLatLng.value ?? defaultLatLng,
                    interactiveFlags:
                        InteractiveFlag.all & ~InteractiveFlag.rotate,
                    onTap: (final _, final LatLng latLng) =>
                        animateStream.add(latLng),

                    /// USA Bounds
                    maxBounds: LatLngBounds(
                      LatLng(49.382808, -124.736342),
                      LatLng(24.521208, -66.945392),
                    ),
                  ),
                  children: <Widget>[
                    TileLayer(urlTemplate: mapTileUrl, minZoom: 4),

                    /// Location
                    Consumer(
                      builder:
                          (final _, final WidgetRef ref, final Widget? child) {
                        final LatLng? latLng = customLatLng.value ??
                            ref.watch(
                              latLngProvider.select((final _) => _.valueOrNull),
                            );
                        return MarkerLayer(
                          markers: <Marker>[
                            if (latLng != null)
                              Marker(
                                point: latLng,
                                rotate: false,
                                builder: (final _) => Icon(
                                  icons.location,
                                  color: theme.colorScheme.primary,
                                  size: 40,
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    /// Action Buttons
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: IconButton(
                          iconSize: 28,
                          icon: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              icons.location,
                              color: theme.colorScheme.surface,
                            ),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () async => syncCallback(() async {
                            customLatLng.value = null;
                            final LatLng? currentLocation =
                                await getCurrentLocation();
                            if (currentLocation != null) {
                              animateStream.add(currentLocation);
                            }
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  readOnly: true,
                  controller: addressController,
                  decoration: InputDecoration(hintText: $.map.hint),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(top: 24, bottom: mediaQuery.padding.bottom + 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(0),
                  ),
                  onPressed: () async => syncCallback(() async {
                    final LatLng latLng = customLatLng.value ??
                        await ref.read(latLngProvider.future);
                    final Iterable<Placemark> placemarks =
                        await ref.read(placemarksProvider(latLng).future);
                    if (placemarks.isEmpty) {
                      await navigator.pushNamed(
                        Routes.mapLocationInvalid.name,
                        arguments: const MapLocationInvalidScreen(null),
                      );
                    } else {
                      UserAddressesModel address = (placemarks.first.convert()
                            ..latitude = latLng.latitude
                            ..longtitude = latLng.longitude)
                          .convert();
                      address = address.copyWith(
                        addressId: initialAddress?.addressId,
                        userAddressId: initialAddress?.userAddressId,
                        memo: initialAddress?.memo,
                        internal: initialAddress?.internal,
                        defaultAddress: initialAddress?.defaultAddress,
                        city: address.city ?? 'undefined',
                        region: address.region ?? 'undefined',
                      );
                      if (addressValid) {
                        await navigator.maybePop(address);
                      } else {
                        await navigator.pushNamed(
                          Routes.address.name,
                          arguments: AddressScreen(address),
                        );
                      }
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text($.map.confirm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(
        properties
          ..add(
            DiagnosticsProperty<UserAddressesModel?>(
              'initialAddress',
              initialAddress,
            ),
          ),
      );
}

/// The screen used to notify user about denied location on [MapScreen].
@immutable
class MapLocationDeniedScreen extends HookConsumerWidget {
  /// The screen used to notify user about denied location on [MapScreen].
  const MapLocationDeniedScreen({super.key});

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
                              $.alert.locationDenied.title,
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
                          $.alert.locationDenied.body,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 5,
                          textAlign: TextAlign.start,
                        ),
                      ),

                      /// Actions
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: <Widget>[
                            /// Deny
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.shadow,
                                  backgroundColor: theme.colorScheme.surface,
                                  minimumSize: const Size.fromHeight(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
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
                                  child: Text($.alert.locationDenied.deny),
                                ),
                              ),
                            ),

                            /// Approve
                            const SizedBox(width: 24),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.surface,
                                  minimumSize: const Size.fromHeight(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  textStyle: theme.textTheme.titleSmall,
                                ),
                                onPressed: () async => syncCallback(() async {
                                  if (await Geolocator.openAppSettings()) {
                                    await navigator.maybePop();
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text($.alert.locationDenied.approve),
                                ),
                              ),
                            ),
                          ],
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
}

/// The screen used to notify user about disabled location on [MapScreen].
@immutable
class MapLocationDisabledScreen extends HookConsumerWidget {
  /// The screen used to notify user about disabled location on [MapScreen].
  const MapLocationDisabledScreen({super.key});

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
                              $.alert.locationDisabled.title,
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
                          $.alert.locationDisabled.body,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 5,
                          textAlign: TextAlign.start,
                        ),
                      ),

                      /// Actions
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: <Widget>[
                            /// Deny
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.shadow,
                                  backgroundColor: theme.colorScheme.surface,
                                  minimumSize: const Size.fromHeight(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
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
                                  child: Text($.alert.locationDisabled.deny),
                                ),
                              ),
                            ),

                            /// Approve
                            const SizedBox(width: 24),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.surface,
                                  minimumSize: const Size.fromHeight(0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  textStyle: theme.textTheme.titleSmall,
                                ),
                                onPressed: () async => syncCallback(() async {
                                  if (await Geolocator.openLocationSettings()) {
                                    await navigator.maybePop();
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text($.alert.locationDisabled.approve),
                                ),
                              ),
                            ),
                          ],
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
}

/// The screen used to notify user abount an invalid location on [MapScreen].
@immutable
class MapLocationInvalidScreen extends HookConsumerWidget {
  /// The screen used to notify user abount an invalid location on [MapScreen].
  const MapLocationInvalidScreen(this.address, {super.key});

  /// The location marked as invalid to show on this screen.
  final UserAddressesModel? address;

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
                              $.alert.locationInvalid.title,
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
                          $.alert.locationInvalid.body,
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
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
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
                            child: Text($.alert.locationInvalid.approve),
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
        properties
          ..add(DiagnosticsProperty<UserAddressesModel?>('address', address)),
      );
}
