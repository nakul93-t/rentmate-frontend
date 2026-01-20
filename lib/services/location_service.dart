import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _kLocationKey = 'user_location';

  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handlePermission();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition();
  }

  Future<String?> getPlaceName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Prefer Locality (City) or SubLocality
        return place.locality ?? place.subLocality ?? place.name;
      }
    } catch (e) {
      print('Error geocoding: $e');
    }
    return null;
  }

  // Save location name
  Future<void> saveLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocationKey, location);
  }

  // Get saved location
  Future<String?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocationKey);
  }
}
