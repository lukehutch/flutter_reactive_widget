# `ReactiveWidget` and `ReactiveValue` for Flutter

Simple state management / reactive state tracking for Flutter, reducing the boilerplate compared to the insanely complex [state management approaches](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options) that are in common use.

## Usage

Import the library:

```dart
import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
```

Declare your state using `StatefulValue<T>` (which extends [`ValueNotifier<T>`](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html)):

```dart
final counter = ReactiveValue<int>(0);
```

Then simply wrap any code that reads `counter.value` in a `ReactiveWidget`:

```dart
ReactiveWidget(
  (BuildContext context) => Text(
    '${counter.value}',
    style: const TextStyle(fontSize: 20),
  ),
),
```

Any event handler that modifies `counter.value` will now trigger the `ReactiveWidget` to be re-built with the new value.

## Persistent `ReactiveValue` subclass

You can also persist values across app restarts by using `PersistentReactiveValue` rather than `ReactiveValue`:

```dart
final counter = PersistentReactiveValue<int>(/* key */ "counter", /* defaultValue */ 0);
```

Here `"counter" is used as a unique key to store the value in `SharedPreferences`. Initially `counter.value` will be set to the default value `0`, but then asynchronously, the key `counter` is looked up in `SharedPreferences`, and if present, `counter.value` is updated to the persisted value. (There may be a "flash of unstyled content" as `counter.value` is updated from the default value to the persisted value, since the `SharedPreferences` API is asynchronous.) Subsequently, whenever `counter.value` is updated, not only is any wrapping `ReactiveWidget` updated, but the new value is asynchronously written through to the `SharedPreferences` persistence cache.
