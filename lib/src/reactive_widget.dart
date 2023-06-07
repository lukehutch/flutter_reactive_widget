// flutter_reactive_widget library
//
// (C) 2023 Luke Hutchison
//
// Published under MIT license
//
// Source hosted at:
// https://github.com/lukehutch/flutter_reactive_widget

import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

// The stack of ReactiveWidgets that are being built
final _currReactiveWidgetState = <_ReactiveWidgetState>[];

/// A reactive widget. Will be rebuilt when the value of any [ReactiveValue]
/// object read by this `ReactiveWidget` is  changed.
class ReactiveWidget extends StatefulWidget {
  final Widget Function() _build;
  const ReactiveWidget(Widget Function() build, {super.key}) : _build = build;

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
    // Record this ReactiveWidget as being built
    _currReactiveWidgetState.add(this);
    try {
      // Call ReactiveWidget.build()
      _cachedWidget = (context.widget as ReactiveWidget)._build();
      return _cachedWidget!;
    } finally {
      // Pop this ReactiveWidget from the stack
      _currReactiveWidgetState.removeLast();
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

// Mark the ReactiveWidget as needing to be rebuilt.
  void _updateReactiveWidget() {
    // Widget may no longer be mounted, if dispose() was called after build()
    if (mounted) {
      setState(() => _cachedWidget = null);
    }
  }

  // Add a listener to call setState when the ReactiveValue value changes
  void _listener() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // Need to defer calling setState until after `build` has completed:
      // https://stackoverflow.com/a/59478165/3950982
      // It suffices to check whether persistent callbacks are being run:
      // https://github.com/flutter/flutter/issues/128384#issuecomment-1580062544
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updateReactiveWidget());
    } else {
      // Set state immediately if persistent callbacks are not being called
      _updateReactiveWidget();
    }
  }
}

/// A reactive value, automatically listened to by any [ReactiveWidget] that
/// tries to read the value.
class ReactiveValue<T> extends ValueNotifier<T> {
  ReactiveValue(super.value);

  @override
  T get value {
    // Ensure that the wrapping ReactiveWidget is listening to value changes
    if (_currReactiveWidgetState.isNotEmpty) {
      _currReactiveWidgetState.last._listenTo(this);
    }
    return super.value;
  }

  /// Used to manually invoke notifyListeners(), e.g. when items are
  /// added to or removed from a ReactiveValue<Set<T>>
  void notifyListeners() {
    super.notifyListeners();
  }
}
