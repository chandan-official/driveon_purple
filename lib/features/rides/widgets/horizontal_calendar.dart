import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/color_constants.dart';

class HorizontalCalendar extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const HorizontalCalendar({Key? key, required this.onDateSelected})
    : super(key: key);

  @override
  _HorizontalCalendarState createState() => _HorizontalCalendarState();
}

class _HorizontalCalendarState extends State<HorizontalCalendar> {
  DateTime _selectedDate = DateTime.now();
  final int _daysToShow = 14; // Show next 2 weeks

  @override
  void initState() {
    super.initState();
    // Reset time to 00:00:00 for accurate comparison
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "When are you going?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80, // Height of the strip
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _daysToShow,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              // Normalize date for comparison
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final isSelected = normalizedDate.isAtSameMomentAs(_selectedDate);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = normalizedDate;
                  });
                  widget.onDateSelected(normalizedDate);
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurple
                        : AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primaryGold,
                            width: 2,
                          ) // Gold border for selected
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat(
                          'MMM',
                        ).format(date).toUpperCase(), // e.g., OCT
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(), // e.g., 24
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('E').format(date), // e.g., Mon
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
