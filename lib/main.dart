import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'db/database_helper.dart';
import 'utils/pdf_pagamento.dart';
import 'package:intl/intl.dart';

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeTabs(),
    theme: ThemeData(primarySwatch: Colors.green)));

class HomeTabs extends StatefulWidget {
  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int index = 0;
  final pages = [LancamentoPage(), ColaboradoresPage(), RelatorioPage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: Colors.green[800],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.grass), label: 'Lançar'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Colab.'),
          BottomNavigationBarItem(
              icon: Icon(Icons.picture_as_pdf), label: 'Fechar'),
        ],
      ),
    );
  }
}

class LancamentoPage extends StatefulWidget {
  @override
  State<LancamentoPage> createState() => _LancamentoPageState();
}

class _LancamentoPageState extends State<LancamentoPage> {
  int medidasCompletas = 0;
  int litrosRestantes = 0;
  String? colaboradorNome;
  int? colaboradorId;
  final db = DatabaseHelper();
  double valorMedida = 35.0;
  double get valorPorLitro => valorMedida / 60.0;
  double get totalDecimal => medidasCompletas + (litrosRestantes / 60.0);
  double get valorTotal => totalDecimal * valorMedida;
  int get totalLitros => medidasCompletas * 60 + litrosRestantes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('60L = 1 Medida | R\$35', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white),
      body: Padding(
          padding: EdgeInsets.all(12),
          child: Column(children: [
            if (colaboradorNome == null)
              ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ScannerPage()));
                    if (res != null) {
                      var dados = await db.getColaboradorByQr(res);
                      if (dados != null)
                        setState(() {
                          colaboradorNome = dados['nome'];
                          colaboradorId = dados['id'];
                        });
                    }
                  },
                  icon: Icon(Icons.qr_code_scanner),
                  label: Text('1. ESCANEAR CRACHA DO COLHEDOR'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 55),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white)),
            if (colaboradorNome != null)
              Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.person, color: Colors.green[800]),
                        Text(colaboradorNome!,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () =>
                                setState(() => colaboradorNome = null))
                      ])),
            SizedBox(height: 10),
            Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  Text('MEDIDAS COMPLETAS (60L cada)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                            onPressed: () => setState(() => medidasCompletas > 0
                                ? medidasCompletas--
                                : null),
                            icon: Icon(Icons.remove_circle,
                                size: 45, color: Colors.green[800])),
                        Column(children: [
                          Text('$medidasCompletas',
                              style: TextStyle(
                                  fontSize: 45, fontWeight: FontWeight.bold)),
                          Text('x 60L', style: TextStyle(fontSize: 12))
                        ]),
                        IconButton(
                            onPressed: () => setState(() => medidasCompletas++),
                            icon: Icon(Icons.add_circle,
                                size: 45, color: Colors.green[800])),
                      ]),
                ])),
            SizedBox(height: 10),
            Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  Text('LITROS RESTANTES (0 a 59L)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.orange[800])),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                            onPressed: () => setState(() => litrosRestantes >= 5
                                ? litrosRestantes -= 5
                                : litrosRestantes = 0),
                            icon: Icon(Icons.remove_circle_outline,
                                size: 35, color: Colors.orange[800])),
                        Column(children: [
                          Text('${litrosRestantes}L',
                              style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800])),
                          Text('+ ${litrosRestantes} litros soltos',
                              style: TextStyle(fontSize: 10))
                        ]),
                        IconButton(
                            onPressed: () => setState(() =>
                                litrosRestantes <= 54
                                    ? litrosRestantes += 5
                                    : litrosRestantes = 59),
                            icon: Icon(Icons.add_circle_outline,
                                size: 35, color: Colors.orange[800])),
                      ]),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (int v in [1, 10, 20, 30])
                      Padding(
                          padding: EdgeInsets.all(2),
                          child: ElevatedButton(
                              onPressed: () =>
                                  setState(() => litrosRestantes = v),
                              child: Text('${v}L'),
                              style: ElevatedButton.styleFrom(
                                  minimumSize: Size(50, 30))))
                  ]),
                ])),
            SizedBox(height: 10),
            Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Geral:'),
                        Text(
                            '$totalLitros L = ${totalDecimal.toStringAsFixed(2)} medidas',
                            style: TextStyle(fontWeight: FontWeight.bold))
                      ]),
                  Divider(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('VALOR A PAGAR:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('R\$ ${valorTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800]))
                      ]),
                ])),
            Spacer(),
            ElevatedButton(
                onPressed: colaboradorNome == null || totalLitros == 0
                    ? null
                    : () async {
                        await db.inserirColheita({
                          'colaboradorId': colaboradorId,
                          'talhaoId': 1,
                          'data':
                              DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          'qtdMedidas': totalDecimal,
                          'qtdLitros': totalLitros,
                          'valorTotal': valorTotal
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '$colaboradorNome - ${totalDecimal.toStringAsFixed(2)} medidas salvas!'),
                            backgroundColor: Colors.green[800]));
                        setState(() {
                          colaboradorNome = null;
                          medidasCompletas = 0;
                          litrosRestantes = 0;
                        });
                      },
                child: Text(
                    'CONFIRMAR ${totalDecimal.toStringAsFixed(2)} MEDIDAS = R\$${valorTotal.toStringAsFixed(2)}'),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 60),
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white)),
          ])),
    );
  }
}

class ColaboradoresPage extends StatefulWidget {
  @override
  State<ColaboradoresPage> createState() => _ColaboradoresPageState();
}

class _ColaboradoresPageState extends State<ColaboradoresPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> lista = [];
  @override
  void initState() {
    super.initState();
    carregar();
  }

  carregar() async {
    var l = await db.listarColaboradores();
    setState(() => lista = l);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Colaboradores (${lista.length}/30)'),
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white),
      body: ListView.builder(
          itemCount: lista.length,
          itemBuilder: (c, i) => ListTile(
              leading: CircleAvatar(child: Text(lista[i]['nome'][0])),
              title: Text(lista[i]['nome']),
              subtitle: Text('R\$35 / 60L | Pix: ${lista[i]['pix']}'),
              trailing: IconButton(
                  icon: Icon(Icons.qr_code),
                  onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                          title: Text(lista[i]['nome']),
                          content:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            QrImageView(data: lista[i]['qrCode'], size: 200),
                            SizedBox(height: 10),
                            Text(lista[i]['qrCode'],
                                style: TextStyle(fontSize: 10))
                          ])))))),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green[800],
          child: Icon(Icons.add, color: Colors.white),
          onPressed: () async {
            var nomeCtrl = TextEditingController();
            var pixCtrl = TextEditingController();
            await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                        title: Text('Novo Colhedor'),
                        content:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(
                              controller: nomeCtrl,
                              decoration:
                                  InputDecoration(labelText: 'Nome completo')),
                          TextField(
                              controller: pixCtrl,
                              decoration:
                                  InputDecoration(labelText: 'Chave Pix'))
                        ]),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                if (nomeCtrl.text.isEmpty) return;
                                var qr =
                                    'ID:${DateTime.now().millisecondsSinceEpoch}|NOME:${nomeCtrl.text.toUpperCase()}';
                                await db.inserirColaborador({
                                  'nome': nomeCtrl.text.toUpperCase(),
                                  'pix': pixCtrl.text,
                                  'valorMedida': 35.0,
                                  'qrCode': qr
                                });
                                carregar();
                                Navigator.pop(context);
                              },
                              child: Text('Salvar e Gerar QR'))
                        ]));
          }),
    );
  }
}

class RelatorioPage extends StatelessWidget {
  final db = DatabaseHelper();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Fechamento'),
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white),
      body: Center(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text('1. GERAR PDF SEMANAL\nEnvia no WhatsApp'),
                        onPressed: () async {
                          var hoje =
                              DateFormat('yyyy-MM-dd').format(DateTime.now());
                          var ranking = await db.rankingHoje(hoje);
                          if (ranking.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Nenhum lançamento hoje!')));
                            return;
                          }
                          await gerarPdfPagamentoSemanal(
                              semana: '02/09 a 07/09/2026',
                              ranking: ranking,
                              valorMedida: 35.0);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            minimumSize: Size(300, 80))),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                        icon: Icon(Icons.backup),
                        label: Text('2. ENVIAR BACKUP\nPara outro gestor'),
                        onPressed: () async {
                          await db.enviarBackupWhatsApp();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                            minimumSize: Size(300, 70))),
                    SizedBox(height: 20),
                    Text(
                        '60 Litros = 1 medida = R\$35,00\nEx: 90L = 1 medida + 30L = R\$52,50',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  ]))),
    );
  }
}

class ScannerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Aponte para o Crachá')),
        body: MobileScanner(onDetect: (cap) {
          final code = cap.barcodes.first.rawValue;
          if (code != null) Navigator.pop(context, code);
        }));
  }
}
