/// A date in the player's local calendar, with no time and no zone.
///
/// Recall is scheduled in whole days ("due in 3 days"), so the engine works in days. The app
/// turns its clock into today's [CalendarDay] and passes it in; the engine never reads a clock
/// (AGENTS.md non-negotiable 3).
class CalendarDay implements Comparable<CalendarDay> {
  CalendarDay(int year, int month, int day)
    : _utc = DateTime.utc(year, month, day);

  CalendarDay._(this._utc);

  /// Backed by midnight UTC, where every day is 24 hours long, so adding days never trips
  /// over a daylight-saving change.
  final DateTime _utc;

  int get year => _utc.year;
  int get month => _utc.month;
  int get day => _utc.day;

  CalendarDay addDays(int days) =>
      CalendarDay._(_utc.add(Duration(days: days)));

  bool isBefore(CalendarDay other) => _utc.isBefore(other._utc);

  @override
  int compareTo(CalendarDay other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) => other is CalendarDay && other._utc == _utc;

  @override
  int get hashCode => _utc.hashCode;

  @override
  String toString() =>
      '$year-${'$month'.padLeft(2, '0')}-${'$day'.padLeft(2, '0')}';
}
