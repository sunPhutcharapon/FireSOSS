import 'package:flutter/material.dart';

import 'actions_helper.dart';
import 'storage.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _formatTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final year = d.year + 543; // พ.ศ.
  const months = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];
  final monthStr = months[d.month - 1];
  return '${d.day} $monthStr $year • ${_two(d.hour)}:${_two(d.minute)} น.';
}

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text('ล้างประวัติทั้งหมด?'),
          ],
        ),
        content: const Text('ประวัติการกด SOS ทั้งหมดจะถูกลบถาวรและไม่สามารถกู้คืนได้'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('ล้างประวัติ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AppStore.instance.clearLogs();
      if (context.mounted) {
        showMessage(context, 'ล้างประวัติเรียบร้อยแล้ว');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final logs = AppStore.instance.logs;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ประวัติการแจ้งเหตุ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'รายการกด SOS และบันทึกพิกัด (${logs.length} รายการ)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (logs.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _confirmClear(context),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                      label: const Text('ล้าง', style: TextStyle(color: Color(0xFFDC2626))),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Content List or Empty State
              Expanded(
                child: logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history_toggle_off_rounded,
                                size: 54,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ยังไม่มีประวัติการแจ้งเหตุ',
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
                                'เมื่อคุณกดปุ่ม SOS ในหน้าหลัก ระบบจะบันทึกเวลาและพิกัดไว้ที่นี่เพื่อความสะดวกในการตรวจสอบย้อนหลัง',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, i) {
                          final l = logs[i];
                          final hasCoords = l.lat != null && l.lng != null;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFD32F2F),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatTime(l.timestamp),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 14,
                                              color: hasCoords ? const Color(0xFF047857) : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                hasCoords
                                                    ? '${l.lat!.toStringAsFixed(6)}, ${l.lng!.toStringAsFixed(6)}'
                                                    : 'ไม่ทราบพิกัด',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: hasCoords ? const Color(0xFF047857) : Colors.grey.shade600,
                                                  fontWeight: hasCoords ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasCoords)
                                    IconButton(
                                      icon: const Icon(Icons.map_outlined, color: Color(0xFF0284C7)),
                                      tooltip: 'เปิดใน Google Maps',
                                      onPressed: () => openFireStationsInMaps(
                                        context,
                                        lat: l.lat,
                                        lng: l.lng,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
