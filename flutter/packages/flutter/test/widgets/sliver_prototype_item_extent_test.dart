// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class TestItem extends StatelessWidget {
  const TestItem({ Key key, this.item, this.width, this.height }) : super(key: key);
  final int item;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Text('Item $item', textDirection: TextDirection.ltr),
    );
  }
}

Widget buildFrame({ int count, double width, double height, Axis scrollDirection }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: CustomScrollView(
      scrollDirection: scrollDirection ?? Axis.vertical,
      slivers: <Widget>[
        SliverPrototypeExtentList(
          prototypeItem: TestItem(item: -1, width: width, height: height),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => TestItem(item: index),
            childCount: count,
          ),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('SliverPrototypeExtentList vertical scrolling basics', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(count: 20, height: 100.0));

    // The viewport is 600 pixels high, lazily created items are 100 pixels high.
    for (int i = 0; i < 6; i += 1) {
      final Finder item = find.widgetWithText(Container, 'Item $i');
      expect(item, findsOneWidget);
      expect(tester.getTopLeft(item).dy, i * 100.0);
      expect(tester.getSize(item).height, 100.0);
    }
    for (int i = 7; i < 20; i += 1)
      expect(find.text('Item $i'), findsNothing);

    // Fling scroll to the end.
    await tester.fling(find.text('Item 2'), const Offset(0.0, -200.0), 5000.0);
    await tester.pumpAndSettle();

    for (int i = 19; i >= 14; i -= 1)
      expect(find.text('Item $i'), findsOneWidget);
    for (int i = 13; i >= 0; i -= 1)
      expect(find.text('Item $i'), findsNothing);
  });

  testWidgets('SliverPrototypeExtentList horizontal scrolling basics', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(count: 20, width: 100.0, scrollDirection: Axis.horizontal));

    // The viewport is 800 pixels wide, lazily created items are 100 pixels wide.
    for (int i = 0; i < 8; i += 1) {
      final Finder item = find.widgetWithText(Container, 'Item $i');
      expect(item, findsOneWidget);
      expect(tester.getTopLeft(item).dx, i * 100.0);
      expect(tester.getSize(item).width, 100.0);
    }
    for (int i = 9; i < 20; i += 1)
      expect(find.text('Item $i'), findsNothing);

    // Fling scroll to the end.
    await tester.fling(find.text('Item 3'), const Offset(-200.0, 0.0), 5000.0);
    await tester.pumpAndSettle();

    for (int i = 19; i >= 12; i -= 1)
      expect(find.text('Item $i'), findsOneWidget);
    for (int i = 11; i >= 0; i -= 1)
      expect(find.text('Item $i'), findsNothing);
  });

  testWidgets('SliverPrototypeExtentList change the prototype item', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(count: 10, height: 60.0));

    // The viewport is 600 pixels high, each of the 10 items is 60 pixels high
    for (int i = 0; i < 10; i += 1)
      expect(find.text('Item $i'), findsOneWidget);

    await tester.pumpWidget(buildFrame(count: 10, height: 120.0));

    // Now the items are 120 pixels high, so only 5 fit.
    for (int i = 0; i < 5; i += 1)
      expect(find.text('Item $i'), findsOneWidget);
    for (int i = 5; i < 10; i += 1)
      expect(find.text('Item $i'), findsNothing);

    await tester.pumpWidget(buildFrame(count: 10, height: 60.0));

    // Now they all fit again
    for (int i = 0; i < 10; i += 1)
      expect(find.text('Item $i'), findsOneWidget);
  });

  testWidgets('SliverPrototypeExtentList first item is also the prototype', (WidgetTester tester) async {
    final List<Widget> items = List<Widget>.generate(10, (int index) {
      return TestItem(key: ValueKey<int>(index), item: index, height: index == 0 ? 60.0 : null);
    }).toList();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPrototypeExtentList(
              prototypeItem: items[0],
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => items[index],
                childCount: 10,
              ),
            ),
          ],
        ),
      ),
    );

    // Item 0 exists in the list and as the prototype item.
    expect(tester.widgetList(find.text('Item 0', skipOffstage: false)).length, 2);

    for (int i = 1; i < 10; i += 1)
      expect(find.text('Item $i'), findsOneWidget);
  });
}
