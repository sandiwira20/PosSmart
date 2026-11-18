import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/menu_model.dart';
import 'firebase_service.dart';

class MenuService {
  // Menu contoh awal untuk auto-seeding jika database masih kosong
  static final List<MenuModel> _demoMenus = [
    MenuModel(
      id: 'menu-1',
      name: 'Ayam Geprek Sambal Korek',
      category: 'Makanan',
      price: 22000,
      imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&q=80',
      description: 'Ayam krispi renyah dengan ulekan cabai rawit pedas mantap',
      isAvailable: true,
    ),
    MenuModel(
      id: 'menu-2',
      name: 'Es Kopi Susu Aren',
      category: 'Minuman',
      price: 15000,
      imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500&q=80',
      description: 'Espresso susu segar berpadu manis legit gula aren asli',
      isAvailable: true,
    ),
    MenuModel(
      id: 'menu-3',
      name: 'Nasi Goreng Spesial Telur',
      category: 'Makanan',
      price: 25000,
      imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=500&q=80',
      description: 'Nasi goreng harum rempah dengan telur mata sapi dan acar',
      isAvailable: true,
    ),
    MenuModel(
      id: 'menu-4',
      name: 'Kentang Goreng Keju',
      category: 'Snack',
      price: 16000,
      imageUrl: 'https://images.unsplash.com/photo-1576107232684-1279f3908594?w=500&q=80',
      description: 'French fries renyah taburan bumbu keju gurih melimpah',
      isAvailable: true,
    ),
    MenuModel(
      id: 'menu-5',
      name: 'Es Teh Manis Melati',
      category: 'Minuman',
      price: 6000,
      imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&q=80',
      description: 'Teh melati seduh segar dingin pelepas dahaga',
      isAvailable: true,
    ),
    MenuModel(
      id: 'menu-6',
      name: 'Pisang Goreng Coklat Keju',
      category: 'Snack',
      price: 18000,
      imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=500&q=80',
      description: 'Pisang tanduk manis crispy lumer saus coklat parut keju',
      isAvailable: true,
    ),
  ];

  /// Mengambil daftar menu dari Firebase Realtime Database
  /// Jika database masih kosong, otomatis melakukan seeding menu contoh awal
  static Future<List<MenuModel>> getMenus() async {
    try {
      final snapshot = await FirebaseService.menusRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        // Database masih kosong, lakukan auto-seeding ke Firebase
        await _seedInitialMenus();
        return List.from(_demoMenus);
      }

      final data = snapshot.value;
      final List<MenuModel> menus = [];

      if (data is Map) {
        data.forEach((key, val) {
          if (val is Map) {
            menus.add(MenuModel.fromMap(val, key.toString()));
          }
        });
      } else if (data is List) {
        for (int i = 0; i < data.length; i++) {
          if (data[i] != null && data[i] is Map) {
            menus.add(MenuModel.fromMap(data[i] as Map, 'menu-$i'));
          }
        }
      }

      return menus;
    } catch (e) {
      debugPrint('Error getting menus from Firebase: $e');
      return List.from(_demoMenus);
    }
  }

  /// Stream realtime untuk memantau perubahan menu secara live
  static Stream<List<MenuModel>> streamMenus() {
    return FirebaseService.menusRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <MenuModel>[];
      }

      final data = snapshot.value;
      final List<MenuModel> menus = [];

      if (data is Map) {
        data.forEach((key, val) {
          if (val is Map) {
            menus.add(MenuModel.fromMap(val, key.toString()));
          }
        });
      }
      return menus;
    });
  }

  /// Tambah Menu Baru ke Firebase Realtime Database
  static Future<bool> addMenu(MenuModel menu) async {
    try {
      final newRef = FirebaseService.menusRef.push();
      final key = newRef.key ?? 'menu-${DateTime.now().millisecondsSinceEpoch}';

      final menuData = menu.toMap();
      await newRef.set(menuData);
      return true;
    } catch (e) {
      debugPrint('Error adding menu to Firebase: $e');
      return false;
    }
  }

  /// Update Menu yang sudah ada di Firebase
  static Future<bool> updateMenu(MenuModel updatedMenu) async {
    try {
      await FirebaseService.menusRef
          .child(updatedMenu.id)
          .update(updatedMenu.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating menu in Firebase: $e');
      return false;
    }
  }

  /// Hapus Menu dari Firebase
  static Future<bool> deleteMenu(String id) async {
    try {
      await FirebaseService.menusRef.child(id).remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting menu in Firebase: $e');
      return false;
    }
  }

  /// Helper untuk inisialisasi data awal (seeding)
  static Future<void> _seedInitialMenus() async {
    try {
      for (final menu in _demoMenus) {
        await FirebaseService.menusRef.child(menu.id).set(menu.toMap());
      }
      debugPrint('Initial demo menus seeded to Firebase successfully.');
    } catch (e) {
      debugPrint('Error seeding initial menus: $e');
    }
  }
}
