part of clean_nepali_calendar;

typedef TextBuilder = String Function(NepaliDateTime date, Language language);
typedef HeaderGestureCallback = void Function(NepaliDateTime focusedDay);
typedef MonthChangedCallback = void Function(NepaliDateTime focusedMonth);

String formattedMonth(int month, [Language? language]) =>
    NepaliDateFormat.MMMM(language).format(NepaliDateTime(1970, month));

int _dayPickerRowCount(NepaliDateTime month, {required bool renderDaysOfWeek}) {
  final dayRows = ((month.weekday - 1 + month.totalDays) / 7).ceil();
  return dayRows + (renderDaysOfWeek ? 1 : 0);
}

class CleanNepaliCalendar extends StatefulWidget {
  const CleanNepaliCalendar({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.language = Language.nepali,
    this.onDaySelected,
    this.onMonthChanged,
    this.headerStyle = const HeaderStyle(),
    this.calendarStyle = const CalendarStyle(),
    this.onHeaderTapped,
    this.onHeaderLongPressed,
    required this.controller,
    this.headerDayType = HeaderDayType.initial,
    this.headerDayBuilder,
    this.dateCellBuilder,
    this.enableVibration = true,
    this.headerBuilder,
  });

  final NepaliDateTime? initialDate;
  final NepaliDateTime? firstDate;
  final NepaliDateTime? lastDate;
  final Function(NepaliDateTime)? onDaySelected;
  final MonthChangedCallback? onMonthChanged;
  final SelectableDayPredicate? selectableDayPredicate;
  final Language language;
  final CalendarStyle calendarStyle;
  final HeaderStyle headerStyle;
  final HeaderGestureCallback? onHeaderTapped;
  final HeaderGestureCallback? onHeaderLongPressed;
  final NepaliCalendarController controller;
  final HeaderDayType headerDayType;
  final HeaderDayBuilder? headerDayBuilder;
  final DateCellBuilder? dateCellBuilder;
  final HeaderBuilder? headerBuilder;
  final bool enableVibration;

  @override
  CleanNepaliCalendarState createState() => CleanNepaliCalendarState();
}

class CleanNepaliCalendarState extends State<CleanNepaliCalendar> {
  @override
  void initState() {
    super.initState();
    _selectedDate = _clampDateToRange(
      widget.initialDate ?? NepaliDateTime.now(),
    );
    widget.controller._init(
      selectedDayCallback: _handleDayChanged,
      initialDay: _selectedDate,
    );
  }

  bool _announcedInitialDate = false;

  late MaterialLocalizations localizations;
  late TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.sendAnnouncement(
        View.of(context),
        NepaliDateFormat.yMMMMd().format(_selectedDate),
        textDirection,
      );
    }
  }

  @override
  void didUpdateWidget(CleanNepaliCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller._dispose();
      widget.controller._init(
        selectedDayCallback: _handleDayChanged,
        initialDay: _selectedDate,
      );
    }

    final dateRangeChanged =
        widget.firstDate != oldWidget.firstDate ||
        widget.lastDate != oldWidget.lastDate;
    final initialDateChanged =
        widget.initialDate != null &&
        widget.initialDate != oldWidget.initialDate;
    if (initialDateChanged || dateRangeChanged) {
      final selectedDate = initialDateChanged
          ? _clampDateToRange(widget.initialDate!)
          : _clampDateToRange(_selectedDate);
      setState(() {
        _selectedDate = selectedDate;
        _pageToSelectedDate = true;
      });
      widget.controller.setSelectedDay(_selectedDate, isProgrammatic: false);
    }
  }

  late NepaliDateTime _selectedDate;
  bool _pageToSelectedDate = true;
  final GlobalKey _pickerKey = GlobalKey();

  void _vibrate() {
    HapticFeedback.vibrate();
  }

  NepaliDateTime get _firstDate => widget.firstDate ?? NepaliDateTime(2000, 1);

  NepaliDateTime get _lastDate => widget.lastDate ?? NepaliDateTime(2095, 12);

  NepaliDateTime _clampDateToRange(NepaliDateTime date) {
    if (date.isBefore(_firstDate)) {
      return _firstDate;
    }
    if (date.isAfter(_lastDate)) {
      return _lastDate;
    }

    return date;
  }

  void _handleDayChanged(
    NepaliDateTime value, {
    bool runCallback = true,
    bool pageToSelectedDate = true,
  }) {
    final selectedDate = _clampDateToRange(value);
    if (widget.enableVibration) _vibrate();
    setState(() {
      widget.controller.setSelectedDay(selectedDate, isProgrammatic: false);
      _selectedDate = selectedDate;
      _pageToSelectedDate = pageToSelectedDate;
    });
    if (runCallback && widget.onDaySelected != null) {
      widget.onDaySelected!(selectedDate);
    }
  }

  Widget _buildPicker() {
    return _MonthView(
      key: _pickerKey,
      headerStyle: widget.headerStyle,
      calendarStyle: widget.calendarStyle,
      language: widget.language,
      selectedDate: _selectedDate,
      onChanged: (value) {
        _handleDayChanged(value, pageToSelectedDate: false);
      },
      onDisplayedDateChanged: _handleDayChanged,
      pageToSelectedDate: _pageToSelectedDate,
      onMonthChanged: widget.onMonthChanged,
      firstDate: _firstDate,
      lastDate: _lastDate,
      selectableDayPredicate: widget.selectableDayPredicate,
      onHeaderTapped: widget.onHeaderTapped,
      onHeaderLongPressed: widget.onHeaderLongPressed,
      headerDayType: widget.headerDayType,
      headerDayBuilder: widget.headerDayBuilder,
      dateCellBuilder: widget.dateCellBuilder,
      headerBuilder: widget.headerBuilder,
      dragStartBehavior: DragStartBehavior.start,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPicker();
  }

  @override
  void dispose() {
    widget.controller._dispose();
    super.dispose();
  }
}

typedef SelectableDayPredicate = bool Function(NepaliDateTime day);
