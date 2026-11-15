import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Lokasi Saya',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
      textTheme: GoogleFonts.poppinsTextTheme(),
      useMaterial3: true,
    ),
    home: const LocationScreen(),
  );
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _kecamatan;
  String? _kota;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _kecamatan = null;
      _kota = null;
      _latitude = null;
      _longitude = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Layanan lokasi tidak aktif. Mohon aktifkan GPS.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak oleh pengguna.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Ubah izin aplikasi di Pengaturan.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        throw Exception('Tidak dapat menemukan informasi alamat.');
      }
      final place = placemarks.first;
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _kecamatan = place.subLocality?.isNotEmpty == true
            ? place.subLocality
            : place.locality;
        _kota = place.subAdministrativeArea?.isNotEmpty == true
            ? place.subAdministrativeArea
            : place.locality;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Lokasi Saya', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1A237E),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_on, size: 64, color: Color(0xFF1A237E)),
            const SizedBox(height: 16),
            const Text(
              'Lokasi Perangkat',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 18,
                ),
                child: _buildCardContent(),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getLocation,
              icon: const Icon(Icons.my_location, color: Colors.white),
              label: Text(
                _isLoading
                    ? 'MENGAMBIL LOKASI...'
                    : 'TAMPILKAN LOKASI SAAT INI',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildCardContent() {
    if (_isLoading) {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Sedang mengambil lokasi perangkat...'),
        ],
      );
    }
    if (_errorMessage != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      );
    }
    if (_latitude == null || _longitude == null) {
      return const Text(
        'Tekan tombol untuk menampilkan lokasi.',
        textAlign: TextAlign.center,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _locationRow(
          Icons.place_outlined,
          'Kelurahan/Kecamatan',
          _kecamatan ?? 'Tidak tersedia',
        ),
        const SizedBox(height: 12),
        _locationRow(Icons.location_city, 'Kota', _kota ?? 'Tidak tersedia'),
        const Divider(height: 28),
        _locationRow(
          Icons.my_location,
          'Latitude',
          _latitude!.toStringAsFixed(6),
        ),
        const SizedBox(height: 8),
        _locationRow(
          Icons.my_location,
          'Longitude',
          _longitude!.toStringAsFixed(6),
        ),
      ],
    );
  }

  Widget _locationRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFF1A237E), size: 21),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}
