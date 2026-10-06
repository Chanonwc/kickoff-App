import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/product_firestore.dart';
import 'package:Kikoff/constant/my_constant.dart';
class FieldsListScreen extends StatefulWidget {
  const FieldsListScreen({super.key});
  @override
  State<FieldsListScreen> createState() => _FieldsListScreenState();
}

class _FieldsListScreenState extends State<FieldsListScreen> {
  String _searchQuery = "";
  String _sortBy = "name";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('KickOff', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'name', child: Text('เรียงตามชื่อ')),
              const PopupMenuItem(value: 'priceAsc', child: Text('ราคา: ต่ำ - สูง')),
              const PopupMenuItem(value: 'priceDesc', child: Text('ราคา: สูง - ต่ำ')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อสนาม...',
                prefixIcon: const Icon(Icons.search, color: BarcaStyle.barcaBlue), // ใช้ BarcaStyle
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('fields').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var fields = snapshot.data!.docs.map((d) => Field.fromFirestore(d)).toList();
                fields = fields.where((f) => f.name.toLowerCase().contains(_searchQuery)).toList();
                if (_sortBy == 'priceAsc') fields.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
                else if (_sortBy == 'priceDesc') fields.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: fields.length,
                  itemBuilder: (context, i) => _buildFieldCard(context, fields[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context, Field field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/detail', arguments: field),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(field.image, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(field.location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  Text('฿${field.pricePerHour}/ชม.', style: const TextStyle(color: BarcaStyle.barcaRed, fontWeight: FontWeight.bold, fontSize: 16)), // ใช้ BarcaStyle
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}