import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _storage;

/// Initialize [SharedPreferences] for [PersistentReactiveValue],
/// and read initial persisted values
Future<void> initPersistentReactiveValue() async {
  _storage = await SharedPreferences.getInstance();
}

/// A [ReactiveValue] backed by [SharedPreferences]
abstract class _PersistentReactiveValue<T> extends ReactiveValue<T> {
  final String _key;

  _PersistentReactiveValue(String key, T defaultValue)
      : _key = key,
        super(defaultValue) {
    assert(_storage != null,
        'Need to call `await PersistentReactiveValue.init()` first');
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
}

/// A [ReactiveValue] backed by [SharedPreferences]
class PersistentReactiveValue<T> extends _PersistentReactiveValue<T> {
  PersistentReactiveValue(String key, T defaultValue)
      : super(key, defaultValue) {
    assert(!_isNullable, 'Type parameter must not be nullable: $runtimeType');
    switch (runtimeType) {
      case PersistentReactiveValue<int>:
        super.value = _storage!.getInt(_key) as T? ?? defaultValue;
        break;
      case PersistentReactiveValue<bool>:
        super.value = _storage!.getBool(_key) as T? ?? defaultValue;
        break;
      case PersistentReactiveValue<double>:
        super.value = _storage!.getDouble(_key) as T? ?? defaultValue;
        break;
      case PersistentReactiveValue<String>:
        super.value = _storage!.getString(_key) as T? ?? defaultValue;
        break;
      case PersistentReactiveValue<List<String>>:
        super.value = _storage!.getStringList(_key) as T? ?? defaultValue;
        break;
      default:
        throw Exception('Type parameter not supported: $runtimeType');
    }
  }

  @override
  set value(T newValue) {
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

/// A nullable [ReactiveValue] backed by [SharedPreferences]
class PersistentReactiveNullableValue<T> extends _PersistentReactiveValue<T?> {
  PersistentReactiveNullableValue(String key, [T? defaultValue])
      : super(key, defaultValue) {
    assert(_isNullable, 'Type parameter must be nullable: $runtimeType');
    switch (runtimeType) {
      case PersistentReactiveValue<int?>:
        super.value = _storage!.getInt(_key) as T? ?? defaultValue;
        break;
      case PersistentReactiveValue<bool?>:
        super.value = _storage!.getBool(_key) as T? ?? defaultValue;
        break;
      case PersistentReactiveValue<double?>:
        super.value = _storage!.getDouble(_key) as T? ?? defaultValue;
        break;
      case PersistentReactiveValue<String?>:
        super.value = _storage!.getString(_key) as T? ?? defaultValue;
        break;
      case PersistentReactiveValue<List<String>?>:
        super.value = _storage!.getStringList(_key) as T? ?? defaultValue;
        break;
      default:
        throw Exception('Type parameter not supported: $runtimeType');
    }
  }

  @override
  set value(T? newValue) {
    super.value = newValue;
    switch (runtimeType) {
      case PersistentReactiveValue<int?>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setInt(_key, newValue as int);
        }
        break;
      case PersistentReactiveValue<bool?>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setBool(_key, newValue as bool);
        }
        break;
      case PersistentReactiveValue<double?>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setDouble(_key, newValue as double);
        }
        break;
      case PersistentReactiveValue<String?>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setString(_key, newValue as String);
        }
        break;
      case PersistentReactiveValue<List<String>?>:
        if (newValue == null) {
          _storage!.remove(_key);
        } else {
          _storage!.setStringList(_key, newValue as List<String>);
        }
        break;
      default:
        // Should not happen, checked in constructor
        throw Exception('Type parameter not supported: $runtimeType');
    }
  }
}
