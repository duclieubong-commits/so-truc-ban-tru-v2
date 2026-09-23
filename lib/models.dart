import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RoomAttendance {
  final int roomNumber;
  int present;
  int total;
  String absentDetails;
  String note;

  RoomAttendance({
    required this.roomNumber,
    this.present = 0,
    this.total = 0,
    this.absentDetails = '',
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
    'roomNumber': roomNumber,
    'present': present,
    'total': total,
    'absentDetails': absentDetails,
    'note': note,
  };

  factory RoomAttendance.fromMap(Map<String, dynamic> map) => RoomAttendance(
    roomNumber: map['roomNumber'] ?? 0,
    present: map['present'] ?? 0,
    total: map['total'] ?? 0,
    absentDetails: map['absentDetails'] ?? '',
    note: map['note'] ?? '',
  );
}

class ClassAttendance {
  final String className;
  int present;
  int total;

  ClassAttendance({
    required this.className,
    this.present = 0,
    this.total = 0,
  });

  Map<String, dynamic> toMap() => {
    'className': className,
    'present': present,
    'total': total,
  };

  factory ClassAttendance.fromMap(Map<String, dynamic> map) => ClassAttendance(
    className: map['className'] ?? '',
    present: map['present'] ?? 0,
    total: map['total'] ?? 0,
  );
}

class DutyReport {
  String id;
  DateTime dutyDate;
  int hour;
  int minute;
  List<String> teachers;
  List<ClassAttendance> classAttendances;
  List<RoomAttendance> noonRoomAttendances;
  String dormRulesNote;
  String hygieneNote;
  List<RoomAttendance> lunchAttendances;
  List<RoomAttendance> dinnerAttendances;
  List<RoomAttendance> studyAttendances;
  List<RoomAttendance> breakfastAttendances;
  String securityNote;
  String incidentsAndSolutions;
  String representativeTeacher;

  DutyReport({
    required this.id,
    required this.dutyDate,
    this.hour = 7,
    this.minute = 30,
    List<String>? teachers,
    List<ClassAttendance>? classAttendances,
    List<RoomAttendance>? noonRoomAttendances,
    this.dormRulesNote = 'Học sinh chấp hành tốt nội quy kí túc xá.',
    this.hygieneNote = 'Phòng ở và khu vực chung sạch sẽ, ngăn nắp.',
    List<RoomAttendance>? lunchAttendances,
    List<RoomAttendance>? dinnerAttendances,
    List<RoomAttendance>? studyAttendances,
    List<RoomAttendance>? breakfastAttendances,
    this.securityNote = 'Khu vực nội trú an toàn, ổn định, không có vụ việc bất thường.',
    this.incidentsAndSolutions = 'Không có.',
    this.representativeTeacher = '',
  })  : teachers = teachers ?? ['', '', ''],
        classAttendances = classAttendances ?? [
          ClassAttendance(className: '6A'), ClassAttendance(className: '6B'),
          ClassAttendance(className: '7A'), ClassAttendance(className: '7B'),
          ClassAttendance(className: '8A'), ClassAttendance(className: '8B'),
          ClassAttendance(className: '9A'), ClassAttendance(className: '9B'),
        ],
        noonRoomAttendances = noonRoomAttendances ?? _generateDefaultRooms(),
        lunchAttendances = lunchAttendances ?? _generateDefaultRooms(),
        dinnerAttendances = dinnerAttendances ?? _generateDefaultRooms(),
        studyAttendances = studyAttendances ?? _generateDefaultRooms(),
        breakfastAttendances = breakfastAttendances ?? _generateDefaultRooms();

  static List<RoomAttendance> _generateDefaultRooms() {
    return List.generate(9, (index) => RoomAttendance(roomNumber: index + 1));
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'dutyDate': dutyDate.toIso8601String(),
    'hour': hour,
    'minute': minute,
    'teachers': teachers,
    'classAttendances': classAttendances.map((x) => x.toMap()).toList(),
    'noonRoomAttendances': noonRoomAttendances.map((x) => x.toMap()).toList(),
    'dormRulesNote': dormRulesNote,
    'hygieneNote': hygieneNote,
    'lunchAttendances': lunchAttendances.map((x) => x.toMap()).toList(),
    'dinnerAttendances': dinnerAttendances.map((x) => x.toMap()).toList(),
    'studyAttendances': studyAttendances.map((x) => x.toMap()).toList(),
    'breakfastAttendances': breakfastAttendances.map((x) => x.toMap()).toList(),
    'securityNote': securityNote,
    'incidentsAndSolutions': incidentsAndSolutions,
    'representativeTeacher': representativeTeacher,
  };

  factory DutyReport.fromMap(Map<String, dynamic> map) => DutyReport(
    id: map['id'] ?? '',
    dutyDate: DateTime.tryParse(map['dutyDate'] ?? '') ?? DateTime.now(),
    hour: map['hour'] ?? 7,
    minute: map['minute'] ?? 30,
    teachers: List<String>.from(map['teachers'] ?? ['', '', '']),
    classAttendances: (map['classAttendances'] as List<dynamic>?)
        ?.map((x) => ClassAttendance.fromMap(x))
        .toList(),
    noonRoomAttendances: (map['noonRoomAttendances'] as List<dynamic>?)
        ?.map((x) => RoomAttendance.fromMap(x))
        .toList(),
    dormRulesNote: map['dormRulesNote'] ?? '',
    hygieneNote: map['hygieneNote'] ?? '',
    lunchAttendances: (map['lunchAttendances'] as List<dynamic>?)
        ?.map((x) => RoomAttendance.fromMap(x))
        .toList(),
    dinnerAttendances: (map['dinnerAttendances'] as List<dynamic>?)
        ?.map((x) => RoomAttendance.fromMap(x))
        .toList(),
    studyAttendances: (map['studyAttendances'] as List<dynamic>?)
        ?.map((x) => RoomAttendance.fromMap(x))
        .toList(),
    breakfastAttendances: (map['breakfastAttendances'] as List<dynamic>?)
        ?.map((x) => RoomAttendance.fromMap(x))
        .toList(),
    securityNote: map['securityNote'] ?? '',
    incidentsAndSolutions: map['incidentsAndSolutions'] ?? '',
    representativeTeacher: map['representativeTeacher'] ?? '',
  );
}

class ReportStorageService {
  static const String _keyReports = 'saved_duty_reports';

  static Future<List<DutyReport>> getAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getStringList(_keyReports) ?? [];
    List<DutyReport> reports = [];
    for (var str in listJson) {
      try {
        reports.add(DutyReport.fromMap(jsonDecode(str)));
      } catch (_) {}
    }
    reports.sort((a, b) => b.dutyDate.compareTo(a.dutyDate));
    return reports;
  }

  static Future<void> saveOrUpdateReport(DutyReport report) async {
    final prefs = await SharedPreferences.getInstance();
    List<DutyReport> reports = await getAllReports();

    int index = reports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      reports[index] = report;
    } else {
      reports.insert(0, report);
    }

    final listJson = reports.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList(_keyReports, listJson);
  }

  static Future<void> deleteReport(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<DutyReport> reports = await getAllReports();
    reports.removeWhere((r) => r.id == id);
    final listJson = reports.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList(_keyReports, listJson);
  }
}
