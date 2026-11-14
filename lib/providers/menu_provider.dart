import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';

class MenuProvider with ChangeNotifier {
  List<MenuModel> _menus = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  List<MenuModel> get menus => _menus;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<MenuModel> get filteredMenus {
    return _menus.where((menu) {
      final matchesCategory = _selectedCategory == 'all' ||
          menu.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          menu.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> fetchMenus() async {
    _isLoading = true;
    notifyListeners();

    _menus = await MenuService.getMenus();
    _isLoading = false;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> addMenu(MenuModel menu) async {
    final success = await MenuService.addMenu(menu);
    if (success) {
      await fetchMenus();
    }
    return success;
  }

  Future<bool> updateMenu(MenuModel menu) async {
    final success = await MenuService.updateMenu(menu);
    if (success) {
      await fetchMenus();
    }
    return success;
  }

  Future<bool> deleteMenu(String id) async {
    final success = await MenuService.deleteMenu(id);
    if (success) {
      await fetchMenus();
    }
    return success;
  }

  Future<void> toggleAvailability(String id) async {
    await MenuService.toggleAvailability(id);
    await fetchMenus();
  }
}
