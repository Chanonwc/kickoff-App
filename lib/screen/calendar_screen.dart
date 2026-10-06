import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // ใช้สำหรับฟังก์ชัน isSameDay

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  
  // สีประจำธีม
  final Color barcaBlue = const Color(0xFF004D98);
  final Color barcaRed = const Color(0xFFA50044);

  @override
  void initState() {
    super.initState();
    // เมื่อสร้างหน้าจอเสร็จ ให้เลื่อนแถบวันที่ไปที่ "วันนี้" ทันที
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    // คำนวณตำแหน่ง: (ความกว้าง item 60 + margin 8) * index ที่ 30
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        30 * 68.0, 
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ตารางการใช้สนาม', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. แถบวันที่แนวนอนแบบเลื่อนได้ (ปรับปรุงใหม่)
          Container(
            height: 95,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: 90, // แสดงทั้งหมด 90 วัน (ย้อนหลัง 30 วัน, ล่วงหน้า 60 วัน)
              itemBuilder: (ctx, i) {
                // index ที่ 30 จะตรงกับ "วันนี้"
                final date = DateTime.now().add(Duration(days: i - 30));
                bool isSelected = isSameDay(_selectedDate, date);
                bool isToday = isSameDay(DateTime.now(), date);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? barcaRed.withOpacity(0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected 
                          ? Border(bottom: BorderSide(color: barcaRed, width: 3)) 
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM').format(date).toUpperCase(), 
                          style: TextStyle(
                            color: isSelected ? barcaRed : Colors.grey, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          date.day.toString(), 
                          style: TextStyle(
                            color: isToday && !isSelected ? barcaBlue : (isSelected ? Colors.black : Colors.black54), 
                            fontSize: 18, 
                            fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        if (isToday) 
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: barcaBlue, shape: BoxShape.circle))
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 2. รายการจองที่ดึงจาก Firestore (Public View)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('status', isEqualTo: 'confirmed') // แสดงเฉพาะรายการที่ยืนยันแล้ว
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('เกิดข้อผิดพลาดในการดึงข้อมูล'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // กรองข้อมูลเฉพาะวันที่เลือกใน UI
                final dayEvents = snapshot.data!.docs.where((doc) {
                  try {
                    final d = DateTime.parse(doc['bookingDate']);
                    return isSameDay(d, _selectedDate);
                  } catch (e) {
                    return false;
                  }
                }).toList();

                if (dayEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text('ไม่มีการจองในวันนี้', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dayEvents.length,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  itemBuilder: (ctx, i) {
                    final data = dayEvents[i].data() as Map<String, dynamic>;
                    String time = "N/A";
                    try {
                      time = DateFormat('HH:mm').format(DateTime.parse(data['bookingDate']));
                    } catch (e) {}
                    
                    return _buildPublicEventCard(context, time, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // ปุ่มลัดเด้งกลับมาวันนี้
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _selectedDate = DateTime.now());
          _scrollToToday();
        },
        backgroundColor: barcaBlue,
        mini: true,
        child: const Icon(Icons.today, color: Colors.white),
      ),
    );
  }

  Widget _buildPublicEventCard(BuildContext context, String time, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () => _showPublicBookingDetails(context, data),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(time, style: TextStyle(color: barcaRed, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['fieldName'] ?? 'สนามกีฬา', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('โดย: ${data['userName'] ?? 'ไม่ระบุชื่อ'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showPublicBookingDetails(BuildContext context, Map<String, dynamic> data) {
    final DateTime start = DateTime.parse(data['bookingDate']);
    final int duration = data['duration'] ?? 1;
    final DateTime end = start.add(Duration(hours: duration));
    final String timeRange = "${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)} น.";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('รายละเอียดการจอง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 25),
            _publicDetailRow(Icons.stadium_outlined, 'สนาม', data['fieldName'] ?? 'ไม่ระบุ'),
            _publicDetailRow(Icons.person_outline, 'ชื่อผู้จอง', data['userName'] ?? 'ไม่ระบุ'),
            _publicDetailRow(Icons.calendar_month_outlined, 'วันที่', DateFormat('dd MMMM yyyy').format(start)),
            _publicDetailRow(Icons.access_time, 'เวลา', timeRange),
            _publicDetailRow(Icons.timer_outlined, 'ระยะเวลา', '$duration ชั่วโมง'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _publicDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: barcaBlue),
          const SizedBox(width: 15),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}