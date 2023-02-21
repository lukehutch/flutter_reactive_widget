import 'package:flutter_reactive_widget/flutter_reactive_widget.dart';

/// A [ReactiveValue] that updates its `validationError` field whenever its
/// value changes, by calling the `validate` function. You can listen for
/// changes in `validationError` separately from listening to this
/// `ReactiveValue`.
class ValidatingReactiveValue<T> extends ReactiveValue<T> {
  ValidatingReactiveValue(super.value, this.validate) {
    // Perform initial validation of default value
    _validate();
  }

  /// Returns null if the value is valid, otherwise an error string.
  final String? Function(T newValue) validate;

  /// If value is null, last set of value had a valid value, according to the
  /// `validate` function.
  final validationError = ReactiveValue<String?>(null);

  _validate() {
    validationError.value = validate(value);
  }

  @override
  void notifyListeners() {
    // Re-validate on change notification
    _validate();
    super.notifyListeners();
  }

  @override
  dispose() {
    validationError.dispose();
    super.dispose();
  }
}
