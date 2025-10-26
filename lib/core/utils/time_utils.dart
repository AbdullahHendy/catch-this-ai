// Helpers to check if a two dates are on the same day, week, or month

bool isSameDay(DateTime now, DateTime currentDay) {
  return now.year == currentDay.year &&
      now.month == currentDay.month &&
      now.day == currentDay.day;
}

bool isSameWeek(DateTime now, DateTime currentWeek) {
  // Monday is weekday 1, so subtract days to get to the start of the week, monday
  // E.g., if today is Wednesday (3), subtract 2 days to get to Monday (1)
  final weekStartNow = now.subtract(
    Duration(days: now.weekday - DateTime.monday),
  );
  final weekStartCurrent = currentWeek.subtract(
    Duration(days: currentWeek.weekday - DateTime.monday),
  );
  // Check if the beginnings of the weeks are the same
  return weekStartNow.year == weekStartCurrent.year &&
      weekStartNow.month == weekStartCurrent.month &&
      weekStartNow.day == weekStartCurrent.day;
}

bool isSameMonth(DateTime now, DateTime currentMonth) {
  return now.year == currentMonth.year && now.month == currentMonth.month;
}
