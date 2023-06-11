### 1.0.9

I am deprecating this library, because I found an even simpler (and much better) mechanism for creating reactive UIs in Flutter: please use the [`flutter_reactive_value`](https://github.com/lukehutch/flutter_reactive_value) library instead of this one.

### 1.0.8

Disallow setting of `ReactiveValue.value` from build method:

https://github.com/flutter/flutter/issues/128384#issuecomment-1580110349

### 1.0.7

Further updates to fix #5.

### 1.0.6

(Ignore -- use 1.0.7)

### 1.0.5

Fix issue where reactive widget would not update in async context (#5).

### 1.0.4

Check if widget is mounted before calling `setState` (fixes #3).

### 1.0.3

Allow `ReactiveWidget`s to be nested.

### 1.0.2

Updated docs (no functionality changes).

### 1.0.1

Updated docs (no functionality changes).

### 1.0.0

First pub.dev release.