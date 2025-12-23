import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class CustomTimePicker extends StatefulWidget {
  final Function(TimeOfDay) onTimeSelected;

  const CustomTimePicker({Key? key, required this.onTimeSelected})
    : super(key: key);

  @override
  _CustomTimePickerState createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  TimeOfDay? _selectedTime;

  // Common ride times to show as "Chips"
  final List<TimeOfDay> _suggestedTimes = const [
    TimeOfDay(hour: 6, minute: 0), // 6:00 AM
    TimeOfDay(hour: 8, minute: 0), // 8:00 AM
    TimeOfDay(hour: 9, minute: 30), // 9:30 AM
    TimeOfDay(hour: 12, minute: 0), // 12:00 PM
    TimeOfDay(hour: 17, minute: 0), // 5:00 PM
    TimeOfDay(hour: 19, minute: 0), // 7:00 PM
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What time will you pick up?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._suggestedTimes.map((time) {
              final isSelected = _selectedTime == time;
              return ChoiceChip(
                label: Text(
                  time.format(context),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryPurple,
                backgroundColor: AppColors.backgroundDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryGold
                        : Colors.transparent,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTime = time;
                    });
                    widget.onTimeSelected(time);
                  }
                },
              );
            }).toList(),
            // "Other" Button to open full clock
            ActionChip(
              label: const Text("Other time..."),
              backgroundColor: AppColors.backgroundDark,
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryPurple,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedTime = picked;
                  });
                  widget.onTimeSelected(picked);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
