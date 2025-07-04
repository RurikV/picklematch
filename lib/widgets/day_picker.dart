import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayPicker extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DayPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  _DayPickerState createState() => _DayPickerState();
}

class _DayPickerState extends State<DayPicker> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final int _daysToShow = 7;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize page controller
    _pageController = PageController(
      initialPage: 1, // Start with the middle page (current week)
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    // Reset to middle page
    if (page != 1) {
      Future.delayed(Duration.zero, () {
        _pageController.jumpToPage(1);
      });
    }
  }

  void _selectDate(DateTime date) {
    widget.onDateSelected(date);
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != widget.selectedDate) {
      _selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date header with month and year
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _showDatePicker,
              tooltip: 'Select Date',
            ),
            Text(
              DateFormat('MMMM yyyy').format(widget.selectedDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: () => _selectDate(DateTime.now()),
              tooltip: 'Today',
            ),
          ],
        ),

        // Day picker
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, pageIndex) {
              // Calculate offset for this page
              final pageOffset = (pageIndex - 1) * _daysToShow;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_daysToShow, (index) {
                  // Calculate date for this index
                  final date = widget.selectedDate.add(
                    Duration(days: pageOffset + index - (widget.selectedDate.weekday - 1)),
                  );

                  final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
                  final isToday = DateUtils.isSameDay(date, DateTime.now());

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(date),
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : isToday
                                      ? Theme.of(context).primaryColor.withAlpha(51) // 0.2 * 255 = 51
                                      : null,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isToday && !isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('E').format(date).substring(0, 1),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              );
            },
            itemCount: 3, // Previous, current, next week
          ),
        ),
      ],
    );
  }
}
