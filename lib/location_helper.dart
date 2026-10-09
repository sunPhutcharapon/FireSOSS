import 'package:geolocator/geolocator.dart';

/// ขอตำแหน่งปัจจุบัน คืนค่า null ถ้า GPS ปิด / ผู้ใช้ไม่อนุญาตสิทธิ์ / ขอไม่สำเร็จ
Future<Position?> getCurrentPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  } catch (_) {
    // ขอตำแหน่งสดไม่ทัน (timeout ฯลฯ) → ลองใช้ตำแหน่งล่าสุดที่เครื่องจำไว้
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}

/// ระยะทางระหว่างสองจุด หน่วยกิโลเมตร
double distanceKm(double lat1, double lng1, double lat2, double lng2) =>
    Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
