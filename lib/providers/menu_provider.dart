import 'package:flutter/foundation.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _menuService = MenuService();

  List<MenuModel> _menus = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<MenuModel> get menus => _filteredMenus;
  List<MenuModel> get allMenus => _menus;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MenuModel> get _filteredMenus {
    var result = _menus;
    if (_selectedCategory != 'Semua') {
      result = result.where((m) => m.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((m) =>
              m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return result;
  }

  void setMenus(List<MenuModel> menus) {
    _menus = menus;
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

  Stream<List<MenuModel>> streamMenu() {
    return _menuService.streamMenu();
  }

  Stream<List<MenuModel>> streamAllMenuAdmin() {
    return _menuService.streamAllMenuAdmin();
  }
}
