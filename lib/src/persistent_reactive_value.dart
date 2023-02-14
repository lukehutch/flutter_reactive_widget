import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _storage;

/// A [ReactiveValue] backed by [SharedPreferences]
class PersistentReactiveValue<T> extends ReactiveValue<T> {
  final String _key;
  PersistentReactiveValue(String key, T defaultValue)
      : _key = key,
        super(defaultValue) {
    assert(_storage != null,
        'Need to call `await PersistentReactiveValue.init()` first');
    dynamic persistedVal;
    switch (runtimeType) {
      case PersistentReactiveValue<int>:
        persistedVal = _storage!.getInt(_key);
        break;
      case PersistentReactiveValue<bool>:
        persistedVal = _storage!.getBool(_key);
        break;
      case PersistentReactiveValue<double>:
        persistedVal = _storage!.getDouble(_key);
        break;
      case PersistentReactiveValue<String>:
        persistedVal = _storage!.getString(_key);
        break;
      case PersistentReactiveValue<List<String>>:
        persistedVal = _storage!.getStringList(_key);
        break;
      default:
        throw Exception('Type parameter not supported: $runtimeType');
    }
    super.value = persistedVal != null ? persistedVal as T : defaultValue;
  }

  /// Initialize [SharedPreferences] and read persisted values
  static Future<void> init() async {
    _storage = await SharedPreferences.getInstance();
  }

  @override
  set value(T newValue) {
    assert(_storage != null,
        'Need to call `await PersistentReactiveValue.init()` first');
    super.value = newValue;
    switch (runtimeType) {
      case PersistentReactiveValue<int>:
        _storage!.setInt(_key, newValue as int);
        break;
      case PersistentReactiveValue<bool>:
        _storage!.setBool(_key, newValue as bool);
        break;
      case PersistentReactiveValue<double>:
        _storage!.setDouble(_key, newValue as double);
        break;
      case PersistentReactiveValue<String>:
        _storage!.setString(_key, newValue as String);
        break;
      case PersistentReactiveValue<List<String>>:
        _storage!.setStringList(_key, newValue as List<String>);
        break;
      default:
        throw Exception('Type parameter not supported: $runtimeType');
    }
  }
}
