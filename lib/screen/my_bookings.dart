import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('จัดการการจอง',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final bool isAdmin = userData['role'] == 'admin';

                return StreamBuilder<QuerySnapshot>(
                  stream: isAdmin
                      ? FirebaseFirestore.instance
                          .collection('bookings')
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('bookings')
                          .where('userId', isEqualTo: user.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('ไม่มีรายการจองในขณะนี้',
                              style: TextStyle(color: Colors.grey)));
                    }

                    final docs = snapshot.data!.docs;

                    // คำนวณรายได้รวมสำหรับ Admin
                    double totalRevenue = 0;
                    if (isAdmin) {
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['status'] == 'confirmed') {
                          totalRevenue += (data['totalPrice'] ?? 0).toDouble();
                        }
                      }
                    }

                    return Column(
                      children: [
                        if (isAdmin) _buildRevenueCard(totalRevenue),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final data =
                                  docs[i].data() as Map<String, dynamic>;
                              final String bookingId = docs[i].id;

                              return _buildBookingItem(
                                  context, data, bookingId, isAdmin);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  // Widget แสดงรายการจองแต่ละรายการ
  Widget _buildBookingItem(BuildContext context, Map<String, dynamic> data,
      String docId, bool isAdmin) {
    final String status = data['status'] ?? 'pending';
    final Color statusColor =
        status == 'confirmed' ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        // เพิ่มการกดเพื่อดูรายละเอียด
        onTap: () => _showBookingDetails(context, data),
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          contentPadding: const EdgeInsets.all(15),
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(
                status == 'confirmed'
                    ? Icons.check_circle
                    : Icons.pending_actions,
                color: statusColor),
          ),
          title: Text(data['fieldName'] ?? 'ไม่ระบุสนาม',
              style: const TextStyle(fontWeight: FontWeight.bold)), // ดัก Null
          subtitle: Text(
            'ผู้จอง: ${data['userName'] ?? 'ไม่ระบุชื่อ'}\n' + // ดัก Null
                'วันที่: ${(data['bookingDate'] ?? '').toString().split('T')[0]}', // ดัก Null
          ),
          trailing: isAdmin && status == 'pending'
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: () => _confirmBooking(context, docId),
                  child: const Text('ยืนยัน',
                      style: TextStyle(color: Colors.white)),
                )
              : Icon(Icons.chevron_right, color: Colors.grey[400]),
        ),
      ),
    );
  }

  // หน้าต่างแสดงรายละเอียดเชิงลึก (Bottom Sheet)
  void _showBookingDetails(BuildContext context, Map<String, dynamic> data) {
    final DateTime start = DateTime.parse(data['bookingDate']);
    final int duration = data['duration'] ?? 1;
    final DateTime end = start.add(Duration(hours: duration));
    final String timeRange =
        "${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)} น.";

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('รายละเอียดการจอง',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Divider(height: 10),
            _detailRow(Icons.stadium_outlined, 'สนาม', data['fieldName']),
            _detailRow(Icons.person_outline, 'ชื่อผู้จอง', data['userName']),

            // ดึงเบอร์โทรศัพท์จากคอลเลกชัน users
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['userId'])
                  .get(),
              builder: (context, snap) {
                final phone =
                    (snap.data?.data() as Map<String, dynamic>?)?['phone'] ??
                        'ไม่ระบุ';
                return _detailRow(Icons.phone_outlined, 'เบอร์ติดต่อ', phone);
              },
            ),

            _detailRow(Icons.calendar_month_outlined, 'วันที่',
                DateFormat('dd/MM/yyyy').format(start)),
            _detailRow(Icons.access_time, 'เวลาเตะ', timeRange),
            _detailRow(Icons.timer_outlined, 'ระยะเวลา', '$duration ชั่วโมง'),
            _detailRow(Icons.payments_outlined, 'ราคาสุทธิ',
                '฿${data['totalPrice'] ?? '0'}'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF004D98)),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF004D98), Color(0xFFA50044)]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('รายได้รวมจากการจองที่สำเร็จ',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text('฿${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ยืนยันการจองเรียบร้อยแล้ว!'),
        backgroundColor: Colors.green));
  }
}

