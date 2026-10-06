import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../data/product_firestore.dart';
import 'login_screen.dart';

// สมมติว่า BarcaStyle อยู่ในไฟล์ constant/my_constant.dart หรือที่ที่คุณเก็บไว้
// ถ้าไม่มี ให้ประกาศไว้ที่นี่หรือเรียกใช้ตามที่คุณตั้งชื่อไว้
class BarcaStyle {
  static const Color barcaRed = Color(0xFFA50044);
  static const Color barcaBlue = Color(0xFF004D98);

  static BoxDecoration selectionDecoration({required bool isSelected}) {
    return BoxDecoration(
      color: isSelected ? barcaRed.withOpacity(0.05) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      border: isSelected ? const Border(bottom: BorderSide(color: barcaRed, width: 3)) : null,
    );
  }

  static TextStyle selectionTextStyle({required bool isSelected, double fontSize = 18}) {
    return TextStyle(
      color: isSelected ? Colors.black : Colors.black54,
      fontSize: fontSize,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    );
  }
}

class BookingScreen extends StatefulWidget {
  final dynamic field;
  const BookingScreen({super.key, this.field});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 1;
  bool _isLoading = false;

  double get _totalPrice => (widget.field as Field).pricePerHour * _duration;

  // --- ฟังก์ชันหลักในการตรวจสอบและบันทึกการจอง ---
  void _submitBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. ตรวจสอบว่าล็อกอินหรือยัง
    if (user == null) {
      _showLoginDialog();
      return;
    }

    if (_date == null || _time == null) return;

    setState(() => _isLoading = true);

    // เตรียมเวลาเริ่มและเวลาสิ้นสุด
    final start = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final end = start.add(Duration(hours: _duration));

    try {
      final field = widget.field as Field;

      // 2. ดึงข้อมูลการจองที่มีอยู่แล้วเพื่อเช็คเวลาซ้ำ (เฉพาะ confirmed)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('fieldId', isEqualTo: field.id)
          .where('status', isEqualTo: 'confirmed')
          .get();

      bool isConflict = false;
      for (var doc in querySnapshot.docs) {
        final existingStart = DateTime.parse(doc['bookingDate']);
        final existingEnd = DateTime.parse(doc['endTime']);

        if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
          isConflict = true;
          break;
        }
      }

      if (isConflict) {
        setState(() => _isLoading = false);
        _showConflictDialog();
        return;
      }

      // 3. บันทึกการจอง
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String realName = userDoc.data()?['displayName'] ?? 'ไม่ระบุชื่อ';

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'userName': realName,
        'fieldName': field.name,
        'fieldId': field.id,
        'bookingDate': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'duration': _duration,
        'totalPrice': _totalPrice,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);
      if (mounted) _showSuccessDialog();

    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Booking Error: $e");
    }
  }

  // --- ป๊อปอัพแจ้งเตือนให้เข้าสู่ระบบ ---
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: BarcaStyle.barcaRed),
            SizedBox(width: 10),
            Text('กรุณาเข้าสู่ระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('คุณจำเป็นต้องเข้าสู่ระบบก่อนจึงจะสามารถดำเนินการจองสนามได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BarcaStyle.barcaBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // ปิดป๊อปอัพ
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const LoginScreen()),
              );
            },
            child: const Text('ไปที่หน้าล็อกอิน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _showConflictDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: BarcaStyle.barcaRed),
          SizedBox(width: 10),
          Text('เวลาไม่ว่าง', style: TextStyle(fontWeight: FontWeight.bold))
        ]),
        content: const Text('ขออภัย! ช่วงเวลานี้มีการจองที่ได้รับการยืนยันไปแล้ว กรุณาเลือกเวลาอื่น'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ตกลง', style: TextStyle(color: BarcaStyle.barcaBlue)))
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('จองสำเร็จ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('ส่งคำขอจองให้แอดมินตรวจสอบแล้ว กรุณารอการยืนยันในหน้า "จัดการการจอง"'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BarcaStyle.barcaBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('ตกลง', style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field as Field;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ระบุวันเวลา', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: BarcaStyle.barcaRed))
        : Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('เลือกวันและเวลาเริ่มเตะ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _pickerButton(Icons.calendar_today, _date == null ? 'วันที่' : DateFormat('dd/MM/yyyy').format(_date!), _pickDate)),
              const SizedBox(width: 12),
              Expanded(child: _pickerButton(Icons.access_time, _time == null ? 'เวลาเริ่ม' : _time!.format(context), _pickTime)),
            ]),
            const SizedBox(height: 30),
            const Text('จำนวนชั่วโมง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) => _durationItem(i + 1)),
            ),
            const Spacer(),
            _priceSummary(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: BarcaStyle.barcaRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: (_date != null && _time != null) ? _submitBooking : null,
                child: const Text('ยืนยันการจอง', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationItem(int hour) {
    bool isSelected = _duration == hour;
    return GestureDetector(
      onTap: () => setState(() => _duration = hour),
      child: Container(
        width: 65,
        height: 50,
        alignment: Alignment.center,
        decoration: BarcaStyle.selectionDecoration(isSelected: isSelected),
        child: Text('$hour ชม.', style: BarcaStyle.selectionTextStyle(isSelected: isSelected, fontSize: 14)),
      ),
    );
  }

  Widget _pickerButton(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon, size: 18, color: BarcaStyle.barcaBlue),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500))
          ]),
        ),
      );

  Widget _priceSummary() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ราคาสุทธิ', style: TextStyle(fontSize: 16)),
            Text('฿${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BarcaStyle.barcaRed)),
          ],
        ),
      );

  void _pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)));
    if (d != null) setState(() => _date = d);
  }

  void _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _time = t);
  }
}