class Contact {
  final int id;
  final String name;
  final String phone;

  const Contact({required this.id, required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        phone: j['phone'] as String,
      );
}

class EmergencyLog {
  final int id;
  final int timestamp; // DateTime.now().millisecondsSinceEpoch
  final double? lat;
  final double? lng;

  const EmergencyLog({
    required this.id,
    required this.timestamp,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'timestamp': timestamp, 'lat': lat, 'lng': lng};

  factory EmergencyLog.fromJson(Map<String, dynamic> j) => EmergencyLog(
        id: (j['id'] as num).toInt(),
        timestamp: (j['timestamp'] as num).toInt(),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );
}

class FireStation {
  final String name;
  final String phone;
  final double lat;
  final double lng;
  final double? distanceKm;

  const FireStation({
    required this.name,
    required this.phone,
    required this.lat,
    required this.lng,
    this.distanceKm,
  });

  FireStation copyWith({double? distanceKm}) => FireStation(
        name: name,
        phone: phone,
        lat: lat,
        lng: lng,
        distanceKm: distanceKm ?? this.distanceKm,
      );
}

// ⚠️ ข้อมูลตัวอย่างเพื่อสาธิตเท่านั้น — ให้แก้พิกัด/เบอร์โทรเป็นข้อมูลจริงของพื้นที่ที่ใช้งาน
// ก่อนปล่อยแอปจริง (หาได้จากเว็บสำนักป้องกันและบรรเทาสาธารณภัยของแต่ละพื้นที่)
const List<FireStation> mockFireStations = [
  FireStation(name: 'สถานีดับเพลิงตัวอย่าง 1', phone: '021110001', lat: 13.7563, lng: 100.5018),
  FireStation(name: 'สถานีดับเพลิงตัวอย่าง 2', phone: '021110002', lat: 13.7367, lng: 100.5231),
  FireStation(name: 'สถานีดับเพลิงตัวอย่าง 3', phone: '021110003', lat: 13.7734, lng: 100.5606),
  FireStation(name: 'สถานีดับเพลิงตัวอย่าง 4', phone: '021110004', lat: 13.7267, lng: 100.5340),
];
