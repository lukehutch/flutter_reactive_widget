# `ReactiveWidget` and `ReactiveValue` for Flutter

Simple state management / reactive state tracking for Flutter, reducing the boilerplate compared to the insanely complex [state management approaches](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options) that are in common use.

## Usage

Import the library:

```dart
import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
```

Declare your state using `ReactiveValue<T>` (which extends [`ValueNotifier<T>`](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html)):

```dart
final counter = ReactiveValue<int>(0);
```

Then simply wrap any code that reads `counter.value` in a `ReactiveWidget`:

```dart
ReactiveWidget(
  () => Text(
    '${counter.value}',
    style: const TextStyle(fontSize: 20),
  ),
),
```

The mere reference to `counter.value` within this `ReactiveWidget` causes this `ReactiveWidget` to start listening for changes to `counter.value`. (This listener is automatically removed if the widget is disposed.)

Any event handler that modifies `counter.value` will now trigger the `ReactiveWidget` to be re-built with the new value.

## Persistent `ReactiveValue` subclass

You can also persist values across app restarts by using `PersistentReactiveValue` rather than `ReactiveValue`.

First in `main`, initialize `PersistentReactiveValue` (which loads cached values from the backing store).

```dart
main() async {
  await PersistentReactiveValue.init();
  runApp(App());
}
```

Then you can use  `PersistentReactiveValue` rather than `ReactiveValue`:

```dart
final counter = PersistentReactiveValue<int>(/* key */ "counter", /* defaultValue */ 0);
```

`counter.value` will be set to the default value `0` if it has never been set before, but if it has been set before in a previous run of the app, the previous value will be recovered from `SharedPreferences`, using the key `"counter"`.

Whenever `counter.value` is set in future, not only is any wrapping `ReactiveWidget` updated, but the new value is asynchronously written through to the `SharedPreferences` persistence cache, using the same key.

## Where to store state

There are good suggestions in [this Medium post](https://suragch.medium.com/flutter-state-management-for-minimalists-4c71a2f2f0c1) about how to use [`GetIt`](https://pub.dev/packages/get_it) to organize state in your application. Applying that idea to `flutter_reactive_widget`:

#### `main.dart`:

```dart
import './service_locator.dart';

main() async {
  await PersistentReactiveValue.init();
  setUpGetIt();
  runApp(App());
}
```

#### `service_locator.dart`:

```dart
import 'package:my_app/pages/home_page_state.dart';
import 'package:get_it/get_it.dart';

void setUpGetIt() {
  // Register all your state classes here, one per stateful page
  GetIt.instance.registerLazySingleton<HomePageState>(() => HomePageState());
}
```

#### `pages/home_page_state.dart`:

```dart
import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';

/// The persistent state of [HomePage]
class HomePageState {
  final count = PersistentReactiveValue<int>('count', 0);
}
```

#### `pages/home_page.dart`:

```dart
import 'package:my_app/pages/home_page_state.dart';
import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// Get the state of the page
final _homePageState = GetIt.instance<HomePageState>();

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