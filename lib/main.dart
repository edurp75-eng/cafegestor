import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'db/database_helper.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.green),
    home: CafeGestorHome(),
  ));
}

class CafeGestorHome extends StatefulWidget {
  @override
  State<CafeGestorHome> createState() => _CafeGestorHomeState();
}

class _CafeGestorHomeState extends State<CafeGestorHome> {
  int _idx = 0;
  final db = DatabaseHelper();

  final List<Widget> _pages = [
    LancamentoPage(),
    ColaboradoresPage(),
    FazendasPage(),
    FechamentoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[800],
        onTap: (i) => setState(() => _idx = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Lançar'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Equipe'),
          BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Fazendas'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Fechar'),
        ],
      ),
    );
  }
}

// ---------------- LANÇAMENTO COM TALHÃO E PREÇO ----------------
class LancamentoPage extends StatefulWidget {
  @override
  State<LancamentoPage> createState() => _LancamentoPageState();
}

class _LancamentoPageState extends State<LancamentoPage> {
  final db = DatabaseHelper();
  String? colaboradorNome;
  int? colaboradorId;
  Map<String, dynamic>? talhaoSel;
  List<Map<String, dynamic>> talhoes = [];
  TextEditingController litrosCtrl = TextEditingController();
  double valorPrev = 0;

  @override
  void initState() {
    super.initState();
    _loadTalhoes();
  }

  _loadTalhoes() async {
    var l = await db.listarTodosTalhoes();
    setState(() => talhoes = l);
  }

  void _calcular() {
    double litros = double.tryParse(litrosCtrl.text.replaceAll(',', '.'))?? 0;
    double precoMed = 35.0;
    if (talhaoSel!= null) precoMed = (talhaoSel!['precoMedida'] as num).toDouble();
    // regra que você já usava: 60L = 1 medida
    double valor = (litros / 60) * precoMed;
    setState(() => valorPrev = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lançar Colheita'), backgroundColor: Colors.green[800]),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.qr_code_scanner),
              label: Text('LER CRACHÁ'),
              onPressed: () async {
                var code = await Navigator.push(context, MaterialPageRoute(builder: (_) => ScannerPage()));
                if (code!= null) {
                  var colab = await db.getColaboradorByQr(code);
                  if (colab!= null) setState(() { colaboradorNome = colab['nome']; colaboradorId = colab['id']; });
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
            if (colaboradorNome!= null) Padding(padding: EdgeInsets.all(8), child: Text('Colaborador: $colaboradorNome', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            SizedBox(height: 10),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(labelText: 'Talhão * - já com preço', border: OutlineInputBorder()),
              value: talhaoSel,
              items: talhoes.map((t) => DropdownMenuItem(value: t, child: Text("${t['fazendaNome']?? ''} - ${t['nome']} - R\$${t['precoMedida']}"))).toList(),
              onChanged: (v) { setState(() => talhaoSel = v); _calcular(); },
            ),
            SizedBox(height: 10),
            TextField(
              controller: litrosCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Litros colhidos', border: OutlineInputBorder()),
              onChanged: (_) => _calcular(),
            ),
            SizedBox(height: 10),
            Text('Valor: R\$ ${valorPrev.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800])),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (colaboradorId == null || talhaoSel == null) return;
                double litros = double.tryParse(litrosCtrl.text.replaceAll(',', '.'))?? 0;
                await db.inserirColheita({
                  'colaboradorId': colaboradorId,
                  'talhaoId': talhaoSel!['id'],
                  'data': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'qtdLitros': litros,
                  'qtdMedidas': litros / 60,
                  'valorTotal': valorPrev,
                  'fazendaId': talhaoSel!['fazendaId'],
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvo!')));
                litrosCtrl.clear();
                setState(() => valorPrev = 0);
              },
              child: Text('SALVAR'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.green[800], foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- FAZENDAS ----------------
class FazendasPage extends StatefulWidget {
  @override
  State<FazendasPage> createState() => _FazendasPageState();
}

class _FazendasPageState extends State<FazendasPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> fazendas = [];
  @override
  void initState() { super.initState(); load(); }
  load() async { var l = await db.listarFazendas(); setState(() => fazendas = l); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fazendas'), backgroundColor: Colors.green[800]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[800],
        child: Icon(Icons.add),
        onPressed: () async {
          var nomeCtrl = TextEditingController();
          var propCtrl = TextEditingController();
          await showDialog(context: context, builder: (_) => AlertDialog(
            title: Text('Nova Fazenda'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nomeCtrl, decoration: InputDecoration(labelText: 'Nome *')),
              TextField(controller: propCtrl, decoration: InputDecoration(labelText: 'Proprietário')),
            ]),
            actions: [TextButton(onPressed: () async { await db.inserirFazenda({'nome': nomeCtrl.text, 'proprietario': propCtrl.text}); load(); Navigator.pop(context); }, child: Text('Salvar'))],
          ));
        },
      ),
      body: ListView.builder(
        itemCount: fazendas.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(fazendas[i]['nome'], style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(fazendas[i]['proprietario']?? ''),
          trailing: Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TalhoesPage(fazendaId: fazendas[i]['id'], fazendaNome: fazendas[i]['nome']))).then((_) => load()),
        ),
      ),
    );
  }
}

class TalhoesPage extends StatefulWidget {
  final int fazendaId; final String fazendaNome;
  TalhoesPage({required this.fazendaId, required this.fazendaNome});
  @override
  State<TalhoesPage> createState() => _TalhoesPageState();
}

class _TalhoesPageState extends State<TalhoesPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> talhoes = [];
  @override
  void initState() { super.initState(); load(); }
  load() async { var l = await db.listarTalhoesPorFazenda(widget.fazendaId); setState(() => talhoes = l); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fazendaNome), backgroundColor: Colors.green[800]),
      floatingActionButton: FloatingActionButton(
