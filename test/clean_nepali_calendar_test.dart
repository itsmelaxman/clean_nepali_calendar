import 'package:clean_nepali_calendar/clean_nepali_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Gregorian month span independently of custom title', (
    tester,
  ) async {
    final controller = NepaliCalendarController();
    final initialDate = NepaliDateTime(2080, 9);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: controller,
            initialDate: initialDate,
            firstDate: NepaliDateTime(2079),
            lastDate: NepaliDateTime(2081, 12),
            enableVibration: false,
            headerStyle: HeaderStyle(
              titleTextBuilder: (_, __) => 'Custom title',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Custom title'), findsOneWidget);
    expect(find.text(gregorianMonthSpanLabel(initialDate)), findsOneWidget);
  });

  testWidgets('allows initial date to be the first selectable date', (
    tester,
  ) async {
    final firstDate = NepaliDateTime(2080, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: NepaliCalendarController(),
            initialDate: firstDate,
            firstDate: firstDate,
            lastDate: NepaliDateTime(2080, 12),
            enableVibration: false,
          ),
        ),
      ),
    );

    expect(find.byType(CleanNepaliCalendar), findsOneWidget);
  });

  testWidgets('sizes calendar to visible month rows', (tester) async {
    final initialDate = NepaliDateTime(2083, 3);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CleanNepaliCalendar(
                controller: NepaliCalendarController(),
                initialDate: initialDate,
                firstDate: NepaliDateTime(2083, 1),
                lastDate: NepaliDateTime(2083, 12),
                enableVibration: false,
              ),
              const Text('hello'),
            ],
          ),
        ),
      ),
    );

    final expectedCalendarHeight = calendarHeightForMonth(initialDate);

    expect(
      tester.getSize(find.byType(CleanNepaliCalendar)).height,
      expectedCalendarHeight,
    );
    expect(tester.getTopLeft(find.text('hello')).dy, expectedCalendarHeight);
  });

  testWidgets('clamps initial date to configured date range', (tester) async {
    final controller = NepaliCalendarController();
    final firstDate = NepaliDateTime(2080, 1, 1);
    final lastDate = NepaliDateTime(2080, 12, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: controller,
            initialDate: NepaliDateTime(2079, 12, 1),
            firstDate: firstDate,
            lastDate: lastDate,
            language: Language.english,
            enableVibration: false,
          ),
        ),
      ),
    );

    expect(controller.selectedDay, firstDate);
    expect(find.text(nepaliMonthHeader(2080, 1)), findsOneWidget);
  });

  testWidgets('clamps programmatic selected date to configured date range', (
    tester,
  ) async {
    final controller = NepaliCalendarController();
    final firstDate = NepaliDateTime(2080, 1, 1);
    final lastDate = NepaliDateTime(2080, 12, 1);
    var selectedDays = <NepaliDateTime>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: controller,
            initialDate: firstDate,
            firstDate: firstDate,
            lastDate: lastDate,
            language: Language.english,
            enableVibration: false,
            onDaySelected: selectedDays.add,
          ),
        ),
      ),
    );

    controller.setSelectedDay(NepaliDateTime(2081, 1, 1), runCallback: true);
    await tester.pumpAndSettle();

    expect(controller.selectedDay, lastDate);
    expect(selectedDays, [lastDate]);
    expect(find.text(nepaliMonthHeader(2080, 12)), findsOneWidget);
  });

  testWidgets('parent rebuild does not reset selected day to initial date', (
    tester,
  ) async {
    final controller = NepaliCalendarController();
    final initialDate = NepaliDateTime(2080, 1, 1);
    final selectedDate = NepaliDateTime(2080, 1, 3);
    late StateSetter rebuildParent;
    var rebuildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return Column(
                children: [
                  Text('rebuild $rebuildCount'),
                  CleanNepaliCalendar(
                    controller: controller,
                    initialDate: initialDate,
                    firstDate: initialDate,
                    lastDate: NepaliDateTime(2080, 12),
                    enableVibration: false,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    controller.setSelectedDay(selectedDate);
    await tester.pump();

    rebuildParent(() {
      rebuildCount += 1;
    });
    await tester.pump();

    expect(controller.selectedDay, selectedDate);
  });

  testWidgets('tapping a day after scrolling keeps the displayed month', (
    tester,
  ) async {
    final controller = NepaliCalendarController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: controller,
            initialDate: NepaliDateTime(2080, 1, 1),
            firstDate: NepaliDateTime(2080, 1, 1),
            lastDate: NepaliDateTime(2080, 12),
            language: Language.english,
            enableVibration: false,
          ),
        ),
      ),
    );

    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();

    final jesthaHeader = nepaliMonthHeader(2080, 2);
    expect(find.text(jesthaHeader), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text(jesthaHeader), findsOneWidget);

    controller.setSelectedDay(NepaliDateTime(2080, 1, 1));
    await tester.pumpAndSettle();

    expect(find.text(nepaliMonthHeader(2080, 1)), findsOneWidget);
  });

  testWidgets('today action selects today and pages to today month', (
    tester,
  ) async {
    final today = NepaliDateTime.now();
    final initialDate = addNepaliMonths(today, -1);
    final controller = NepaliCalendarController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: controller,
            initialDate: initialDate,
            firstDate: initialDate,
            lastDate: addNepaliMonths(today, 1),
            language: Language.english,
            enableVibration: false,
          ),
        ),
      ),
    );

    expect(find.text(nepaliMonthHeader(today.year, today.month)), findsNothing);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(
      find.text(nepaliMonthHeader(today.year, today.month)),
      findsOneWidget,
    );
    expect(controller.selectedDay?.year, today.year);
    expect(controller.selectedDay?.month, today.month);
    expect(controller.selectedDay?.day, today.day);
  });

  testWidgets('today action does nothing when today is outside date range', (
    tester,
  ) async {
    final initialDate = NepaliDateTime(2070, 1, 1);
    final controller = NepaliCalendarController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: controller,
            initialDate: initialDate,
            firstDate: initialDate,
            lastDate: NepaliDateTime(2070, 12),
            language: Language.english,
            enableVibration: false,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text(nepaliMonthHeader(2070, 1)), findsOneWidget);
    expect(controller.selectedDay, initialDate);
  });

  testWidgets(
      'onMonthChanged does not fire on initial build but fires on swipe and chevron navigation',
      (
    tester,
  ) async {
    final controller = NepaliCalendarController();
    final initialDate = NepaliDateTime(2080, 1, 1);
    var monthChanges = <NepaliDateTime>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: controller,
            initialDate: initialDate,
            firstDate: initialDate,
            lastDate: NepaliDateTime(2080, 12),
            language: Language.english,
            enableVibration: false,
            onMonthChanged: monthChanges.add,
          ),
        ),
      ),
    );

    expect(monthChanges, isEmpty);

    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();

    expect(monthChanges.length, 1);
    expect(monthChanges.first.month, initialDate.month + 1);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(monthChanges.length, 2);
    expect(monthChanges.last.month, initialDate.month + 2);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(monthChanges.length, 3);
    expect(monthChanges.last.month, initialDate.month + 1);
  });

  testWidgets(
      'sizes calendar with detailed cell height when dateCellBuilder is provided',
      (
    tester,
  ) async {
    final initialDate = NepaliDateTime(2083, 3);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanNepaliCalendar(
            controller: NepaliCalendarController(),
            initialDate: initialDate,
            firstDate: NepaliDateTime(2083, 1),
            lastDate: NepaliDateTime(2083, 12),
            enableVibration: false,
            dateCellBuilder:
                (_, __, ___, ____, _____, ______, _______, ________) =>
                    Container(),
          ),
        ),
      ),
    );

    final dayRows =
        ((initialDate.weekday - 1 + initialDate.totalDays) / 7).ceil();
    final expectedCalendarHeight = 56.0 + 52.0 * (dayRows + 1);

    expect(
      tester.getSize(find.byType(CleanNepaliCalendar)).height,
      expectedCalendarHeight,
    );
  });

  testWidgets('old controller is detached after controller replacement', (
    tester,
  ) async {
    final oldController = NepaliCalendarController();
    final newController = NepaliCalendarController();
    final initialDate = NepaliDateTime(2080, 1, 1);
    var useNewController = false;
    var selectedDays = <NepaliDateTime>[];
    late StateSetter rebuildParent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return CleanNepaliCalendar(
                controller: useNewController ? newController : oldController,
                initialDate: initialDate,
                firstDate: initialDate,
                lastDate: NepaliDateTime(2080, 12),
                enableVibration: false,
                onDaySelected: selectedDays.add,
              );
            },
          ),
        ),
      ),
    );

    rebuildParent(() {
      useNewController = true;
    });
    await tester.pump();

    oldController.setSelectedDay(NepaliDateTime(2080, 1, 2), runCallback: true);
    await tester.pump();

    expect(selectedDays, isEmpty);
    expect(newController.selectedDay, initialDate);
  });
}

String nepaliMonthHeader(int year, int month) {
  final monthName = NepaliDateFormat.MMMM(
    Language.english,
  ).format(NepaliDateTime(1970, month));

  return '$monthName - $year';
}

NepaliDateTime addNepaliMonths(NepaliDateTime date, int monthDelta) {
  var year = date.year;
  var month = date.month + monthDelta;
  while (month < 1) {
    year -= 1;
    month += 12;
  }
  while (month > 12) {
    year += 1;
    month -= 12;
  }

  return NepaliDateTime(year, month);
}

String gregorianMonthSpanLabel(NepaliDateTime date) {
  final firstGregorianDate = NepaliDateTime(date.year, date.month).toDateTime();
  final lastGregorianDate = NepaliDateTime(
    date.year,
    date.month,
    date.totalDays,
  ).toDateTime();
  final yearLabel = firstGregorianDate.year == lastGregorianDate.year
      ? '${firstGregorianDate.year}'
      : '${firstGregorianDate.year}/${lastGregorianDate.year}';

  return '${englishMonth(firstGregorianDate.month)}/${englishMonth(lastGregorianDate.month)} - $yearLabel';
}

double calendarHeightForMonth(NepaliDateTime date) {
  final dayRows = ((date.weekday - 1 + date.totalDays) / 7).ceil();
  const headerHeight = 56.0;
  const defaultCellHeight = 40.0;
  return headerHeight + defaultCellHeight * (dayRows + 1);
}

String englishMonth(int month) {
  const names = {
    DateTime.january: 'Jan',
    DateTime.february: 'Feb',
    DateTime.march: 'Mar',
    DateTime.april: 'April',
    DateTime.may: 'May',
    DateTime.june: 'Jun',
    DateTime.july: 'Jul',
    DateTime.august: 'Aug',
    DateTime.september: 'Sep',
    DateTime.october: 'Oct',
    DateTime.november: 'Nov',
    DateTime.december: 'Dec',
  };

  return names[month]!;
}
