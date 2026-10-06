import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// --- ธีม Barca Style ---
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
}

// --- โมเดลสินค้าจาก API ---
class Product {
  final int id;
  final String name;
  final double price;
  final String image;

  Product({required this.id, required this.name, required this.price, required this.image});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['title'] ?? 'ไม่มีชื่อสินค้า',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? 'https://via.placeholder.com/150',
    );
  }
}

// --- โมเดลสินค้าในตะกร้า ---
class CartItem {
  final int id;
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({required this.id, required this.name, required this.price, required this.image, this.quantity = 1});
}

// --- ตัวจัดการตะกร้าสินค้า (Cart Manager) ---
class CartManager {
  static List<CartItem> items = [];

  static void addToCart(Product product) {
    int index = items.indexWhere((item) => item.id == product.id);
    if (index != -1) {
      items[index].quantity++;
    } else {
      items.add(CartItem(id: product.id, name: product.name, price: product.price, image: product.image));
    }
  }

  static double get totalPrice => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}