import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models.dart';
import 'pdf_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BoardingDutyApp());
}

class BoardingDutyApp extends StatelessWidget {
  const BoardingDutyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ Trực Bán Trú',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
      ],
      locale: const Locale('vi', 'VN'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E56A0),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor: Color(0xFF1E56A0),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: const DutyReportScreen(),
    );
  }
}

// BẢNG ĐIỂM DANH 9 PHÒNG
class RoomAttendanceTableWidget extends StatelessWidget {
  final String title;
  final String timeFrame;
  final List<RoomAttendance> rooms;
  final VoidCallback onDataChanged;

  const RoomAttendanceTableWidget({
    Key? key,
    required this.title,
    required this.timeFrame,
    required this.rooms,
    required this.onDataChanged,
  }) : super(key: key);

  void _editRoom(BuildContext context, RoomAttendance room) {
    final presentCtrl = TextEditingController(text: room.present > 0 ? room.present.toString() : '');
    final totalCtrl = TextEditingController(text: room.total > 0 ? room.total.toString() : '');
    final absentCtrl = TextEditingController(text: room.absentDetails);
    final noteCtrl = TextEditingController(text: room.note);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cập nhật Phòng ${room.roomNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: presentCtrl,
                      decoration: const InputDecoration(labelText: 'Có mặt'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: totalCtrl,
                      decoration: const InputDecoration(labelText: 'Tổng sĩ số'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: absentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên HS vắng (lí do)',
                  hintText: 'VD: Lò Văn A (về phép)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              room.present = int.tryParse(presentCtrl.text) ?? room.present;
              room.total = int.tryParse(totalCtrl.text) ?? room.total;
              room.absentDetails = absentCtrl.text.trim();
              room.note = noteCtrl.text.trim();
              onDataChanged();
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Khung giờ: $timeFrame', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 12)),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = rooms[index];
                final isAbsent = r.absentDetails.isNotEmpty || (r.total > 0 && r.present < r.total);
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 13,
                    backgroundColor: isAbsent ? Colors.orange[100] : Colors.blue[50],
                    child: Text('${r.roomNumber}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAbsent ? Colors.deepOrange : Colors.blue[800])),
                  ),
                  title: Text('Có mặt: ${r.present}/${r.total}', style: TextStyle(fontWeight: FontWeight.w600, color: isAbsent ? Colors.deepOrange : Colors.black87)),
                  subtitle: isAbsent
                      ? Text('Vắng: ${r.absentDetails} ${r.note.isNotEmpty ? "(${r.note})" : ""}')
                      : const Text('Đầy đủ', style: TextStyle(color: Colors.green)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editRoom(context, r),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// MÀN HÌNH CHÍNH: SOẠN BIÊN BẢN & LỊCH SỬ
class DutyReportScreen extends StatefulWidget {
  const DutyReportScreen({Key? key}) : super(key: key);

  @override
  State<DutyReportScreen> createState() => _DutyReportScreenState();
}

class _DutyReportScreenState extends State<DutyReportScreen> {
  late DutyReport report;

  late TextEditingController _teacher1Ctrl;
  late TextEditingController _teacher2Ctrl;
  late TextEditingController _teacher3Ctrl;
  int _signerIndex = 0;

  late List<TextEditingController> _classPresentControllers;
  late List<TextEditingController> _classTotalControllers;

  late TextEditingController _dormRulesCtrl;
  late TextEditingController _hygieneCtrl;
  late TextEditingController _securityCtrl;
  late TextEditingController _incidentsCtrl;

  @override
  void initState() {
    super.initState();
    _initNewReport();
  }

  void _initNewReport() {
    report = DutyReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dutyDate: DateTime.now(),
      hour: 7,
      minute: 30,
      teachers: ['', '', ''],
    );

    _teacher1Ctrl = TextEditingController(text: report.teachers[0]);
    _teacher2Ctrl = TextEditingController(text: report.teachers[1]);
    _teacher3Ctrl = TextEditingController(text: report.teachers[2]);

    _classPresentControllers = report.classAttendances
        .map((c) => TextEditingController(text: c.present > 0 ? c.present.toString() : ''))
        .toList();
    _classTotalControllers = report.classAttendances
        .map((c) => TextEditingController(text: c.total > 0 ? c.total.toString() : ''))
        .toList();

    _dormRulesCtrl = TextEditingController(text: report.dormRulesNote);
    _hygieneCtrl = TextEditingController(text: report.hygieneNote);
    _securityCtrl = TextEditingController(text: report.securityNote);
    _incidentsCtrl = TextEditingController(text: report.incidentsAndSolutions);

    _signerIndex = 0;
    _syncSigner();
  }

  void _loadReportIntoForm(DutyReport loaded) {
    setState(() {
      report = loaded;
      _teacher1Ctrl.text = report.teachers.isNotEmpty ? report.teachers[0] : '';
      _teacher2Ctrl.text = report.teachers.length > 1 ? report.teachers[1] : '';
      _teacher3Ctrl.text = report.teachers.length > 2 ? report.teachers[2] : '';

      if (report.representativeTeacher == _teacher2Ctrl.text && _teacher2Ctrl.text.isNotEmpty) {
        _signerIndex = 1;
      } else if (report.representativeTeacher == _teacher3Ctrl.text && _teacher3Ctrl.text.isNotEmpty) {
        _signerIndex = 2;
      } else {
        _signerIndex = 0;
      }

      for (int i = 0; i < report.classAttendances.length; i++) {
        _classPresentControllers[i].text = report.classAttendances[i].present > 0 ? report.classAttendances[i].present.toString() : '';
        _classTotalControllers[i].text = report.classAttendances[i].total > 0 ? report.classAttendances[i].total.toString() : '';
      }

      _dormRulesCtrl.text = report.dormRulesNote;
      _hygieneCtrl.text = report.hygieneNote;
      _securityCtrl.text = report.securityNote;
      _incidentsCtrl.text = report.incidentsAndSolutions;
    });
  }

  void _syncSigner() {
    report.teachers = [
      _teacher1Ctrl.text.trim(),
      _teacher2Ctrl.text.trim(),
      _teacher3Ctrl.text.trim(),
    ];
    if (_signerIndex == 0) {
      report.representativeTeacher = _teacher1Ctrl.text.trim();
    } else if (_signerIndex == 1) {
      report.representativeTeacher = _teacher2Ctrl.text.trim();
    } else {
      report.representativeTeacher = _teacher3Ctrl.text.trim();
    }
    report.dormRulesNote = _dormRulesCtrl.text.trim();
    report.hygieneNote = _hygieneCtrl.text.trim();
    report.securityNote = _securityCtrl.text.trim();
    report.incidentsAndSolutions = _incidentsCtrl.text.trim();
  }

  Future<void> _saveReport() async {
    _syncSigner();
    await ReportStorageService.saveOrUpdateReport(report);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu biên bản thành công!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openHistoryDialog() async {
    final list = await ReportStorageService.getAllReports();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lịch Sử Các Ca Trực', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Chưa có biên bản nào được lưu.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final r = list[index];
                          final teachersStr = r.teachers.where((t) => t.isNotEmpty).join(", ");
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF1E56A0),
                              child: Icon(Icons.description, color: Colors.white, size: 20),
                            ),
                            title: Text('Ngày ${r.dutyDate.day}/${r.dutyDate.month}/${r.dutyDate.year} (${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Trực: ${teachersStr.isNotEmpty ? teachersStr : "Chưa có tên"}\nNgười ký: ${r.representativeTeacher}'),
                            isThreeLine: true,
                            onTap: () {
                              _loadReportIntoForm(r);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã mở biên bản ngày ${r.dutyDate.day}/${r.dutyDate.month}/${r.dutyDate.year}')),
                              );
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                await ReportStorageService.deleteReport(r.id);
                                setModalState(() {
                                  list.removeWhere((item) => item.id == r.id);
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _teacher1Ctrl.dispose();
    _teacher2Ctrl.dispose();
    _teacher3Ctrl.dispose();
    for (var c in _classPresentControllers) { c.dispose(); }
    for (var c in _classTotalControllers) { c.dispose(); }
    _dormRulesCtrl.dispose();
    _hygieneCtrl.dispose();
    _securityCtrl.dispose();
    _incidentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biên Bản Trực Bán Trú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử ca trực',
            onPressed: _openHistoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Tạo ca mới',
            onPressed: () {
              setState(() { _initNewReport(); });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tạo một biên bản ca trực mới!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Xuất văn bản PDF',
            onPressed: () async {
              _syncSigner();
              await _saveReport();
              await ReportPdfService.generateAndSharePdf(report);
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.history, color: Color(0xFF1E56A0)),
                label: const Text('LỊCH SỬ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E56A0))),
                onPressed: _openHistoryDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E56A0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.save),
                label: const Text('LƯU BIÊN BẢN', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _saveReport,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRƯỜNG PTDTBT THCS PHAN THANH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E56A0))),
                    const Text('TỔ QUẢN LÝ HS BÁN TRÚ', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    const Divider(height: 16),
                    const Text('Thời gian lập biên bản (Chạm để đổi):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: report.dutyDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                                locale: const Locale('vi', 'VN'),
                              );
                              if (pickedDate != null) {
                                setState(() { report.dutyDate = pickedDate; });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueGrey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blue.shade50.withOpacity(0.3),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: Color(0xFF1E56A0), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Ngày ${report.dutyDate.day}/${report.dutyDate.month}/${report.dutyDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: report.hour, minute: report.minute),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  report.hour = pickedTime.hour;
                                  report.minute = pickedTime.minute;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueGrey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blue.shade50.withOpacity(0.3),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0xFF1E56A0), size: 20),
                                  const SizedBox(width: 6),
                                  Text('${report.hour.toString().padLeft(2, '0')}:${report.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.group, color: Color(0xFF1E56A0)),
                        SizedBox(width: 8),
                        Text('Thành viên ca trực (03 người)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _teacher1Ctrl,
                      decoration: InputDecoration(
                        labelText: '1. Họ và tên người trực 1 (Mặc định ký)',
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: _signerIndex == 0
                            ? const Chip(label: Text('Ký biên bản', style: TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: Color(0xFF1E56A0))
                            : null,
                      ),
                      onChanged: (val) { if (_signerIndex == 0) _syncSigner(); },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _teacher2Ctrl,
                      decoration: InputDecoration(
                        labelText: '2. Họ và tên người trực 2',
                        prefixIcon: const Icon(Icons.person_outline),
                        suffixIcon: _signerIndex == 1
                            ? const Chip(label: Text('Ký biên bản', style: TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: Color(0xFF1E56A0))
                            : null,
                      ),
                      onChanged: (val) { if (_signerIndex == 1) _syncSigner(); },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _teacher3Ctrl,
                      decoration: InputDecoration(
                        labelText: '3. Họ và tên người trực 3',
                        prefixIcon: const Icon(Icons.person_outline),
                        suffixIcon: _signerIndex == 2
                            ? const Chip(label: Text('Ký biên bản', style: TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: Color(0xFF1E56A0))
                            : null,
                      ),
                      onChanged: (val) { if (_signerIndex == 2) _syncSigner(); },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Người ký: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Expanded(
                          child: Row(
                            children: [
                              Radio<int>(value: 0, groupValue: _signerIndex, onChanged: (v) => setState(() { _signerIndex = v!; _syncSigner(); })),
                              const Text('Người 1'),
                              Radio<int>(value: 1, groupValue: _signerIndex, onChanged: (v) => setState(() { _signerIndex = v!; _syncSigner(); })),
                              const Text('Người 2'),
                              Radio<int>(value: 2, groupValue: _signerIndex, onChanged: (v) => setState(() { _signerIndex = v!; _syncSigner(); })),
                              const Text('Người 3'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Sĩ số học sinh đến trường (7h30 - 8h30)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: report.classAttendances.length,
                      itemBuilder: (ctx, i) {
                        final ca = report.classAttendances[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueGrey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Lớp ${ca.className}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E56A0))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _classPresentControllers[i],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                        hintText: 'Có mặt',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) { ca.present = int.tryParse(val.trim()) ?? 0; },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Text('/', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _classTotalControllers[i],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                        hintText: 'Tổng',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) { ca.total = int.tryParse(val.trim()) ?? 0; },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            RoomAttendanceTableWidget(
              title: '2. Theo dõi sĩ số học sinh bán trú',
              timeFrame: '12h15 – 13h30',
              rooms: report.noonRoomAttendances,
              onDataChanged: () => setState(() {}),
            ),
            RoomAttendanceTableWidget(
              title: '5.1 Giám sát ăn trưa',
              timeFrame: '11h55 – 12h05',
              rooms: report.lunchAttendances,
              onDataChanged: () => setState(() {}),
            ),
            RoomAttendanceTableWidget(
              title: '5.2 Giám sát ăn tối',
              timeFrame: '18h00 – 18h10',
              rooms: report.dinnerAttendances,
              onDataChanged: () => setState(() {}),
            ),
            RoomAttendanceTableWidget(
              title: '6. Quản lý giờ tự học ở nội trú',
              timeFrame: '19h00 – 20h30',
              rooms: report.studyAttendances,
              onDataChanged: () => setState(() {}),
            ),
            RoomAttendanceTableWidget(
              title: '7. Theo dõi sĩ số và HS ăn sáng hôm sau',
              timeFrame: '06h00 – 06h45',
              rooms: report.breakfastAttendances,
              onDataChanged: () => setState(() {}),
            ),
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(controller: _dormRulesCtrl, decoration: const InputDecoration(labelText: '3. Thực hiện nội quy kí túc')),
                    const SizedBox(height: 10),
                    TextField(controller: _hygieneCtrl, decoration: const InputDecoration(labelText: '4. Vệ sinh cá nhân - phòng ở - khu vực')),
                    const SizedBox(height: 10),
                    TextField(controller: _securityCtrl, decoration: const InputDecoration(labelText: '8. Tình hình an ninh')),
                    const SizedBox(height: 10),
                    TextField(controller: _incidentsCtrl, decoration: const InputDecoration(labelText: '9. Bất thường và phương án xử lý'), maxLines: 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
