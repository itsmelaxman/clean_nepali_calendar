part of clean_nepali_calendar;

const Duration _kMonthScrollDuration = Duration(milliseconds: 200);

class _MonthView extends StatefulWidget {
  _MonthView({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
    required this.onDisplayedDateChanged,
    required this.pageToSelectedDate,
    this.onMonthChanged,
    required this.firstDate,
    required this.lastDate,
    required this.language,
    required this.calendarStyle,
    required this.headerStyle,
    this.selectableDayPredicate,
    this.onHeaderLongPressed,
    this.onHeaderTapped,
    this.dragStartBehavior = DragStartBehavior.start,
    this.headerDayType = HeaderDayType.initial,
    this.headerDayBuilder,
    this.dateCellBuilder,
    this.headerBuilder,
  }) : assert(!firstDate.isAfter(lastDate)),
       assert(!selectedDate.isBefore(firstDate)),
       assert(!selectedDate.isAfter(lastDate)),
       super(key: key);

  final NepaliDateTime selectedDate;

  final ValueChanged<NepaliDateTime> onChanged;
  final ValueChanged<NepaliDateTime> onDisplayedDateChanged;
  final bool pageToSelectedDate;
  final MonthChangedCallback? onMonthChanged;

  final NepaliDateTime firstDate;

  final NepaliDateTime lastDate;

  final SelectableDayPredicate? selectableDayPredicate;

  final DragStartBehavior dragStartBehavior;

  final Language language;

  final CalendarStyle calendarStyle;

  final HeaderStyle headerStyle;
  final HeaderGestureCallback? onHeaderTapped;
  final HeaderGestureCallback? onHeaderLongPressed;

  final HeaderDayType headerDayType;

  // build custom header
  final HeaderDayBuilder? headerDayBuilder;
  final DateCellBuilder? dateCellBuilder;
  final HeaderBuilder? headerBuilder;

  @override
  _MonthViewState createState() => _MonthViewState();
}

class _MonthViewState extends State<_MonthView>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _chevronOpacityTween = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).chain(CurveTween(curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    // Initially display the pre-selected date.
    final monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
    _dayPickerController = PageController(initialPage: monthPage);
    _handleMonthPageChanged(monthPage, notify: false);
    _updateCurrentDate();

    // Setup the fade animation for chevrons
    _chevronOpacityController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _chevronOpacityAnimation = widget.headerStyle.enableFadeTransition
        ? _chevronOpacityController.drive(_chevronOpacityTween)
        : _chevronOpacityController.drive(
            Tween<double>(
              begin: 1.0,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          );
  }

  @override
  void didUpdateWidget(_MonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.firstDate != oldWidget.firstDate) {
      final monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
      _jumpToMonthPage(monthPage);
      _handleMonthPageChanged(monthPage, notify: false);
    } else if (widget.pageToSelectedDate &&
        widget.selectedDate != oldWidget.selectedDate) {
      final monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
      _jumpToMonthPage(monthPage);
      _handleMonthPageChanged(monthPage, notify: false);
    }
  }

  TextDirection textDirection = TextDirection.ltr;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    textDirection = Directionality.of(context);
  }

  late NepaliDateTime _todayDate;
  late NepaliDateTime _currentDisplayedMonthDate;
  Timer? _timer;
  late PageController _dayPickerController;
  late AnimationController _chevronOpacityController;
  late Animation<double> _chevronOpacityAnimation;

  void _updateCurrentDate() {
    _todayDate = NepaliDateTime.now();
    final tomorrow = NepaliDateTime(
      _todayDate.year,
      _todayDate.month,
      _todayDate.day + 1,
    );
    var timeUntilTomorrow = tomorrow.difference(_todayDate);
    timeUntilTomorrow += const Duration(
      seconds: 1,
    ); // so we don't miss it by rounding
    _timer?.cancel();
    _timer = Timer(timeUntilTomorrow, () {
      setState(_updateCurrentDate);
    });
  }

  static int _monthDelta(NepaliDateTime startDate, NepaliDateTime endDate) {
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  NepaliDateTime _addMonthsToMonthDate(
    NepaliDateTime monthDate,
    int monthsToAdd,
  ) {
    int year = monthsToAdd ~/ 12;
    int months = monthDate.month + monthsToAdd % 12;
    if (months > 12) {
      year += months ~/ 12;
      months = months % 12;
    }
    return NepaliDateTime(monthDate.year + year, months);
  }

  Widget _buildItems(BuildContext context, int index) {
    final month = _addMonthsToMonthDate(widget.firstDate, index);
    return _DaysView(
      key: ValueKey<NepaliDateTime>(month),
      headerStyle: widget.headerStyle,
      calendarStyle: widget.calendarStyle,
      selectedDate: widget.selectedDate,
      currentDate: _todayDate,
      onChanged: widget.onChanged,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      displayedMonth: month,
      language: widget.language,
      selectableDayPredicate: widget.selectableDayPredicate,
      dragStartBehavior: widget.dragStartBehavior,
      headerDayType: widget.headerDayType,
      headerDayBuilder: widget.headerDayBuilder,
      dateCellBuilder: widget.dateCellBuilder,
    );
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
        "${formattedMonth(_nextMonthDate.month, Language.english)} ${_nextMonthDate.year}",
        textDirection,
      );
      _dayPickerController.nextPage(
        duration: _kMonthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
        "${formattedMonth(_previousMonthDate.month, Language.english)} ${_previousMonthDate.year}",
        textDirection,
      );
      _dayPickerController.previousPage(
        duration: _kMonthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  void _handleToday() {
    final today = NepaliDateTime.now();
    if (today.isBefore(widget.firstDate) || today.isAfter(widget.lastDate)) {
      return;
    }

    widget.onDisplayedDateChanged(today);
  }

  bool get _isDisplayingFirstMonth {
    return !_currentDisplayedMonthDate.isAfter(
      NepaliDateTime(widget.firstDate.year, widget.firstDate.month),
    );
  }

  bool get _isDisplayingLastMonth {
    return !_currentDisplayedMonthDate.isBefore(
      NepaliDateTime(widget.lastDate.year, widget.lastDate.month),
    );
  }

  late NepaliDateTime _previousMonthDate;
  late NepaliDateTime _nextMonthDate;

  double get _cellHeight => widget.dateCellBuilder == null
      ? _kDayPickerDefaultCellHeight
      : _kDayPickerDetailedCellHeight;

  double get _maxDayPickerHeight =>
      _kDayPickerHeaderHeight + (_cellHeight * (_kMaxDayPickerRowCount + 1));

  void _jumpToMonthPage(int monthPage) {
    if (_dayPickerController.hasClients) {
      _dayPickerController.jumpToPage(monthPage);
    } else {
      _dayPickerController.dispose();
      _dayPickerController = PageController(initialPage: monthPage);
    }
  }

  void _handleMonthPageChanged(int monthPage, {bool notify = true}) {
    late NepaliDateTime displayedMonth;
    setState(() {
      _previousMonthDate = _addMonthsToMonthDate(
        widget.firstDate,
        monthPage - 1,
      );
      displayedMonth = _addMonthsToMonthDate(widget.firstDate, monthPage);
      _currentDisplayedMonthDate = displayedMonth;
      _nextMonthDate = _addMonthsToMonthDate(widget.firstDate, monthPage + 1);
    });
    if (notify) {
      widget.onMonthChanged?.call(displayedMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxDayPickerHeight,
      child: Column(
        children: <Widget>[
          _CalendarHeader(
            onHeaderLongPressed: widget.onHeaderLongPressed,
            onHeaderTapped: widget.onHeaderTapped,
            language: widget.language,
            handleNextMonth: _handleNextMonth,
            handlePreviousMonth: _handlePreviousMonth,
            headerStyle: widget.headerStyle,
            chevronOpacityAnimation: _chevronOpacityAnimation,
            isDisplayingFirstMonth: _isDisplayingFirstMonth,
            previousMonthDate: _previousMonthDate,
            date: _currentDisplayedMonthDate,
            isDisplayingLastMonth: _isDisplayingLastMonth,
            nextMonthDate: _nextMonthDate,
            changeToToday: _handleToday,
            headerBuilder: widget.headerBuilder,
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                Semantics(
                  sortKey: _MonthPickerSortKey.calendar,
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: (_) {
                      _chevronOpacityController.forward();
                      return false;
                    },
                    child: NotificationListener<ScrollEndNotification>(
                      onNotification: (_) {
                        _chevronOpacityController.reverse();
                        return false;
                      },
                      child: PageView.builder(
                        dragStartBehavior: widget.dragStartBehavior,
                        controller: _dayPickerController,
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _monthDelta(widget.firstDate, widget.lastDate) + 1,
                        itemBuilder: _buildItems,
                        onPageChanged: _handleMonthPageChanged,
                      ),
                    ),
                  ),
                ),
                /*  PositionedDirectional(
                  top: 0.0,
                  start: 8.0,
                ), */
                /* PositionedDirectional(
                  top: 0.0,
                  end: 8.0,
                  child: 
                ), */
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dayPickerController.dispose();
    super.dispose();
  }
}

// Defines semantic traversal order of the top-level widgets inside the month
// picker.
class _MonthPickerSortKey extends OrdinalSortKey {
  const _MonthPickerSortKey(double order) : super(order);

  static const _MonthPickerSortKey previousMonth = _MonthPickerSortKey(1.0);
  static const _MonthPickerSortKey nextMonth = _MonthPickerSortKey(2.0);
  static const _MonthPickerSortKey calendar = _MonthPickerSortKey(3.0);
}
