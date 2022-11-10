import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flash/flash.dart';
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
import '../../hooks/sync_callback_hook.dart';
import '../../hooks/widget_state_hook.dart';
import '../../models/address.dart';
import '../../models/settings.dart';
import '../../providers/api.dart';
import '../../providers/location.dart';
import '../../providers/misc.dart';
import '../../routes.dart';

/// The screen used to select an address on map.
@immutable
class MapScreen extends HookConsumerWidget {
  /// The screen used to select an address on map.
  const MapScreen({super.key});

  /// The default location to show on map.
  static final LatLng defaultLocation = LatLng(43, 75);

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
    final TextEditingController addressController = useTextEditingController();
    final ValueNotifier<LatLng?> customLatLng = useState<LatLng?>(null);
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

    final StreamController<LatLng> animateStream = useMemoized(
      () => StreamController<LatLng>.broadcast()
        ..stream.listen(
          (final LatLng latLng) async => Future.wait(<Future<Object?>>[
            (ref.read(placemarksProvider(latLng).future)).then(
              (final Iterable<Placemark> placemarks) => addressController.text =
                  placemarks.firstOrNull?.convert().convert().displayLong ?? '',
            ),
            animateTo(latLng),
          ]),
        ),
    );
    useWidgetState(dispose: animateStream.close);

    /// * If location permission is not granted, request the permission.
    /// * If location services are disabled, request to enable the services.
    Future<LatLng?> getCurrentLocation() async {
      try {
        return await ref.read(latLngProvider.future);
      } on PermissionDeniedException catch (_) {
        final LocationPermission permission =
            await Geolocator.requestPermission();
        if (!isMounted()) {
          return null;
        } else if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.unableToDetermine) {
          // ignore: use_build_context_synchronously
          await context.showFlashDialog(
            title: Text($.alert.locationDenied.title),
            content: Text($.alert.locationDenied.body),
            negativeActionBuilder: (
              final _,
              final FlashController<void> controller,
              final __,
            ) =>
                TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.all(12)),
              onPressed: controller.dismiss,
              child: Text(
                $.alert.locationDenied.deny,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            positiveActionBuilder: (
              final _,
              final FlashController<void> controller,
              final __,
            ) =>
                TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.all(12)),
              onPressed: () async => await Geolocator.openAppSettings()
                  ? await controller.dismiss()
                  : null,
              child: Text(
                $.alert.locationDenied.approve,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }
      } on LocationServiceDisabledException catch (_) {
        if (!isMounted()) {
          return null;
        }
        // ignore: use_build_context_synchronously
        await context.showFlashDialog(
          title: Text($.alert.locationDisabled.title),
          content: Text($.alert.locationDisabled.body),
          negativeActionBuilder: (
            final _,
            final FlashController<void> controller,
            final __,
          ) =>
              TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.all(12)),
            onPressed: () async => await Geolocator.openLocationSettings()
                ? await controller.dismiss()
                : null,
            child: Text(
              $.alert.locationDisabled.approve,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          positiveActionBuilder: (
            final _,
            final FlashController<void> controller,
            final __,
          ) =>
              TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.all(12)),
            onPressed: controller.dismiss,
            child: Text(
              $.alert.locationDisabled.deny,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
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
      () => WidgetsBinding.instance.addPostFrameCallback((final _) async {
        final LatLng? currentLocation = await getCurrentLocation();
        if (currentLocation != null) {
          animateStream.add(currentLocation);
        }
      }),
    );
    return WillPopScope(
      onWillPop: () async {
        if (navigator.canPop()) {
          return true;
        }
        WidgetsBinding.instance.addPostFrameCallback(
          (final _) => syncCallback(() async {
            final Settings settings = await ref.read(settingsProvider.future);
            if (!settings.skippedDefaultAddress &&
                await ref.read(activeAddressProvider.future) == null) {
              final Isar isar = await ref.read(isarProvider.future);
              await isar.writeTxn(
                () async =>
                    isar.settings.put(settings..skippedDefaultAddress = true),
              );
              await Future<void>.delayed(const Duration(milliseconds: 100));
            }
            await navigator.pushReplacementNamed(
              (await Routes.current(container)).name,
            );
          }),
        );
        return false;
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
                    center: defaultLocation,
                    interactiveFlags:
                        InteractiveFlag.all & ~InteractiveFlag.rotate,
                    onTap: (final _, final LatLng latLng) async =>
                        animateStream.add(customLatLng.value = latLng),
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
                      if (!isMounted()) {
                        return;
                      }
                      // ignore: use_build_context_synchronously
                      return context.showFlashDialog(
                        title: Text($.alert.locationInvalid.title),
                        content: Text($.alert.locationInvalid.body),
                        positiveActionBuilder: (
                          final _,
                          final FlashController<void> controller,
                          final __,
                        ) =>
                            TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: controller.dismiss,
                          child: Text(
                            $.alert.locationInvalid.approve,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }

                    final Placemark placemark = placemarks.first;
                    if (await ref.read(skippedAuthorizationProvider.future)) {
                      final Isar isar = await ref.read(isarProvider.future);
                      await isar.writeTxn(
                        () async => isar.address.put(
                          placemark.convert()
                            ..latitude = latLng.latitude
                            ..longtitude = latLng.longitude
                            ..defaultAddress = await isar.address.count() == 0,
                        ),
                      );
                    }
                    await navigator.maybePop();
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
}
