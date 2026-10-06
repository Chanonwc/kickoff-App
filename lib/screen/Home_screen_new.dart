import 'package:flutter/material.dart';
import 'fields_list.dart'; // เปลี่ยนไปเรียกหน้าลิสต์สนาม
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'my_bookings.dart'; // อย่าลืมสร้างไฟล์นี้
import 'Product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // รายชื่อหน้าจอหลัก 4 หน้า
  final List<Widget> _screens = [
    const FieldsListScreen(), // หน้า 1: รายการสนาม (Home)
    const ProductListScreen(), // หน้า 2: รายการสินค้า
    const MyBookingsScreen(), // หน้า 2: รายการที่ User จองไว้
    const CalendarScreen(), // หน้า 3: ปฏิทินรวม
    const ProfileScreen(), // หน้า 4: โปรไฟล์/ตั้งค่า
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFA50044), // สีแดง Barca
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.stadium), label: "สนาม"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "สินค้า"),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: "จองของฉัน"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: "ตาราง"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "โปรไฟล์"),
        ],
      ),
    );
  }
}
