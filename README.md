# `ReactiveWidget` and `ReactiveValue` for Flutter


## DEPRECATED

I am deprecating this library, because I found an even simpler (and much better) mechanism for creating reactive UIs in Flutter: please use the [`flutter_reactive_value`](https://github.com/lukehutch/flutter_reactive_value) library instead of this one.

The documentation and code for this `flutter_reactive_widget` library will still be hosted here, but this code will not see further development.

## Usage

This library provides a simple mechanism for creating a reactive UI in Flutter.

(1) Declare your state using `ReactiveValue<T>` (which extends [`ValueNotifier<T>`](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html)):

```dart
final counter = ReactiveValue<int>(0);
```

(2) Wrap any code that needs to react to changes to `counter.value` in a `ReactiveWidget` (which accepts a zero-arg lambda to be called by the `ReactiveWidget`'s `build` method).

If `counter.value` is read while the `ReactiveWidget`'s `build()` method is running, then the `ReactiveWidget` will start listening for changes to `counter.value`. (This listener is automatically removed if the widget is disposed.)

```dart
ReactiveWidget(
  () => Text('${counter.value}'),
),
```

(3) Any event handler that modifies `counter.value` will now trigger the `ReactiveWidget` to be re-built with the new value, by scheduling `setState` to be called on the `ReactiveWidget` in a post-frame callback.

```dart
IconButton(
  icon: const Icon(Icons.plus_one),
  onPressed: () {
    counter.value++;
  },
),
```

`counter.value` can be modifed from anywhere except for a `build` method (since `build` methods should never mutate state).

## Adding the library dependency

[`flutter_reactive_widget` is hosted on pub.dev](https://pub.dev/packages/flutter_reactive_widget).

To be able to import the library, you need to add a dependency upon it in `pubspec.yaml` (replace `any` with the latest version, if you want to control the version), then run `flutter pub get`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_reactive_widget: any
```

Import the library in your code:

```dart
import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
```

## `PersistentReactiveValue` subclass

`ReactiveValue` resets to its initial value every time the app is restarted. You can also persist values across app restarts by using `PersistentReactiveValue` rather than `ReactiveValue`.

First in `main`, you need to initialize `WidgetsFlutterBinding` and then you need to call `await initPersistentReactiveValue()` (defined in `flutter_reactive_widget.dart`), which starts `SharedPreferences` and loads any persisted values from the backing store.

```dart
main() async {
  // Both of the following lines are needed, in this order
  WidgetsFlutterBinding.ensureInitialized();
  await initPersistentReactiveValue();
  
  // Then run the app
  runApp(App());
}
```

Then you can use  `PersistentReactiveValue` rather than `ReactiveValue`:

```dart
final counter = PersistentReactiveValue<int>(
      /* key */ 'counter', /* defaultValue */ 0);
```

`counter.value` will be set to the default value `0` if it has never been set before, but if it has been set before in a previous run of the app, the previous value will be recovered from `SharedPreferences`, using the key `'counter'`.

Whenever `counter.value` is set in future, not only is any wrapping `ReactiveWidget` updated, but the new value is asynchronously written through to the `SharedPreferences` persistence cache, using the same key.

## `PersistentReactiveNullableValue` subclass

Note that for `PersistentReactiveValue<T>`, `T` cannot be a nullable type (`T?`), since null values cannot be distinguished from a value not being present in `SharedPreferences`.

If you want to be able to "store" null values in SharedPreferences (which amounts to removing the key from `SharedPreferences` if you try to set a null value), then use `PersistentReactiveNullableValue<T?>`. For this class, `defaultValue` is optional.

## `ValidatingReactiveValue` subclass

The `ValidatingReactiveValue` subclass of `ReactiveValue` has an additional field, `validationError`, which is itself a `ReactiveValue<String?>`. This field is updated whenever the `ValidatingReactiveValue`'s value changes, by calling the `validate` function that is passed into the `ValidatingReactiveValue` constructor. For example:

```dart
final age = ValidatingReactiveValue<int?>(null,
        (a) => a == null ? 'Please specify age' : null);

// You can now listen to either `age.validationError` or `age.value` in a `ReactiveWidget`.
```

## Manually notifying listeners of deeper changes to value

If you create `final set = ReactiveValue<Set<String>>({});` and then you call `set.value.add('abc')`, `set`'s listeners will not be notified of the change, because the reference to the set itself (i.e. `set.value`) has not changed. You can manually call listeners in this case by doing something like:

```dart
_addFlag(bool flag) {
  bool changed = flag ? set.value.add('flag') : set.value.remove('flag');
  if (changed) {
    set.notifyListeners();
  }
}
```

## Removing `ReactiveValue` listeners in `StatefulWidget`s' `State.dispose()` method

If you are instantiating a `ReactiveValue` in a field of a `StatefulWidget`'s `State<T>` object, make sure your `State<T>`'s `dispose()` method calls the `ReactiveValue`'s `dispose()` method to remove all listeners when the widget is disposed, in order to prevent memory leaks.

## Lifecycle, and where to store state

If you want a `ReactiveValue`'s to exist for the lifetime of the app, there are good suggestions in [this Medium post](https://suragch.medium.com/flutter-state-management-for-minimalists-4c71a2f2f0c1) about how to use [`GetIt`](https://pub.dev/packages/get_it) to organize state in your application. Applying that idea to `flutter_reactive_widget`:

#### `main.dart`

Call `setUpGetIt()` from `main`:

```dart
import 'package:my_app/pages/home_page.dart';
import './service_locator.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initPersistentReactiveValue();

  // Register state singletons (defined in service_locator.dart)
  setUpGetIt();

  runApp(HomePage());
}
```

#### `service_locator.dart`

Register all your state-containing classes as singletons using `GetIt`, with one state class per page (i.e. create `home_page_state.dart` for page `home_page.dart`):

```dart
import 'package:my_app/pages/home_page_state.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setUpGetIt() {
  getIt.registerLazySingleton<HomePageState>(() => HomePageState());
}
```

#### `pages/home_page_state.dart`

Define each state class:

```dart
import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';

/// The persistent state of [HomePage]
class HomePageState {
  final count = PersistentReactiveValue<int>('count', 0);
}
```

#### `pages/home_page.dart`

Get the state singleton class instance(s) you need to read state from, using `GetIt.instance<T>()` (or `getIt<T>`, if you import `service_locator.dart`):

```dart
import 'package:my_app/pages/home_page_state.dart';
import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
import 'package:flutter/material.dart';
import './service_locator.dart';

// Get the state of the page
final _homePageState = getIt<HomePageState>();

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeView'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ReactiveWidget(
            () => Text(
              '${_homePageState.count.value}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.plus_one),
            onPressed: () {
              _homePageState.count.value++;
            },
          ),
        ],
      ),
    );
  }
}
```

## Author

`flutter_reactive_widget` was written by Luke Hutchison, and is released under the MIT license.
