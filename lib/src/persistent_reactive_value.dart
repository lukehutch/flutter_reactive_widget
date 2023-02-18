import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _storage;

/// A [ReactiveValue] backed by [SharedPreferences]
class PersistentReactiveValue<T> extends ReactiveValue<T?> {
  final String _key;
  PersistentReactiveValue(String key, [T? defaultValue])
      : _key = key,
        super(defaultValue) {
    assert(_storage != null,
        'Need to call `await PersistentReactiveValue.init()` first');
    final isNullable = _isNullable;
    assert(
        isNullable || defaultValue != null,
        'Must specify a non-null `defaultValue` since ' +
            'type parameter is not nullable: $runtimeType');
    dynamic persistedVal;
    switch (runtimeType) {
      case PersistentReactiveValue<int>:
      case PersistentReactiveValue<int?>:
        persistedVal = _storage!.getInt(_key);
        break;
      case PersistentReactiveValue<bool>:
      case PersistentReactiveValue<bool?>:
        persistedVal = _storage!.getBool(_key);
        break;
      case PersistentReactiveValue<double>:
      case PersistentReactiveValue<double?>:
        persistedVal = _storage!.getDouble(_key);
        break;
      case PersistentReactiveValue<String>:
      case PersistentReactiveValue<String?>:
        persistedVal = _storage!.getString(_key);
        break;
      case PersistentReactiveValue<List<String>>:
      case PersistentReactiveValue<List<String>?>:
        persistedVal = _storage!.getStringList(_key);
        break;
      default:
        throw Exception('Type parameter not supported: $runtimeType');
    }
    super.value = persistedVal != null ? persistedVal as T : defaultValue;
  }

  // https://stackoverflow.com/a/67583208/3950982
  bool get _isNullable {
    try {
      // Throws an exception if T is not nullable
      T? nullT;
      if (nullT is T) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Initialize [SharedPreferences] and read persisted values
  static Future<void> init() async {
    _storage = await SharedPreferences.getInstance();
  }

  @override
  set value(T? newValue) {
    super.value = newValue;
    switch (runtimeType) {
      case PersistentReactiveValue<int>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setInt(_key, newValue as int);
        }
        break;
      case PersistentReactiveValue<bool>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setBool(_key, newValue as bool);
        }
        break;
      case PersistentReactiveValue<double>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setDouble(_key, newValue as double);
        }
        break;
      case PersistentReactiveValue<String>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setString(_key, newValue as String);
        }
        break;
      case PersistentReactiveValue<List<String>>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setStringList(_key, newValue as List<String>);
        }
        break;
      default:
        throw Exception('Type parameter not supported: $runtimeType');
    }
  }
}
