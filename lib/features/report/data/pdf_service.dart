import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/shared/models/transaction.dart';

class PdfService {
  static final _fmt = NumberFormat('#,###', 'vi_VN');
  static final _dateFmt = DateFormat('dd/MM/yyyy', 'vi_VN');

  /// Tạo PDF báo cáo tháng và mở share/print dialog
  static Future<void> exportMonthlyReport({
    required String uid,
    required int month,
    required int year,
    required FirebaseFirestore db,
  }) async {
    // Lấy giao dịch tháng
    final start = DateTime(year, month, 1);
    final end   = DateTime(year, month + 1, 1);
    final snap = await db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();

    final txs = snap.docs.map((d) => TransactionModel.fromMap(d.id, {...d.data(), 'ownerUid': uid})).toList();

    double totalIn  = 0;
    double totalOut = 0;
    final Map<String, double> byCategory = {};

    for (final t in txs) {
      if (t.type == TransactionType.income) {
        totalIn += t.amount;
      } else if (t.type == TransactionType.expense) {
        totalOut += t.amount;
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
    }

    final pdf = pw.Document();
    final titleStyle    = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final headerStyle   = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    final subStyle      = const pw.TextStyle(fontSize: 10);
    final redStyle      = pw.TextStyle(fontSize: 10, color: PdfColors.red600);
    final greenStyle    = pw.TextStyle(fontSize: 10, color: PdfColors.green700);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text('Báo cáo tài chính tháng $month/$year', style: titleStyle),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // Tổng hợp
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Tổng thu', style: headerStyle),
                pw.Text('+${_fmt.format(totalIn)}đ', style: greenStyle),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Tổng chi', style: headerStyle),
                pw.Text('-${_fmt.format(totalOut)}đ', style: redStyle),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Cân đối', style: headerStyle),
                pw.Text(
                  '${totalIn - totalOut >= 0 ? '+' : ''}${_fmt.format(totalIn - totalOut)}đ',
                  style: totalIn - totalOut >= 0 ? greenStyle : redStyle,
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 16),

          // Chi theo danh mục
          if (byCategory.isNotEmpty) ...[
            pw.Text('Chi tiêu theo danh mục', style: headerStyle),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(2)},
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Danh mục', style: headerStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Số tiền', style: headerStyle)),
                  ],
                ),
                ...byCategory.entries
                    .toList()
                    .sorted((a, b) => b.value.compareTo(a.value))
                    .map((e) => pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.key, style: subStyle)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('-${_fmt.format(e.value)}đ', style: redStyle)),
                        ])),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Chi tiết giao dịch
          pw.Text('Chi tiết giao dịch (${txs.length})', style: headerStyle),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Ngày', style: headerStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Danh mục / Ghi chú', style: headerStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Số tiền', style: headerStyle)),
                ],
              ),
              ...txs.map((t) {
                final isIncome = t.type == TransactionType.income;
                final sign = isIncome ? '+' : (t.type == TransactionType.transfer ? '⇄' : '-');
                final amtStyle = isIncome ? greenStyle : redStyle;
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_dateFmt.format(t.createdAt), style: subStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('${t.category}${t.note.isNotEmpty ? '\n${t.note}' : ''}', style: subStyle)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('$sign${_fmt.format(t.amount)}đ', style: amtStyle)),
                ]);
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'bao_cao_${month}_$year.pdf',
    );
  }
}

extension _ListX<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) => [...this]..sort(compare);
}
