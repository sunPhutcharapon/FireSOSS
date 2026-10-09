import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// เก็บผู้ติดต่อฉุกเฉิน + ประวัติแจ้งเหตุในเครื่อง (แทน Room ในเวอร์ชัน Kotlin)
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static const _contactsKey = 'contacts';
  static const _logsKey = 'logs';

  SharedPreferences? _prefs;
  List<Contact> _contacts = [];
  List<EmergencyLog> _logs = [];

  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<EmergencyLog> get logs => List.unmodifiable(_logs);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _contacts = _decode(prefs.getString(_contactsKey), Contact.fromJson);
      _logs = _decode(prefs.getString(_logsKey), EmergencyLog.fromJson);
      notifyListeners();
    } catch (_) {}
  }

  List<T> _decode<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveContacts() async {
    await _prefs?.setString(
        _contactsKey, jsonEncode(_contacts.map((c) => c.toJson()).toList()));
  }

  Future<void> _saveLogs() async {
    await _prefs?.setString(
        _logsKey, jsonEncode(_logs.map((l) => l.toJson()).toList()));
  }

  Future<void> addContact(String name, String phone) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    _contacts = [Contact(id: id, name: name, phone: phone), ..._contacts];
    notifyListeners();
    await _saveContacts();
  }

  Future<void> deleteContact(int id) async {
    _contacts = _contacts.where((c) => c.id != id).toList();
    notifyListeners();
    await _saveContacts();
  }

  Future<void> addLog({double? lat, double? lng}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _logs = [EmergencyLog(id: now, timestamp: now, lat: lat, lng: lng), ..._logs];
    notifyListeners();
    await _saveLogs();
  }

  Future<void> clearLogs() async {
    _logs = [];
    notifyListeners();
    await _saveLogs();
  }
}
