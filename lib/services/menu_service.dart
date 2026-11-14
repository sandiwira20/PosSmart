import 'package:flutter/foundation.dart';
import '../models/menu_model.dart';

class MenuService {
  // Initial demo menus based on Stitch design & Indonesian UMKM favorites
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

  static List<MenuModel> _localMenus = List.from(_demoMenus);

  // Read
  static Future<List<MenuModel>> getMenus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_localMenus);
  }

  // Create
  static Future<bool> addMenu(MenuModel menu) async {
    try {
      _localMenus.add(menu);
      return true;
    } catch (e) {
      debugPrint('Error adding menu: $e');
      return false;
    }
  }

  // Update
  static Future<bool> updateMenu(MenuModel updatedMenu) async {
    try {
      final index = _localMenus.indexWhere((m) => m.id == updatedMenu.id);
      if (index != -1) {
        _localMenus[index] = updatedMenu;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating menu: $e');
      return false;
    }
  }

  // Delete
  static Future<bool> deleteMenu(String id) async {
    try {
      _localMenus.removeWhere((m) => m.id == id);
      return true;
    } catch (e) {
      debugPrint('Error deleting menu: $e');
      return false;
    }
  }

  // Toggle availability
  static Future<bool> toggleAvailability(String id) async {
    final index = _localMenus.indexWhere((m) => m.id == id);
    if (index != -1) {
      final current = _localMenus[index];
      _localMenus[index] = current.copyWith(isAvailable: !current.isAvailable);
      return true;
    }
    return false;
  }
}
