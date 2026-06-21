// ignore_for_file: prefer_const_constructors
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Generate dan cetak struk izin keluar format thermal 80mm.
Future<void> printIzinKeluar({
  required String studentName,
  required String className,
  required String major,
  required String reason,
  required DateTime date,
  required DateTime? exitTime,
  required String piketName,
  required String schoolName,
  required String? schoolAddress,
  required String nomorSurat,
}) async {
  // Inisialisasi locale Indonesia sebelum pakai DateFormat
  await initializeDateFormatting('id_ID', null);
  final pdf = pw.Document();

  const pageWidth  = 80.0 * PdfPageFormat.mm;
  const pageHeight = 160.0 * PdfPageFormat.mm;

  final dateStr = DateFormat('d MMM yyyy', 'id_ID').format(date);
  final timeStr = exitTime != null
      ? DateFormat('HH:mm', 'id_ID').format(exitTime)
      : '—';

  pdf.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(pageWidth, pageHeight, marginAll: 4 * PdfPageFormat.mm),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Header sekolah
            pw.Text(
              schoolName.toUpperCase(),
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            if (schoolAddress != null && schoolAddress.isNotEmpty) ...[
              pw.SizedBox(height: 1),
              pw.Text(
                schoolAddress,
                style: const pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
            ],
            pw.SizedBox(height: 3),
            pw.Divider(thickness: 1.2),
            pw.SizedBox(height: 2),

            // Judul
            pw.Text(
              'SURAT IZIN KELUAR',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              'No: $nomorSurat',
              style: const pw.TextStyle(fontSize: 6.5),
            ),
            pw.SizedBox(height: 3),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 3),

            // Data siswa
            _dataRow('Nama',       studentName),
            _dataRow('Kelas',      className),
            _dataRow('Jurusan',    major),
            _dataRow('Keperluan',  reason),
            _dataRow('Tanggal',    dateStr),
            _dataRow('Jam Keluar', timeStr),
            _dataRow('Jam Kembali', '___________'),

            pw.SizedBox(height: 4),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 4),

            // TTD
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _ttd('Siswa',      studentName.split(' ').take(2).join(' ')),
                _ttd('Guru Piket', piketName.split(' ').take(2).join(' ')),
              ],
            ),

            pw.SizedBox(height: 4),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 2),

            // Footer
            pw.Text(
              'Wajib kembali tepat waktu',
              style: const pw.TextStyle(fontSize: 6.5),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 5.5),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'Izin-$nomorSurat',
  );
}

pw.Widget _dataRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 22 * PdfPageFormat.mm,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 7.5)),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 7.5)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: label == 'Nama' ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _ttd(String title, String name) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Text(title, style: const pw.TextStyle(fontSize: 7)),
      pw.SizedBox(height: 12),
      pw.Text(
        '($name)',
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          decoration: pw.TextDecoration.underline,
        ),
      ),
    ],
  );
}
