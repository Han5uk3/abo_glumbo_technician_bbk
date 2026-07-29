import 'package:aboglumbo_bbk_panel/services/time_service.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HorizontalDateRangePicker extends StatefulWidget {
  const HorizontalDateRangePicker({super.key});

  @override
  State<HorizontalDateRangePicker> createState() =>
      _HorizontalDateRangePickerState();
}

class _HorizontalDateRangePickerState extends State<HorizontalDateRangePicker> {
  late PageController _pageController;
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSelectingEnd = false;
  String _locale = 'en';

  @override
  void initState() {
    super.initState();
    // The calendar grid is a Saudi calendar: which day counts as "today", and
    // therefore which days are greyed out as future, must not depend on where
    // the admin happens to be.
    _currentMonth = KsaTime.now;
    // Start with current month (index ~1200)
    _pageController = PageController(initialPage: 1200);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).languageCode;
    // Initialize date formatting for the current locale
    initializeDateFormatting(_locale, null);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getMonthForPage(int page) {
    final now = KsaTime.now;
    final offset = page - 1200;
    return DateTime(now.year, now.month + offset, 1);
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start new selection
        _startDate = date;
        _endDate = null;
        _isSelectingEnd = true;
      } else if (_isSelectingEnd) {
        // Complete selection
        if (date.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
        _isSelectingEnd = false;
      }
    });
  }

  bool _isInRange(DateTime date) {
    if (_startDate == null) return false;
    if (_endDate == null) return _isSameDay(date, _startDate!);

    return (date.isAfter(_startDate!) || _isSameDay(date, _startDate!)) &&
        (date.isBefore(_endDate!) || _isSameDay(date, _endDate!));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isStartDate(DateTime date) {
    return _startDate != null && _isSameDay(date, _startDate!);
  }

  bool _isEndDate(DateTime date) {
    return _endDate != null && _isSameDay(date, _endDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primary],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.selectDateRange,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          tooltip: AppLocalizations.of(context)!.close,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.startDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _startDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                        _locale,
                                      ).format(_startDate!)
                                    : AppLocalizations.of(context)!.notSelected,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.endDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _endDate != null
                                    ? DateFormat(
                                        'MMM dd, yyyy',
                                        _locale,
                                      ).format(_endDate!)
                                    : AppLocalizations.of(context)!.notSelected,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Month navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.chevron_left, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', _locale).format(_currentMonth),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.chevron_right, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Weekday headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _getLocalizedWeekdays().map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF6366F1).withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Calendar grid with horizontal swipe
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentMonth = _getMonthForPage(page);
                  });
                },
                itemBuilder: (context, page) {
                  final month = _getMonthForPage(page);
                  return _buildMonthGrid(month);
                },
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _isSelectingEnd = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.clear,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _startDate != null && _endDate != null
                          ? () {
                              Navigator.pop(
                                context,
                                DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.apply,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;

    final now = KsaTime.now;
    final today = KsaTime.today;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 42,
        itemBuilder: (context, index) {
          final dayOffset = index - startWeekday;

          if (dayOffset < 0 || dayOffset >= daysInMonth) {
            return const SizedBox();
          }

          final date = DateTime(month.year, month.month, dayOffset + 1);
          final isToday = _isSameDay(date, today);
          final isInRange = _isInRange(date);
          final isStart = _isStartDate(date);
          final isEnd = _isEndDate(date);
          final isFuture = date.isAfter(now);

          return GestureDetector(
            onTap: isFuture ? null : () => _onDateSelected(date),
            child: Container(
              decoration: BoxDecoration(
                gradient: (isStart || isEnd)
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: (isStart || isEnd)
                    ? null
                    : isInRange
                    ? AppColors.primary.withOpacity(0.15)
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: isToday
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: (isStart || isEnd)
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${dayOffset + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: (isStart || isEnd || isToday)
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: (isStart || isEnd)
                        ? Colors.white
                        : isFuture
                        ? Colors.grey.shade400
                        : isInRange
                        ? AppColors.primary
                        : const Color(0xFF1F2937),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getLocalizedWeekdays() {
    if (_locale == 'ar') {
      // Arabic weekday abbreviations (starting from Sunday)
      return ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
    } else {
      // English weekday abbreviations (starting from Sunday)
      return ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    }
  }
}
