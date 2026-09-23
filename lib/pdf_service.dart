import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';

class ReportPdfService {
  static Future<void> generateAndSharePdf(DutyReport r) async {
    final pdf = pw.Document();

    final fontRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final fontItalic = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Italic.ttf'));
    final fontBoldItalic = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-BoldItalic.ttf'));

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
      boldItalic: fontBoldItalic,
    );

    pw.Widget buildRoomTable(String title, String timeFrame, List<RoomAttendance> rooms) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$title ($timeFrame)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(40),
              1: pw.FixedColumnWidth(85),
              2: pw.FlexColumnWidth(),
              3: pw.FixedColumnWidth(80),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Center(child: pw.Text('Phòng', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Center(child: pw.Text('Số HS có mặt/\nHS phòng', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7), textAlign: pw.TextAlign.center)),
                  pw.Center(child: pw.Text('Tên HS vắng (lí do)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Center(child: pw.Text('Ghi chú', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                ],
              ),
              for (final RoomAttendance room in rooms)
                pw.TableRow(
                  children: [
                    pw.Center(child: pw.Text('${room.roomNumber}', style: const pw.TextStyle(fontSize: 8))),
                    pw.Center(child: pw.Text('${room.present}/${room.total}', style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: pw.Text(room.absentDetails, style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: pw.Text(room.note, style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 6),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('TRƯỜNG PTDTBT THCS PHAN THANH', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('TỔ QUẢN LÝ HS BÁN TRÚ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Container(width: 70, height: 0.5, color: PdfColors.black, margin: const pw.EdgeInsets.only(top: 2)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Độc lập – Tự do – Hạnh phúc', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                  pw.Container(width: 90, height: 0.5, color: PdfColors.black, margin: const pw.EdgeInsets.only(top: 2)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          pw.Center(
            child: pw.Column(
              children: [
                pw.Text('BIÊN BẢN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('Về việc trực bán trú năm học 2026 – 2027', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 6),

          pw.Text('Vào hồi: ${r.hour} giờ ${r.minute} phút ngày ${r.dutyDate.day} tháng ${r.dutyDate.month} năm ${r.dutyDate.year}, tại trường PTDTBT THCS Phan Thanh (trường chính).', style: const pw.TextStyle(fontSize: 8.5)),
          pw.Text('Chúng tôi gồm: 1, ${r.teachers.isNotEmpty ? r.teachers[0] : ""}    2, ${r.teachers.length > 1 ? r.teachers[1] : ""}    3, ${r.teachers.length > 2 ? r.teachers[2] : ""}', style: const pw.TextStyle(fontSize: 8.5)),
          pw.Text('Thực hiện các nội dung công việc như sau:', style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 5),

          pw.Text('1. Theo dõi sĩ số học sinh đến trường: (Điểm danh từ 7h30’ -8h30’)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(
            'Lớp 6A: TS ${r.classAttendances[0].present}/${r.classAttendances[0].total}   |   '
            'Lớp 7A: TS ${r.classAttendances[2].present}/${r.classAttendances[2].total}   |   '
            'Lớp 8A: TS ${r.classAttendances[4].present}/${r.classAttendances[4].total}   |   '
            'Lớp 9A: TS ${r.classAttendances[6].present}/${r.classAttendances[6].total}',
            style: const pw.TextStyle(fontSize: 8.5),
          ),
          pw.Text(
            'Lớp 6B: TS ${r.classAttendances[1].present}/${r.classAttendances[1].total}   |   '
            'Lớp 7B: TS ${r.classAttendances[3].present}/${r.classAttendances[3].total}   |   '
            'Lớp 8B: TS ${r.classAttendances[5].present}/${r.classAttendances[5].total}   |   '
            'Lớp 9B: TS ${r.classAttendances[7].present}/${r.classAttendances[7].total}',
            style: const pw.TextStyle(fontSize: 8.5),
          ),
          pw.SizedBox(height: 5),

          buildRoomTable('2. Theo dõi sĩ số học sinh bán trú', 'Điểm danh từ 12h15’ – 13h30’', r.noonRoomAttendances),

          pw.Text('3. Theo dõi HS Thực hiện nội quy kí túc, tham gia các hoạt động:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(r.dormRulesNote.isEmpty ? 'Không có' : r.dormRulesNote, style: const pw.TextStyle(fontSize: 8.5)),
          pw.SizedBox(height: 4),

          pw.Text('4. Theo dõi HS vệ sinh cá nhân - phòng ở ; vệ sinh khu vực:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(r.hygieneNote.isEmpty ? 'Đảm bảo vệ sinh sạch sẽ' : r.hygieneNote, style: const pw.TextStyle(fontSize: 8.5)),
          pw.SizedBox(height: 5),

          buildRoomTable('5.1. Giám sát học sinh ăn trưa', 'Điểm danh từ 11h55’ – 12h05’', r.lunchAttendances),
          buildRoomTable('5.2. Giám sát học sinh ăn tối', 'Điểm danh từ 18h00’ – 18h10’', r.dinnerAttendances),
          buildRoomTable('6. Quản lý giờ tự học của HS ở nội trú', 'từ 19h00’ – 20h30’', r.studyAttendances),
          buildRoomTable('7. Theo dõi sĩ số học sinh và HS ăn sáng hôm sau', 'Kiểm tra từ 06h00’ – 06h45’', r.breakfastAttendances),

          pw.Text('8. Tình hình an ninh:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(r.securityNote.isEmpty ? 'Ổn định, an toàn' : r.securityNote, style: const pw.TextStyle(fontSize: 8.5)),
          pw.SizedBox(height: 4),

          pw.Text('9. Những nội dung chi tiết bất thường diễn ra trong ngày, phương án xử lý:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(r.incidentsAndSolutions.isEmpty ? 'Không có' : r.incidentsAndSolutions, style: const pw.TextStyle(fontSize: 8.5)),
          pw.SizedBox(height: 10),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Phan Thanh, ngày ${r.dutyDate.day} tháng ${r.dutyDate.month} năm ${r.dutyDate.year}', style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic)),
                  pw.Text('Đại diện nhóm trực', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('(ký và ghi rõ họ tên)', style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    r.representativeTeacher.isNotEmpty 
                        ? r.representativeTeacher 
                        : (r.teachers.isNotEmpty ? r.teachers[0] : ''), 
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Bien_ban_truc_${r.dutyDate.day}_${r.dutyDate.month}_${r.dutyDate.year}.pdf',
    );
  }
}
