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
  final pages = [
    LancamentoPage(),
    ColaboradoresPage(),
    FazendasPage(),
    FechamentoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[800],
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Lançar'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Equipe'),
          BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Fazendas'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Fechar'),
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
  final db = DatabaseHelper();
  String? nomeColab;
  int? idColab;
  Map<String, dynamic>? talhaoSel;
  List<Map<String, dynamic>> talhoes = [];
  TextEditingController litrosCtrl = TextEditingController();
  double valorPrev = 0;

  @override
  void initState() {
    super.initState();
    carregarTalhoes();
  }

  Future<void> carregarTalhoes() async {
    var l = await db.listarTodosTalhoes();
    setState(() => talhoes = l);
  }

  void calcular() {
    double litros = double.tryParse(litrosCtrl.text.replaceAll(',', '.'))?? 0;
    double preco = 35.0;
    if (talhaoSel!= null) preco = (talhaoSel!['precoMedida'] as num).toDouble();
    setState(() => valorPrev = (litros / 60) * preco);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançar Colheita'), backgroundColor: Colors.green[800]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('LER CRACHÁ'),
              onPressed: () async {
                var code = await Navigator.push(context, MaterialPageRoute(builder: (_) => ScannerPage()));
                if (code!= null) {
                  var colab = await db.getColaboradorByQr(code.toString());
                  if (colab!= null) setState(() { nomeColab = colab['nome']; idColab = colab['id']; });
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            if (nomeColab!= null) Padding(padding: const EdgeInsets.all(8), child: Text('Colaborador: $nomeColab', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 10),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: const InputDecoration(labelText: 'Talhão * - com preço', border: OutlineInputBorder()),
              value: talhaoSel,
              items: talhoes.map((t) => DropdownMenuItem(value: t, child: Text("${t['fazendaNome']?? ''} - ${t['nome']} - R\$${t['precoMedida']}"))).toList(),
              onChanged: (v) { setState(() => talhaoSel = v); calcular(); },
            ),
            const SizedBox(height: 10),
            TextField(controller: litrosCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Litros colhidos', border: OutlineInputBorder()), onChanged: (_) => calcular()),
            const SizedBox(height: 10),
            Text('Valor: R\$ ${valorPrev.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800])),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (idColab == null || talhaoSel == null) return;
                double litros = double.tryParse(litrosCtrl.text.replaceAll(',', '.'))?? 0;
                await db.inserirColheita({
                  'colaboradorId': idColab,
                  'talhaoId': talhaoSel!['id'],
                  'fazendaId': talhaoSel!['fazendaId'],
                  'data': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'qtdLitros': litros.toInt(),
                  'qtdMedidas': litros / 60,
                  'valorTotal': valorPrev,
                });
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo!')));
                litrosCtrl.clear();
                setState(() => valorPrev = 0);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green[800], foregroundColor: Colors.white),
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }
}

class FazendasPage extends StatefulWidget {
  @override
  State<FazendasPage> createState() => _FazendasPageState();
}

class _FazendasPageState extends State<FazendasPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> fazendas = [];
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async { var l = await db.listarFazendas(); setState(() => fazendas = l); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fazendas'), backgroundColor: Colors.green[800]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.add),
        onPressed: () async {
          var nomeCtrl = TextEditingController();
          var propCtrl = TextEditingController();
          await showDialog(context: context, builder: (_) => AlertDialog(
            title: const Text('Nova Fazenda'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome *')),
              TextField(controller: propCtrl, decoration: const InputDecoration(labelText: 'Proprietário')),
            ]),
            actions: [TextButton(onPressed: () async { await db.inserirFazenda({'nome': nomeCtrl.text, 'proprietario': propCtrl.text}); load(); if(context.mounted) Navigator.pop(context); }, child: const Text('Salvar'))],
          ));
        },
      ),
      body: ListView.builder(
        itemCount: fazendas.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(fazendas[i]['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(fazendas[i]['proprietario']?? ''),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TalhoesPage(fazendaId: fazendas[i]['id'], fazendaNome: fazendas[i]['nome']))).then((_) => load()),
        ),
      ),
    );
  }
}

class TalhoesPage extends StatefulWidget {
  final int fazendaId; final String fazendaNome;
  const TalhoesPage({required this.fazendaId, required this.fazendaNome});
  @override
  State<TalhoesPage> createState() => _TalhoesPageState();
}

class _TalhoesPageState extends State<TalhoesPage> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> talhoes = [];
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async { var l = await db.listarTalhoesPorFazenda(widget.fazendaId); setState(() => talhoes = l); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fazendaNome), backgroundColor: Colors.green[800]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.add),
        onPressed: () async {
          var nomeCtrl = TextEditingController();
          var varCtrl = TextEditingController();
          var precoCtrl = TextEditingController(text: '35.00');
          await showDialog(context: context, builder: (_) => AlertDialog(
            title: const Text('Novo Talhão'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome Ex: Talhão 01 *')),
              TextField(controller: varCtrl, decoration: const InputDecoration(labelText: 'Variedade')),
              TextField(controller: precoCtrl, decoration: const InputDecoration(labelText: 'Preço por medida 60L R\$'), keyboardType: TextInputType.number),
            ]),
            actions: [TextButton(onPressed: () async { await db.inserirTalhao({'fazendaId': widget.fazendaId, 'nome': nomeCtrl.text, 'variedade': varCtrl.text, 'precoMedida': double.tryParse(precoCtrl.text.replaceAll(',', '.'))?? 35.0}); load(); if(context.mounted) Navigator.pop(context); }, child: const Text('Salvar'))],
          ));
        },
      ),
      body: ListView.builder(
        itemCount: talhoes.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.grass, color: Colors.green),
          title: Text(talhoes[i]['nome']),
          subtitle: Text(talhoes[i]['variedade']?? ''),
          trailing: Chip(label: Text('R\$ ${talhoes[i]['precoMedida']}'), backgroundColor: Colors.green.shade100),
        ),
      ),
    );
  }
}

class ColaboradoresPage extends StatelessWidget {
  final db = DatabaseHelper();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: db.listarColaboradores(),
      builder: (c, AsyncSnapshot<List<Map<String, dynamic>>> s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return Scaffold(
          appBar: AppBar(title: const Text('Colaboradores'), backgroundColor: Colors.green[800]),
          body: ListView(children: s.data!.map((e) => ListTile(title: Text(e['nome'].toString()))).toList()),
        );
      },
    );
  }
}

class FechamentoPage extends StatelessWidget {
  final db = DatabaseHelper();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fechamento'), backgroundColor: Colors.green[800]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text('2. ENVIAR BACKUP\nPara outro gestor'),
              onPressed: () async { await db.enviarBackupWhatsApp(); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, minimumSize: const Size(300, 70)),
            ),
            const SizedBox(height: 20),
            const Text('60 Litros = 1 medida = R\$35,00\nEx: 90L = 1 medida + 30L = R\$52,50', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class ScannerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aponte para o Crachá')),
      body: MobileScanner(onDetect: (cap) {
        final code = cap.barcodes.first.rawValue;
        if (code!= null) Navigator.pop(context, code);
      }),
    );
  }
}
