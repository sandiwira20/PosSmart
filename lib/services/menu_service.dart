import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/menu_model.dart';
import '../core/constants/app_constants.dart';

class MenuService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream semua menu (real-time)
  Stream<List<MenuModel>> streamMenu({String? category}) {
    return _db.ref(AppConstants.menuPath).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final map = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final menus = map.entries
          .map((e) => MenuModel.fromMap(
                e.key as String,
                Map<dynamic, dynamic>.from(e.value as Map),
              ))
          .where((m) => m.isAvailable)
          .toList();

      if (category != null && category != 'Semua') {
        return menus.where((m) => m.category == category).toList();
      }
      return menus;
    });
  }

  // Stream semua menu untuk admin (termasuk yang tidak tersedia)
  Stream<List<MenuModel>> streamAllMenuAdmin() {
    return _db.ref(AppConstants.menuPath).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final map = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      return map.entries
          .map((e) => MenuModel.fromMap(
                e.key as String,
                Map<dynamic, dynamic>.from(e.value as Map),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Create menu baru
  Future<String> createMenu(MenuModel menu, {File? imageFile}) async {
    final ref = _db.ref(AppConstants.menuPath).push();
    final id = ref.key!;

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadMenuImage(id, imageFile);
    }

    final menuWithId = menu.copyWith(id: id, imageUrl: imageUrl);
    await ref.set(menuWithId.toMap());
    return id;
  }

  // Update menu
  Future<void> updateMenu(MenuModel menu, {File? imageFile}) async {
    String? imageUrl = menu.imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadMenuImage(menu.id, imageFile);
    }

    final updatedMenu = menu.copyWith(imageUrl: imageUrl);
    await _db
        .ref('${AppConstants.menuPath}/${menu.id}')
        .update(updatedMenu.toMap());
  }

  // Delete menu
  Future<void> deleteMenu(String menuId) async {
    // Delete image if exists
    try {
      await _storage.ref('menu_images/$menuId').delete();
    } catch (_) {}
    await _db.ref('${AppConstants.menuPath}/$menuId').remove();
  }

  // Toggle availability
  Future<void> toggleAvailability(String menuId, bool isAvailable) async {
    await _db
        .ref('${AppConstants.menuPath}/$menuId')
        .update({'is_available': isAvailable});
  }

  // Upload image to Firebase Storage
  Future<String> uploadMenuImage(String menuId, File imageFile) async {
    final storageRef = _storage.ref('menu_images/$menuId');
    final uploadTask = await storageRef.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }
}
