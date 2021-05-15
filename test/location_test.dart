import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapd_demo/home.dart';



void main() {
  testWidgets('MyWidget has a title ', (WidgetTester tester) async {
    // Create the widget by telling the tester to build it.
    await tester.pumpWidget(MaterialApp(home: MyHomePage(title: 'Add new place at your current location')));

    // Create the Finders.
    final titleFinder = find.text('Add new place at your current location');

    // Use the `findsOneWidget` matcher provided by flutter_test to
    // verify that the Text widgets appear exactly once in the widget tree.
    expect(titleFinder, findsOneWidget);
  });
}