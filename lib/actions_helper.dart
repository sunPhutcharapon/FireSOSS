import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

String _cleanPhone(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

const _directCallChannel = MethodChannel('com.example.kuyyai/direct_call');

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> _launch(Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
  try {
    return await launchUrl(uri, mode: mode);
  } catch (_) {
    return false;
  }
}

/// โทรออกตรงไปยังเบอร์ฉุกเฉินทันทีโดยไม่ต้องเปิดหน้าแป้นพิมพ์
Future<void> callNumber(BuildContext context, String number) async {
  final clean = _cleanPhone(number);
  if (clean.isEmpty) return;

  try {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }
  } catch (_) {}

  try {
    // โทรออกโดยตรงทันทีโดยใช้ Native Android Intent (ACTION_CALL)
    final bool? directOk = await _directCallChannel.invokeMethod('makeDirectCall', {'phone': clean});
    if (directOk == true) return;
  } catch (_) {}

  // หากโทรตรงไม่ได้ ให้สำรองเป็นเปิดหน้าโทรศัพท์พร้อมกรอกเบอร์ให้อัตโนมัติ
  final uri = Uri(scheme: 'tel', path: clean);
  final ok = await _launch(uri);
  if (!ok && context.mounted) {
    showMessage(context, 'ไม่สามารถเปิดระบบโทรศัพท์ได้');
  }
}

/// เปิดแอป SMS พร้อมเบอร์และข้อความที่กรอกไว้แล้ว (กดส่งอีก 1 ครั้ง)
Future<void> composeSms(BuildContext context, String phone, String body) async {
  final uri = Uri(
    scheme: 'sms',
    path: _cleanPhone(phone),
    query: 'body=${Uri.encodeComponent(body)}',
  );
  final ok = await _launch(uri);
  if (!ok && context.mounted) {
    showMessage(context, 'ไม่สามารถเปิดแอป SMS ได้');
  }
}

/// เปิด Google Maps เพื่อดูสถานีดับเพลิงใกล้เคียง
Future<void> openFireStationsInMaps(BuildContext context, {double? lat, double? lng}) async {
  final Uri uri;
  if (lat != null && lng != null) {
    uri = Uri.parse('https://www.google.com/maps/search/สถานีดับเพลิง/@$lat,$lng,14z');
  } else {
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=สถานีดับเพลิง');
  }
  final ok = await _launch(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    showMessage(context, 'ไม่สามารถเปิด Google Maps ได้');
  }
}
