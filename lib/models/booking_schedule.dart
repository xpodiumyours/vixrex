class BookingDaySchedule {
  final String start;
  final String end;
  final bool active;

  const BookingDaySchedule({
    this.start = '09:00',
    this.end = '19:00',
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'active': active,
  };

  factory BookingDaySchedule.fromJson(Map<String, dynamic> json) {
    return BookingDaySchedule(
      start: (json['start'] ?? '09:00').toString(),
      end: (json['end'] ?? '19:00').toString(),
      active: (json['active'] ?? true) as bool,
    );
  }
}

class BookingWorkingHours {
  final Map<String, BookingDaySchedule> days;

  BookingWorkingHours({Map<String, BookingDaySchedule>? days})
    : days =
          days ??
          {
            '1': const BookingDaySchedule(
              start: '09:00',
              end: '19:00',
              active: true,
            ),
            '2': const BookingDaySchedule(
              start: '09:00',
              end: '19:00',
              active: true,
            ),
            '3': const BookingDaySchedule(
              start: '09:00',
              end: '19:00',
              active: true,
            ),
            '4': const BookingDaySchedule(
              start: '09:00',
              end: '19:00',
              active: true,
            ),
            '5': const BookingDaySchedule(
              start: '09:00',
              end: '19:00',
              active: true,
            ),
            '6': const BookingDaySchedule(
              start: '09:00',
              end: '16:00',
              active: true,
            ),
            '7': const BookingDaySchedule(
              start: '00:00',
              end: '00:00',
              active: false,
            ),
          };

  Map<String, dynamic> toJson() =>
      days.map((key, value) => MapEntry(key, value.toJson()));

  factory BookingWorkingHours.fromJson(Map<String, dynamic> json) {
    return BookingWorkingHours(
      days: json.map(
        (key, value) => MapEntry(
          key,
          BookingDaySchedule.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }
}

class BookingLunchBreak {
  final String start;
  final String end;
  final bool active;

  const BookingLunchBreak({
    this.start = '12:00',
    this.end = '13:00',
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'active': active,
  };

  factory BookingLunchBreak.fromJson(Map<String, dynamic> json) {
    return BookingLunchBreak(
      start: (json['start'] ?? '12:00').toString(),
      end: (json['end'] ?? '13:00').toString(),
      active: (json['active'] ?? true) as bool,
    );
  }
}
