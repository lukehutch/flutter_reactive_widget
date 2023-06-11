// flutter_reactive_widget library
//
// (C) 2023 Luke Hutchison
//
// Published under MIT license
//
// Source hosted at:
// https://github.com/lukehutch/flutter_reactive_widget

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

class _HashableWeakReference<T extends Object> {
  late WeakReference<T> _weakReference;
  _HashableWeakReference(T value) {
    _weakReference = WeakReference(value);
  }

  T? get target => _weakReference.target;

  @override
  bool operator ==(Object other) =>
      other is _HashableWeakReference<T> &&
      identical(_weakReference.target, other._weakReference.target);

  @override
  int get hashCode => _weakReference.target.hashCode;
}

class NewReactiveValue<T> {
  NewReactiveValue(this._value);

  T _value;
  final _subscribedElements = <_HashableWeakReference<Element>>{};

  /// Get the current value, and cause the [Element] passed as this
  /// [BuildContext] to subscribe to future changes in the value.
  T getAndSubscribe(BuildContext context) {
    _subscribedElements.add(_HashableWeakReference(context as Element));
    return _value;
  }

  /// Set the value, and notify subscribers if value changed.
  void set(T newValue) {
    // Don't allow mutating state during `build`
    // https://github.com/flutter/flutter/issues/128384#issuecomment-1580110349
    assert(
        SchedulerBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks,
        'Do not mutate state (by setting a ReactiveValue\'s value) '
        'during a `build` method. If you need to schedule an update, '
        'use `SchedulerBinding.instance.scheduleTask(task, Priority.idle)` '
        'or similar.');
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  /// Update the value based on current value, and notify subscribers
  /// if value changed.
  /// e.g. to increment: reactiveVal.update((v) => v + 1)
  void update(T Function(T) currValueToNextValue) {
    set(currValueToNextValue(_value));
  }

  /// You should manually invoke this method for deeper changes,
  /// e.g. when items are added to or removed from a set, as in
  /// ReactiveValue<Set<T>>
  void notifyListeners() {
    final liveSubscribedElements = <_HashableWeakReference<Element>>[];
    _subscribedElements.forEach((elementWeakRef) {
      // Skip elements that have already been garbage collected
      final element = elementWeakRef.target;
      if (element != null) {
        // For any subscribing elements that are still live, mark element
        // as needing to be rebuilt
        element.markNeedsBuild();
        // Remember elements that are still live
        liveSubscribedElements.add(elementWeakRef);
      }
    });
    // Remove any elements that have been garbage collected
    _subscribedElements.clear();
    _subscribedElements.addAll(liveSubscribedElements);
  }

  @override
  String toString() => '${describeIdentity(this)}($_value)';
}
