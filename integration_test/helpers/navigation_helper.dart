import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_config.dart';

/// Helper for navigating between screens in integration tests.
class NavigationHelper {
  final WidgetTester tester;

  NavigationHelper(this.tester);

  /// Navigates to a route by tapping on a sidebar/menu item with the given label.
  Future<void> navigateToMenuItem(String label) async {
    final menuItem = find.text(label);
    if (menuItem.evaluate().isNotEmpty) {
      await tester.tap(menuItem.first);
      await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
    }
  }

  /// Taps a button with the given text.
  Future<void> tapButton(String text) async {
    final button = find.text(text);
    expect(button, findsWidgets);
    await tester.tap(button.first);
    await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
  }

  /// Fills a text field identified by its label or hint.
  Future<void> fillField(String labelOrHint, String value) async {
    final field = find.byWidgetPredicate((widget) {
      if (widget is TextField) {
        return widget.decoration?.labelText == labelOrHint ||
            widget.decoration?.hintText == labelOrHint;
      }
      if (widget is TextFormField) {
        return false; // TextFormField wraps InputDecorator differently
      }
      return false;
    });

    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field.first, value);
    }
  }

  /// Scrolls down within the current scrollable widget.
  Future<void> scrollDown({double pixels = 300}) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byType(SizedBox).last,
      pixels,
      scrollable: scrollable,
    );
  }

  /// Waits for the page to settle after an action.
  Future<void> waitForSettle() async {
    await tester.pumpAndSettle(TestConfig.pumpSettleDuration);
  }
}
