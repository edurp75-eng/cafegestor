import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CafeGestorApp(),
    theme: ThemeData(primarySwatch: Colors.green),
  ));
}

class CafeGestorApp extends StatefulWidget {
  @override
  State<CafeGestorApp> createState() => _CafeGestorAppState();
}

class _CafeGestorAppState extends State<CafeGestorApp> {
  int _index = 0;

  final pages = [
    LancarScreen(),
    ColaboradoresScreen(),
    FazendasScreen(), // NOVO
    FecharScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Lançar'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Colab.'),
          BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Fazendas'),
          BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: 'Fechar'),
        ],
      ),
    );
  }
}

// ------------------- TELA LANÇAR -------------------
class LancarScreen extends StatefulWidget {
  @override
  State<LancarScreen> createState() => _LancarScreenState();
}

class _LancarScreenState extends State<LancarScreen> {
  String? colaboradorNome;
  int? colaboradorId;
  Map<String, dynamic>? talhaoSelecionado;
  List<Map<String, dynamic>> talhoes = [];
  final medidasCtrl = TextEditingController(text: '1');
  double valorCalculado = 35.0;

  @override
  void initState() {
    super.initState();
    carregarTalhoes();
  }

  carregarTalhoes() async {
    var lista = await DatabaseHelper().listarTodosTalhoes();
    setState(() => talhoes = lista);
  }

  calcularValor() {
    if (talhaoSelecionado!= null) {
      double preco = (talhaoSelecionado!['precoMedida'] as num).toDouble();
      double qtd = double.tryParse(medidasCtrl.text.replaceAll(',', '.'))?? 0;
      setState(() => valorCalculado = preco * qtd);
    }
  }

  salvar() async {
    if (colaboradorId == null || talhaoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Escolha colaborador e talhão!')));
      return;
    }
    double qtdMed = double.tryParse(medidasCtrl.text.replaceAll(',', '.'))?? 0;
    int qtdLitros = (qtdMed * 60).toInt();
    await DatabaseHelper().inserirColheita({
      'colaboradorId': colaboradorId,
      'talhaoId': talhaoSelecionado!['id'],
      'data': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'qtdMedidas': qtdMed,
      'qtdLitros': qtdLitros,
      'valorTotal': valorCalculado,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvo! R\$ ${valorCalculado.toStringAsFixed(2)}')));
  }

  escanearQr() async {
    // Aqui você já tem seu scanner, só simula busca por QR
    // Mantém sua lógica atual de QR
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lançar Medida - 60L'), backgroundColor: Colors.green),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // SELETOR DE TALHÃO COM PREÇO
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(labelText: 'Talhão * (com preço)', border: OutlineInputBorder()),
              items: talhoes.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text('${t['nome']} - R\$ ${t['precoMedida']}/med'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => talhaoSelecionado = val);
                calcularValor();
              },
            ),
            SizedBox(height: 12),
            TextField(
              controller: medidasCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Qtd Medidas 60L', border: OutlineInputBorder()),
              onChanged: (_) => calcularValor(),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('VALOR TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('R\$ ${valorCalculado.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              ]),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: salvar,
              icon: Icon(Icons.save),
              label: Text('SALVAR LANÇAMENTO'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- FAZENDAS E TALHÕES -------------------
class FazendasScreen extends StatefulWidget {
  @override
  State<FazendasScreen> createState() => _FazendasScreenState();
}

class _FazendasScreenState extends State<FazendasScreen> {
  List<Map<String, dynamic>> fazendas = [];
  final nomeCtrl = TextEditingController();
  final propCtrl = TextEditingController();

  @override
  void initState() { super.initState(); carregar(); }
  carregar() async {
    var lista = await DatabaseHelper().listarFazendas();
    setState(() => fazendas = lista);
  }

  salvar() async {
    if (nomeCtrl.text.isEmpty) return;
    await DatabaseHelper().inserirFazenda({'nome': nomeCtrl.text, 'proprietario': propCtrl.text, 'cidade': 'Vargem Grande', 'areaTotal': 0});
    nomeCtrl.clear(); propCtrl.clear(); carregar(); Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fazendas'), backgroundColor: Colors.green),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
          title: Text('Nova Fazenda'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nomeCtrl, decoration: InputDecoration(labelText: 'Nome da Fazenda *')),
            TextField(controller: propCtrl, decoration: InputDecoration(labelText: 'Proprietário')),
          ]),
          actions: [TextButton(onPressed: salvar, child: Text('SALVAR'))],
        )),
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: fazendas.length,
        itemBuilder: (_, i) => ListTile(
          leading: Icon(Icons.landscape, color: Colors.green, size: 40),
          title: Text(fazendas[i]['nome'], style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(fazendas[i]['proprietario']?? ''),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TalhoesScreen(fazendaId: fazendas[i]['id'], fazendaNome: fazendas[i]['nome']))),
        ),
      ),
    );
  }
}

class TalhoesScreen extends StatefulWidget {
  final int fazendaId;
  final String fazendaNome;
  TalhoesScreen({required this.fazendaId, required this.fazendaNome});
  @override
  State<TalhoesScreen> createState() => _TalhoesScreenState();
}

class _TalhoesScreenState extends State<TalhoesScreen> {
  List<Map<String, dynamic>> talhoes = [];
  final nomeCtrl = TextEditingController();
  final variedadeCtrl = TextEditingController();
  final precoCtrl = TextEditingController(text: '35.00');

  @override
  void initState() { super.initState(); carregar(); }
  carregar() async {
    var lista = await DatabaseHelper().listarTalhoesPorFazenda(widget.fazendaId);
    setState(() => talhoes = lista);
  }

  salvar() async {
    if (nomeCtrl.text.isEmpty) return;
    await DatabaseHelper().inserirTalhao({
      'fazendaId': widget.fazendaId,
      'nome': nomeCtrl.text,
      'variedade': variedadeCtrl.text,
      'precoMedida': double.tryParse(precoCtrl.text.replaceAll(',', '.'))?? 35.0,
      'qtdPes': 0,
      'area': 0.0,
    });
    nomeCtrl.clear(); variedadeCtrl.clear(); precoCtrl.text='35.00';
    carregar(); Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fazendaNome), backgroundColor: Colors.green),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
          title: Text('Novo Talhão'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nomeCtrl, decoration: InputDecoration(labelText: 'Nome Ex: Talhão 01 *')),
            TextField(controller: variedadeCtrl, decoration: InputDecoration(labelText: 'Variedade')),
            TextField(controller: precoCtrl, decoration: InputDecoration(labelText: 'Preço por Medida 60L R\$ *'), keyboardType: TextInputType.number),
          ]),
          actions: [TextButton(onPressed: salvar, child: Text('SALVAR'))],
        )),
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: talhoes.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(talhoes[i]['nome'], style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(talhoes[i]['variedade']?? ''),
          trailing: Chip(label: Text('R\$ ${talhoes[i]['precoMedida']}'), backgroundColor: Colors.green.shade100),
        ),
      ),
    );
  }
}

// ------------------- MANTÉM SUAS TELAS ANTIGAS -------------------
class ColaboradoresScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Colaboradores')), body: Center(child: Text('Sua tela de colaboradores aqui')));
}
class FecharScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Fechamento')), body: Center(child: Text('Sua tela de fechamento/ranking aqui')));
}
