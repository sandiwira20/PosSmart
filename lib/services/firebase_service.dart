import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static const String databaseUrl =
      'https://possmart-app-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Instance Firebase Realtime Database yang sudah terarah ke Region Singapore
  static FirebaseDatabase get database {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
  }

  /// Reference untuk tabel 'menus'
  static DatabaseReference get menusRef => database.ref('menus');

  /// Reference untuk tabel 'transactions'
  static DatabaseReference get transactionsRef => database.ref('transactions');

  /// Reference untuk tabel 'users'
  static DatabaseReference get usersRef => database.ref('users');
}
