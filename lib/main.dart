import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // untuk menampilkan alamat

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tugas 2 - Jarak Real-time ke PNB',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  Position? _currentPosition;
  String? _currentAddress;
  String? _errorMessage;

  StreamSubscription<Position>? _positionStream;

  //[Langkah 1] Buat variabel untuk menyimpan jarak ke PNB
  String? _distanceToPNB;

  //Koordinat tetap (contoh: Politeknik Negeri Bali)
  final double _pnbLatitude = -8.7995;
  final double _pnbLongitude = 115.1767;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  //Fungsi untuk meminta izin dan mengambil lokasi
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
      return Future.error('Izin lokasi ditolak permanen. Ubah di pengaturan.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  //Mendapatkan alamat dari koordinat
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal mendapatkan alamat: $e";
      });
    }
  }

  //Tombol untuk mendapatkan lokasi sekarang
  void _handleGetLocation() async {
    try {
      Position position = await _getPermissionAndLocation();
      setState(() {
        _currentPosition = position;
        _errorMessage = null;
      });
      await _getAddressFromLatLng(position);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  //[Langkah 2 & 3] Fungsi untuk mulai tracking real-time
  
  void _handleStartTracking() {
    _positionStream?.cancel();

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update jika berpindah 5 meter
    );

    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) async {
        //Inilah bagian kode yang kamu kirim (LETTAKNYA DI SINI)
        double distanceInMeters = Geolocator.distanceBetween(
          _pnbLatitude,
          _pnbLongitude,
          position.latitude, // position dari stream
          position.longitude,
        );

        setState(() {
          _currentPosition = position;
          _distanceToPNB = "Jarak dari PNB: ${distanceInMeters.toStringAsFixed(2)} m";
          _errorMessage = null;
        });

        //Akhir potongan kode dari kamu

        await _getAddressFromLatLng(position);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  //Tombol untuk berhenti melacak
  void _handleStopTracking() {
    _positionStream?.cancel();
    setState(() {
      _errorMessage = "Pelacakan dihentikan.";
    });
  }

  //[Langkah 4] Tampilkan jarak di UI agar ter-update real-time
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tugas 2 - Jarak Real-time ke PNB")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Icon(Icons.location_on, size: 60, color: Colors.blue),
              SizedBox(height: 16),

              // Pesan error
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

              // Lokasi dan alamat
              if (_currentPosition != null) ...[
                Text(
                  "Latitude: ${_currentPosition!.latitude}\nLongitude: ${_currentPosition!.longitude}",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_currentAddress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Alamat: $_currentAddress",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],

              //[Langkah 4] Tampilkan jarak real-time
              if (_distanceToPNB != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _distanceToPNB!,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              SizedBox(height: 32),

              // Tombol Aksi
              ElevatedButton.icon(
                icon: Icon(Icons.location_searching),
                label: Text("Dapatkan Lokasi Sekarang"),
                onPressed: _handleGetLocation,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 45),
                ),
              ),
              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow),
                    label: Text("Mulai Lacak"),
                    onPressed: _handleStartTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.stop),
                    label: Text("Henti Lacak"),
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
    );
  }
}
