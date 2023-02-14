/// Support for doing something awesome.
///
/// More dartdocs go here.
library flutter_reactive_widget;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A reactive widget. Will be rebuilt when the value of any [ReactiveValue] object
/// read by this `ReactiveWidget` is  changed.
class ReactiveWidget extends StatefulWidget {
  final Widget Function(BuildContext context) _build;
  const ReactiveWidget(Widget Function(BuildContext context) build, {super.key})
      : _build = build;

  @override
  State<ReactiveWidget> createState() => _ReactiveWidgetState();
}

/// Maintains the state of a [ReactiveWidget]
class _ReactiveWidgetState extends State<ReactiveWidget> {
  // The cached widget, reused if no state changes
  Widget? _cachedWidget;
  // The set of `ReactiveValue` objects for which listeners have been added
  final _listeningTo = <ReactiveValue>{};

  @override
  Widget build(BuildContext context) {
    return _cachedWidget ?? _rebuild(context);
  }

  Widget _rebuild(BuildContext context) {
    // Remove all ReactiveValue listeners when the widget tree is being rebuilt,
    // since the set of referenced ReactiveValue objects may change
    removeAllListeners();
    // Make sure only one `build` method is being called at once (`build` does
    // not currently work recursively, but maybe this will change in a future
    // version of Flutter)
    if (ReactiveValue._currReactiveWidgetState != null) {
      throw Exception('build() should not be called recursively');
    }
    // Record this ReactiveWidget as being built
    ReactiveValue._currReactiveWidgetState = this;
    try {
      // Call ReactiveWidget.build()
      _cachedWidget = (context.widget as ReactiveWidget)._build(context);
      return _cachedWidget!;
    } finally {
      ReactiveValue._currReactiveWidgetState = null;
    }
  }

  // Remove all ReactiveValue listeners when disposing of this widget
  @override
  void dispose() {
    removeAllListeners();
    super.dispose();
  }

  // Remove all ReactiveValue listeners
  void removeAllListeners() {
    for (var reactiveValue in _listeningTo) {
      reactiveValue.removeListener(_listener);
    }
    _listeningTo.clear();
  }

  // Subscribe to changes in a ReactiveValue
  void _listenTo(ReactiveValue reactiveValue) {
    // Only listen to a given ReactiveValue once per ReactiveWidget
    if (_listeningTo.add(reactiveValue)) {
      // Listen to the ReactiveValue
      reactiveValue.addListener(_listener);
    }
  }

  // Add a listener to call setState when the ReactiveValue value changes
  void _listener() {
    setState(() {
      // Calling setState marks this ReactiveWidget as needing to be rebuilt.
      _cachedWidget = null;
    });
  }
}

/// A reactive value, automatically listened to by any [ReactiveWidget] that tries to read the value.
class ReactiveValue<T> extends ValueNotifier<T> {
  // The current ReactiveWidget that is being built
  static _ReactiveWidgetState? _currReactiveWidgetState;

  ReactiveValue(super.value);

  @override
  T get value {
    // Ensure that the wrapping ReactiveWidget is listening to value changes
    _currReactiveWidgetState?._listenTo(this);
    return super.value;
  }
}

/// A [ReactiveValue] backed by [SharedPreferences]
class PersistentReactiveValue<T> extends ReactiveValue<T> {
  final String _key;
  PersistentReactiveValue(String key, T defaultValue)
      : _key = key,
        super(defaultValue) {
    // Asynchronously overwrite defaultValue with the persisted value, if it's in SharedPreferences
    () async {
      final prefs = await SharedPreferences.getInstance();
      dynamic persistedVal;
      switch (runtimeType) {
        case PersistentReactiveValue<int>:
          persistedVal = prefs.getInt(_key);
          break;
        case PersistentReactiveValue<String>:
          persistedVal = prefs.getString(_key);
          break;
        case PersistentReactiveValue<bool>:
          persistedVal = prefs.getBool(_key);
          break;
        default:
          throw Exception('Type parameter not supported: $runtimeType');
      }
      if (persistedVal != null) {
        super.value = persistedVal as T;
      }
    }();
  }

  @override
  set value(T newValue) {
    super.value = newValue;
    () async {
      final prefs = await SharedPreferences.getInstance();
      switch (runtimeType) {
        case PersistentReactiveValue<int>:
          prefs.setInt(_key, newValue as int);
          break;
        case PersistentReactiveValue<String>:
          prefs.setString(_key, newValue as String);
          break;
        case PersistentReactiveValue<bool>:
          prefs.setBool(_key, newValue as bool);
          break;
        default:
          throw Exception('Type parameter not supported: $runtimeType');
      }
    }();
  }
}
