import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// The [Provider] of the current user's [LatLng].
final StreamProvider<LatLng> latLngProvider = StreamProvider<LatLng>(
  (final StreamProviderRef<LatLng> ref) => GeolocatorPlatform.instance
      .getPositionStream(
        locationSettings: const LocationSettings(
          timeLimit: Duration(minutes: 1),
        ),
      )
      .handleError(
        (final Object error, final StackTrace stackTrace) => log(
          error.toString(),
          stackTrace: stackTrace,
          error: error,
        ),
        test: (final Object? error) =>
            error is! PermissionDeniedException &&
            error is! LocationServiceDisabledException,
      )
      .map(
        (final Position position) =>
            LatLng(position.latitude, position.longitude),
      ),
);

/// The [Provider] of the locations for the specified address.
final FutureProviderFamily<Iterable<LatLng>, String> locationProvider =
    FutureProvider.family<Iterable<LatLng>, String>(
  (final FutureProviderRef<Iterable<LatLng>> ref, final String address) async =>
      (await locationFromAddress(address, localeIdentifier: 'en_US'))
          .map((final _) => LatLng(_.latitude, _.longitude)),
);

/// The [Provider] of the placemarks for the specified [LatLng].
final FutureProviderFamily<Iterable<Placemark>, LatLng> placemarksProvider =
    FutureProvider.family<Iterable<Placemark>, LatLng>(
  (final FutureProviderRef<Iterable<Placemark>> ref, final LatLng latLng) =>
      placemarkFromCoordinates(
    latLng.latitude,
    latLng.longitude,
    localeIdentifier: 'en_US',
  ),
);
