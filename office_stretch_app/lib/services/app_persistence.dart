import 'package:shared_preferences/shared_preferences.dart';

import '../models/persisted_app_data.dart';

abstract class AppPersistence {
  Future<PersistedAppData?> load();

  Future<void> save(PersistedAppData data);

  Future<void> clear();
}

class SharedPreferencesAppPersistence implements AppPersistence {
  SharedPreferencesAppPersistence({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'office_stretch_app.persisted_state.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<PersistedAppData?> load() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return PersistedAppData.decode(raw);
  }

  @override
  Future<void> save(PersistedAppData data) {
    return _preferences.setString(_storageKey, data.encode());
  }

  @override
  Future<void> clear() {
    return _preferences.remove(_storageKey);
  }
}

class InMemoryAppPersistence implements AppPersistence {
  PersistedAppData? _data;

  @override
  Future<PersistedAppData?> load() async => _data;

  @override
  Future<void> save(PersistedAppData data) async {
    _data = data;
  }

  @override
  Future<void> clear() async {
    _data = null;
  }
}
