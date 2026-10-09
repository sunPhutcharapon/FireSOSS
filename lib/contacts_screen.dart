import 'package:flutter/material.dart';

import 'actions_helper.dart';
import 'storage.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showAddContactBottomSheet() {
    _nameCtrl.clear();
    _phoneCtrl.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: const [
                Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFD32F2F)),
                SizedBox(width: 8),
                Text(
                  'เพิ่มผู้ติดต่อฉุกเฉิน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'ชื่อผู้ติดต่อ',
                hintText: 'เช่น คุณแม่ / เพื่อนสนิท',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                hintText: 'เช่น 0812345678',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  final phone = _phoneCtrl.text.trim();
                  if (name.isEmpty || phone.isEmpty) {
                    showMessage(context, 'กรุณากรอกชื่อและเบอร์โทรศัพท์');
                    return;
                  }
                  await AppStore.instance.addContact(name, phone);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  showMessage(context, 'บันทึกรายชื่อผู้ติดต่อเรียบร้อยแล้ว');
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('บันทึกผู้ติดต่อ', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ลบผู้ติดต่อ?'),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบ "$name" ออกจากรายการผู้ติดต่อฉุกเฉิน?'),
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
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppStore.instance.deleteContact(id);
      if (!mounted) return;
      showMessage(context, 'ลบผู้ติดต่อเรียบร้อยแล้ว');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final contacts = AppStore.instance.contacts;
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
                          'ผู้ติดต่อฉุกเฉิน',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'รายชื่อสำหรับรับ SMS พิกัดเหตุฉุกเฉิน (${contacts.length} คน)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _showAddContactBottomSheet,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('เพิ่ม'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Content List or Empty State
              Expanded(
                child: contacts.isEmpty
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
                                Icons.contacts_outlined,
                                size: 54,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ยังไม่มีผู้ติดต่อฉุกเฉิน',
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
                                'เพิ่มรายชื่อบุคคลสำคัญเพื่อให้ระบบสามารถส่ง SMS แจ้งพิกัดเหตุฉุกเฉินได้ทันที',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _showAddContactBottomSheet,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('เพิ่มผู้ติดต่อคนแรก'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, i) {
                          final c = contacts[i];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  child: Text(
                                    c.name.isNotEmpty ? c.name[0] : 'C',
                                    style: const TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Text(
                                  c.phone,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.phone_rounded, color: Color(0xFF047857)),
                                      tooltip: 'โทรหาผู้ติดต่อ',
                                      onPressed: () => callNumber(context, c.phone),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade500),
                                      tooltip: 'ลบผู้ติดต่อ',
                                      onPressed: () => _confirmDelete(c.id, c.name),
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
      },
    );
  }
}
