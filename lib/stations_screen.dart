import 'package:flutter/material.dart';

import 'actions_helper.dart';
import 'location_helper.dart';
import 'models.dart';
import 'places_service.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  List<FireStation> _stations = [];
  bool _loading = false;
  bool _hasSearched = false;
  double? _userLat;
  double? _userLng;

  Future<void> _findNearest() async {
    setState(() => _loading = true);
    final pos = await getCurrentPosition();
    if (!mounted) return;

    if (pos == null) {
      setState(() => _loading = false);
      showMessage(context, 'ขอตำแหน่งไม่สำเร็จ (ตรวจสอบสิทธิ์ตำแหน่ง/GPS)');
      return;
    }

    _userLat = pos.latitude;
    _userLng = pos.longitude;

    final nearestStations = await fetchNearbyFireStations(
      pos.latitude,
      pos.longitude,
    );

    if (!mounted) return;

    setState(() {
      _stations = nearestStations;
      _hasSearched = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFD32F2F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สถานีดับเพลิงใกล้ที่สุด',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'ค้นหาด้วยระบบ GPS / แผนที่ดาวเทียม',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _findNearest,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(_loading ? 'กำลังค้นหา...' : 'ค้นหาตำแหน่งฉัน'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => openFireStationsInMaps(
                  context,
                  lat: _userLat,
                  lng: _userLng,
                ),
                icon: const Icon(Icons.map_rounded, size: 18, color: Color(0xFF0284C7)),
                label: const Text('Google Maps', style: TextStyle(color: Color(0xFF0284C7))),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFFD32F2F)),
                        const SizedBox(height: 16),
                        Text(
                          'กำลังดึงข้อมูลสถานีดับเพลิงใกล้เคียง...',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.near_me_outlined,
                                size: 54,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ค้นหาสถานีดับเพลิงรอบตัวคุณ',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'กดปุ่ม "ค้นหาตำแหน่งฉัน" ด้านบน เพื่อระบุพิกัดและคำนวณระยะทางไปยังสถานีดับเพลิงใกล้ที่สุด',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _stations.isEmpty
                        ? Center(
                            child: Text(
                              'ไม่พบสถานีดับเพลิงในรัศมีใกล้เคียง',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _stations.length,
                            itemBuilder: (context, i) {
                              final s = _stations[i];
                              final hasDistance = s.distanceKm != null;
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    onTap: () => openFireStationsInMaps(
                                      context,
                                      lat: s.lat,
                                      lng: s.lng,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Color(0xFFD32F2F),
                                        size: 22,
                                      ),
                                    ),
                                    title: Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (hasDistance)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                                ),
                                                child: Text(
                                                  '${s.distanceKm!.toStringAsFixed(1)} กม.',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF047857),
                                                  ),
                                                ),
                                              ),
                                            Text(
                                              '📞 ${s.phone}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.directions_rounded, color: Color(0xFF0284C7)),
                                          tooltip: 'นำทาง / ดูแผนที่',
                                          onPressed: () => openFireStationsInMaps(
                                            context,
                                            lat: s.lat,
                                            lng: s.lng,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.phone_rounded, color: Color(0xFF047857)),
                                          tooltip: 'โทรออก',
                                          onPressed: () => callNumber(context, s.phone),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
