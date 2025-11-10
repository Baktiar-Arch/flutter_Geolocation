import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // (2) Tambahkan import geocoding
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum Geolocator (Dasar)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // --- Variabel State Utama ---
  Position? _currentPosition;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStream;

  String? currentAddress; // (3) Tambahkan variabel alamat

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<Position> _getPermissionAndLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi tidak aktif. Harap aktifkan GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Izin lokasi ditolak permanen. Harap ubah di pengaturan aplikasi.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // (4) Fungsi baru untuk mengonversi koordinat menjadi alamat
  Future<void> getAddressFromLatLng(Position position) async {
    // First try plugin-based reverse geocoding (may return partial results)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        String safe(String? s) =>
            (s == null || s.trim().isEmpty) ? "" : s.trim();
        final parts = [
          safe(place.street),
          safe(place.subLocality),
          safe(place.locality),
          safe(place.postalCode),
          safe(place.country),
        ].where((p) => p.isNotEmpty).toList();

        if (parts.isNotEmpty) {
          setState(() {
            currentAddress = parts.join(', ');
          });
          return;
        }
      }
    } catch (_) {
      // ignore and fallthrough to Nominatim
    }

    // Fallback: use Nominatim (OpenStreetMap) reverse geocoding for better results
    await getAddressFromNominatim(position);
  }

  // Call Nominatim reverse-geocoding API (no API key required, respect usage policy)
  Future<void> getAddressFromNominatim(Position position) async {
    final lat = position.latitude;
    final lon = position.longitude;
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
    );

    try {
      final resp = await http
          .get(url, headers: {'User-Agent': 'flutter_app_reverse_geocode/1.0'})
          .timeout(Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final display = data['display_name'] as String?;
        if (display != null && display.trim().isNotEmpty) {
          setState(() {
            currentAddress = display;
          });
          return;
        }

        // Try to build a structured address if display_name absent
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final parts = <String>[];
          for (final key in [
            'road',
            'suburb',
            'hamlet',
            'village',
            'town',
            'county',
            'state',
            'country',
          ]) {
            final v = addr[key];
            if (v is String && v.trim().isNotEmpty) parts.add(v.trim());
          }
          if (parts.isNotEmpty) {
            setState(() {
              currentAddress = parts.join(', ');
            });
            return;
          }
        }
      }

      // If we get here, nothing useful
      setState(() {
        currentAddress = 'Alamat tidak tersedia (lat: $lat, lng: $lon)';
      });
    } catch (e) {
      setState(() {
        currentAddress =
            'Gagal mendapatkan alamat: ${e.toString()} (lat: $lat, lng: $lon)';
      });
    }
  }

  void _handleGetLocation() async {
    try {
      Position position = await _getPermissionAndLocation();
      setState(() {
        _currentPosition = position;
        _errorMessage = null;
      });

      // (5) Panggil getAddressFromLatLng setelah posisi diperbarui
      await getAddressFromLatLng(_currentPosition!);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _handleStartTracking() {
    _positionStream?.cancel();

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    try {
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) async {
            setState(() {
              _currentPosition = position;
              _errorMessage = null;
            });

            // (5) Panggil juga di sini untuk memperbarui alamat saat posisi berubah
            await getAddressFromLatLng(position);
          });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _handleStopTracking() {
    _positionStream?.cancel();
    setState(() {
      _errorMessage = "Pelacakan dihentikan.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Praktikum Geolocator (Dasar)")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 50, color: Colors.blue),
                SizedBox(height: 16),

                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 150),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      SizedBox(height: 16),
                      if (_currentPosition != null)
                        Text(
                          "Lat: ${_currentPosition!.latitude}\nLng: ${_currentPosition!.longitude}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      // (6) Tambahkan tampilan alamat di bawah Lat/Lng
                      if (currentAddress != null) ...[
                        SizedBox(height: 8),
                        Text(
                          "Alamat: $currentAddress",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: Icon(Icons.location_searching),
                  label: Text('Dapatkan Lokasi Sekarang'),
                  onPressed: _handleGetLocation,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 40),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.play_arrow),
                      label: Text('Mulai Lacak'),
                      onPressed: _handleStartTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.stop),
                      label: Text('Henti Lacak'),
                      onPressed: _handleStopTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
