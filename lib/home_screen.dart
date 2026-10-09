import 'package:flutter/material.dart';

import 'actions_helper.dart';
import 'location_helper.dart';
import 'storage.dart';

const String kEmergencyNumber = '0960528206';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _status = 'ยังไม่ได้ขอตำแหน่ง';
  double? _lat;
  double? _lng;
  bool _busy = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onSosPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ยืนยันแจ้งเหตุ SOS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'ระบบจะระบุตำแหน่งปัจจุบันของคุณ บันทึกลงประวัติ และเตรียมแจ้งเหตุฉุกเฉินทันที',
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('ยืนยันแจ้งเหตุ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'กำลังค้นหาตำแหน่งพิกัด GPS...';
    });

    final pos = await getCurrentPosition();
    _lat = pos?.latitude;
    _lng = pos?.longitude;
    await AppStore.instance.addLog(lat: _lat, lng: _lng);
    if (!mounted) return;

    setState(() {
      _busy = false;
      _status = pos != null
          ? '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'
          : 'ขอตำแหน่งไม่สำเร็จ (ตรวจสอบสิทธิ์ตำแหน่ง/GPS)';
    });
    _showActionDialog();
  }

  void _showActionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'บันทึกตำแหน่งสำเร็จ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lat != null ? 'พิกัด: $_lat, $_lng' : 'ไม่สามารถดึงพิกัดได้',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('เลือกร้านหรือช่องทางแจ้งเหตุฉุกเฉินถัดไป:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _sendSms();
            },
            icon: const Icon(Icons.sms_rounded, size: 18),
            label: const Text('ส่ง SMS'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              callNumber(context, kEmergencyNumber);
            },
            icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            label: Text('โทร $kEmergencyNumber'),
          ),
        ],
      ),
    );
  }

  String _buildSosMessage() {
    final where = (_lat != null && _lng != null)
        ? 'https://maps.google.com/?q=$_lat,$_lng'
        : 'ไม่ทราบพิกัด';
    return 'เกิดเหตุไฟไหม้ ช่วยด้วย! พิกัด: $where';
  }

  Future<void> _sendSms() async {
    final contacts = AppStore.instance.contacts;
    if (contacts.isEmpty) {
      showMessage(context, 'ยังไม่มีผู้ติดต่อฉุกเฉิน กรุณาเพิ่มในหน้า "ผู้ติดต่อ"');
      return;
    }
    final msg = _buildSosMessage();
    if (contacts.length == 1) {
      await composeSms(context, contacts.first.phone, msg);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.sms_outlined, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'เลือกผู้ติดต่อที่จะส่ง SMS แจ้งเหตุ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in contacts)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: Text(
                            c.name.isNotEmpty ? c.name[0] : 'C',
                            style: const TextStyle(
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c.phone),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(ctx);
                          composeSms(context, c.phone, msg);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFD32F2F),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'FireSOSS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ระบบแจ้งเหตุอัคคีภัยฉุกเฉิน',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                    SizedBox(width: 6),
                    Text(
                      'พร้อมใช้งาน',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // SOS Button Area
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.06);
                return SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer animated glow ring
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD32F2F).withAlpha((30 * (1 - _pulseController.value)).toInt()),
                          ),
                        ),
                      ),
                      // Inner ring
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFEE2E2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD32F2F).withAlpha(40),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Core SOS Button
                      SizedBox(
                        width: 155,
                        height: 155,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _onSosPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 8,
                            padding: EdgeInsets.zero,
                          ),
                          child: _busy
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      'SOS',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'กดเพื่อแจ้งเหตุ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // GPS Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF0284C7),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'ตำแหน่งพิกัดปัจจุบัน',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      '📍 $_status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _lat != null ? const Color(0xFF047857) : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Steps Advice Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 ขั้นตอนเมื่อเกิดเหตุอัคคีภัย',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAdviceStep('1', 'ตั้งสติ และหมอบต่ำอพยพออกจากพื้นที่เสี่ยง'),
                  _buildAdviceStep('2', 'กดปุ่ม SOS เพื่อบันทึกพิกัดสถานที่เกิดเหตุ'),
                  _buildAdviceStep('3', 'โทรสายด่วน 199 หรือส่ง SMS แจ้งผู้ติดต่อ'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFFFEE2E2),
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }
}
