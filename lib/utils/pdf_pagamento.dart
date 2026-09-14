import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> gerarPdfPagamentoSemanal(
    {required String semana,
    required List<Map<String, dynamic>> ranking,
    required double valorMedida}) async {
  final pdf = pw.Document();

  double totalMed = 0;
  double totalValor = 0;
  int totalLitros = 0;

  for (var r in ranking) {
    totalMed += (r['totalMedidas'] as num).toDouble();
    totalValor += (r['totalValor'] as num).toDouble();
    totalLitros += (r['totalLitros'] as int? ?? 0);
  }

  pdf.addPage(pw.Page(
      build: (c) => pw.Column(children: [
            pw.Container(
                color: PdfColor.fromHex('#2e7d32'),
                padding: pw.EdgeInsets.all(15),
                child: pw.Column(children: [
                  pw.Text('FECHAMENTO - 60L = R\$35,00',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Semana: $semana | Fazenda Vargem Grande',
                      style:
                          pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                  pw.Text(
                      'Total: ${totalMed.toStringAsFixed(2)} medidas | ${totalLitros}L | R\$${totalValor.toStringAsFixed(2)}',
                      style:
                          pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                ])),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
                headers: ['NOME', 'MEDIDAS (60L)', 'LITROS', 'VALOR'],
                data: ranking
                    .map((r) => [
                          r['nome'],
                          (r['totalMedidas'] as num)
                              .toDouble()
                              .toStringAsFixed(2),
                          '${r['totalLitros']}L',
                          'R\$${(r['totalValor'] as num).toDouble().toStringAsFixed(2)}'
                        ])
                    .toList()),
          ])));

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/fechamento_$semana.pdf');
  await file.writeAsBytes(await pdf.save());
  await Share.shareXFiles([XFile(file.path)],
      text:
          'Fechamento $semana - 60L=R\$35 - Total R\$${totalValor.toStringAsFixed(2)} - Vargem Grande');
}
