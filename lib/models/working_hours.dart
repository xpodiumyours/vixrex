class BookingSettings {
  bool isEnabled;
  int capacity;
  Map<String, dynamic> workingHours;
  Map<String, dynamic> lunchBreak;

  BookingSettings({
    this.isEnabled = false,
    this.capacity = 1,
    Map<String, dynamic>? workingHours,
    Map<String, dynamic>? lunchBreak,
  }) : workingHours =
           workingHours ??
           {
             '1': {'start': '09:00', 'end': '19:00', 'active': true},
             '2': {'start': '09:00', 'end': '19:00', 'active': true},
             '3': {'start': '09:00', 'end': '19:00', 'active': true},
             '4': {'start': '09:00', 'end': '19:00', 'active': true},
             '5': {'start': '09:00', 'end': '19:00', 'active': true},
             '6': {'start': '09:00', 'end': '16:00', 'active': true},
             '7': {'start': '00:00', 'end': '00:00', 'active': false},
           },
       lunchBreak =
           lunchBreak ?? {'start': '12:00', 'end': '13:00', 'active': true};

  Map<String, dynamic> toJson() => {
    'is_enabled': isEnabled,
    'capacity': capacity,
    'working_hours': workingHours,
    'lunch_break': lunchBreak,
  };

  factory BookingSettings.fromJson(Map<String, dynamic> json) {
    return BookingSettings(
      isEnabled: (json['is_enabled'] ?? json['isEnabled'] ?? false) as bool,
      capacity: (json['capacity'] ?? 1) as int,
      workingHours:
          json['working_hours'] != null
              ? Map<String, dynamic>.from(json['working_hours'] as Map)
              : (json['workingHours'] != null
                  ? Map<String, dynamic>.from(json['workingHours'] as Map)
                  : {}),
      lunchBreak:
          json['lunch_break'] != null
              ? Map<String, dynamic>.from(json['lunch_break'] as Map)
              : (json['lunchBreak'] != null
                  ? Map<String, dynamic>.from(json['lunchBreak'] as Map)
                  : {}),
    );
  }
}
