import 'package:geocoding/geocoding.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

import '../generated/models.g.dart';
import '../providers/misc.dart';

part 'address.g.dart';

/// The address the user has entered.
@collection
class Address {
  /// The id of this address.
  Id id = Isar.autoIncrement;

  /// The `street_number` property of this [Address].
  String? streetNumber;

  /// The `route` property of this [Address].
  String? route;

  /// The `internal` property of this [Address].
  String? internal;

  /// The `postal_code` property of this [Address].
  String? postalCode;

  /// The `memo` property of this [Address].
  String? memo;

  /// The number of the apartment.
  String? apartment;

  /// region name
  String? region;

  /// Neighborhood name
  String? neighborhood;

  /// city name
  String? city;

  /// The `default_address` property of this [Address].
  bool defaultAddress = false;

  /// The `state` property of this [Address].
  AddressState? state;

  /// The `country` property of this [Address].
  AddressCountry? country;

  /// Address longitude
  double? longtitude;

  /// Address latitude
  double? latitude;

  /// Convert this address to [UserAddressesModel].
  UserAddressesModel convert() => UserAddressesModel(
        addressId: id,
        streetNumber: streetNumber,
        route: route,
        internal: internal,
        postalCode: postalCode,
        memo: memo,
        apartment: apartment,
        region: region,
        neighborhood: neighborhood,
        city: city,
        defaultAddress: defaultAddress,
        state: state?.convert(),
        country: country?.convert(),
        lng: longtitude,
        lat: latitude,
        displayShort: <String?>[
          <String?>[streetNumber, route]
              .whereType<String>()
              .map((final _) => _.trim())
              .where((final _) => _.isNotEmpty)
              .join(' '),
          city,
          state?.longName
        ]
            .whereType<String>()
            .map((final _) => _.trim())
            .where((final _) => _.isNotEmpty)
            .join(', '),
        displayLong: <String?>[
          <String?>[streetNumber, route]
              .whereType<String>()
              .map((final _) => _.trim())
              .where((final _) => _.isNotEmpty)
              .join(' '),
          city,
          state?.longName,
          <String?>[state?.shortName, postalCode]
              .whereType<String>()
              .map((final _) => _.trim())
              .where((final _) => _.isNotEmpty)
              .join(' ')
        ]
            .whereType<String>()
            .map((final _) => _.trim())
            .where((final _) => _.isNotEmpty)
            .join(', '),
      );
}

/// The state of the [Address].
@embedded
class AddressState {
  /// Short state name
  String? shortName;

  /// Long state name
  String? longName;

  /// Convert this state to [UserAddressesStateModel].
  UserAddressesStateModel convert() => UserAddressesStateModel(
        shortName: shortName,
        longName: longName,
      );
}

/// The state of the [Address].
@embedded
class AddressCountry {
  /// Short country name
  String? shortName;

  /// Long country name
  String? longName;

  /// Convert this country to [UserAddressesCountryModel].
  UserAddressesCountryModel convert() => UserAddressesCountryModel(
        shortName: shortName,
        longName: longName,
      );
}

/// The provider of the user addresses.
final StreamProvider<Iterable<UserAddressesModel>> isarAddressesProvider =
    StreamProvider<Iterable<UserAddressesModel>>(
        (final StreamProviderRef<Iterable<UserAddressesModel>> ref) async* {
  final Isar isar = await ref.watch(isarProvider.future);
  yield* isar.address
      .where()
      .limit(5)
      .watch(fireImmediately: true)
      .map((final _) => _.map((final _) => _.convert()));
});

/// Extension used to convert [Placemark] to [Address].
extension PlacemarkConvert on Placemark {
  /// Convert this placemark to [Address].
  Address convert() {
    final String streetNumber = subThoroughfare?.replaceAll(r'\D', '') ?? '';
    final String route = thoroughfare?.trim() ?? '';
    final String city = locality?.trim() ?? '';
    final String neighborhood = subAdministrativeArea?.trim() ?? '';
    final String postalCode = this.postalCode?.replaceAll(r'\D', '') ?? '';
    final String stateLongName = administrativeArea?.trim() ?? '';
    final String countryShortName = isoCountryCode?.trim() ?? '';
    final String countryLongName = country?.trim() ?? '';
    return Address()
      ..streetNumber = streetNumber.isNotEmpty ? streetNumber : null
      ..route = route.isNotEmpty ? route : null
      ..city = city.isNotEmpty ? city : null
      ..neighborhood = neighborhood.isNotEmpty ? neighborhood : null
      ..postalCode = postalCode.isNotEmpty ? postalCode : null
      ..state = (AddressState()
        ..longName = stateLongName.isNotEmpty ? stateLongName : null)
      ..country = (AddressCountry()
        ..shortName = countryShortName.isNotEmpty ? countryShortName : null
        ..longName = countryLongName.isNotEmpty ? countryLongName : null);
  }
}

/// Extension used to convert [UserAddressesModel] to [Address].
extension AddressConvert on UserAddressesModel {
  /// Convert this address to [Address].
  Address convert() => Address()
    ..id = addressId ?? Isar.autoIncrement
    ..streetNumber = streetNumber
    ..route = route
    ..internal = internal
    ..postalCode = postalCode
    ..memo = memo
    ..apartment = apartment
    ..region = region
    ..neighborhood = neighborhood
    ..city = city
    ..defaultAddress = defaultAddress ?? Address().defaultAddress
    ..state = state?.convert()
    ..country = country?.convert()
    ..longtitude = lng
    ..latitude = lat;
}

/// Extension used to convert [UserAddressesStateModel] to [AddressState].
extension AddressStateConvert on UserAddressesStateModel {
  /// Convert this state to [AddressState].
  AddressState convert() => AddressState()
    ..shortName = shortName
    ..longName = longName;
}

/// Extension used to convert [UserAddressesCountryModel] to [AddressCountry].
extension AddressCountryConvert on UserAddressesCountryModel {
  /// Convert this country to [AddressCountry].
  AddressCountry convert() => AddressCountry()
    ..shortName = shortName
    ..longName = longName;
}
