import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'db/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  final pages = [LancamentoPage(), ColaboradoresPage(), FazendasPage(), FechamentoPage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, type: BottomNavigationBarType.fixed,
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

// LANCAMENTO
class LancamentoPage extends StatefulWidget { @override State<LancamentoPage> createState() => _LancamentoPageState(); }
class _LancamentoPageState extends State<LancamentoPage> {
  final db = DatabaseHelper();
  String? nomeColab; int? idColab; Map<String, dynamic>? talhaoSel;
  List<Map<String, dynamic>> talhoes = [];
  TextEditingController litrosCtrl = TextEditingController();
  double valorPrev = 0;
  @override void initState(){super.initState(); _load();}
  _load() async { var l = await db.listarTodosTalhoes(); setState(() => talhoes = l); }
  void calc(){ double l = double.tryParse(litrosCtrl.text.replaceAll(',', '.'))??0; double p = talhaoSel==null?35.0:(talhaoSel!['precoMedida'] as num).toDouble(); setState(()=>valorPrev=(l/60)*p); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text('Lançar Colheita'), backgroundColor: Colors.green[800]),
      body: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        ElevatedButton.icon(icon: Icon(Icons.qr_code_scanner), label: Text('LER CRACHÁ'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity,50)), onPressed: () async {
          var code = await Navigator.push(context, MaterialPageRoute(builder: (_)=>ScannerPage()));
          if(code!=null){ var c=await db.getColaboradorByQr(code.toString()); if(c!=null) setState((){nomeColab=c['nome']; idColab=c['id'];}); }
        }),
        if(nomeColab!=null) Text('Colaborador: $nomeColab', style: TextStyle(fontWeight: FontWeight.bold, fontSize:18)),
        SizedBox(height:10),
        DropdownButtonFormField<Map<String,dynamic>>(decoration: InputDecoration(labelText: 'Talhão (com preço)', border: OutlineInputBorder()), value: talhaoSel,
          items: talhoes.map((t)=>DropdownMenuItem(value:t, child: Text("${t['fazendaNome']??''} - ${t['nome']} - R\$${t['precoMedida']}"))).toList(),
          onChanged:(v){setState(()=>talhaoSel=v); calc();}),
        SizedBox(height:10),
        TextField(controller: litrosCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText:'Litros', border: OutlineInputBorder()), onChanged:(_)=>calc()),
        SizedBox(height:10),
        Text('Valor: R\$ ${valorPrev.toStringAsFixed(2)}', style: TextStyle(fontSize:22, fontWeight:FontWeight.bold, color:Colors.green[800])),
        SizedBox(height:10),
        ElevatedButton(child: Text('SALVAR'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity,50), backgroundColor: Colors.green[800], foregroundColor: Colors.white),
          onPressed: () async {
            if(idColab==null||talhaoSel==null) return;
            double litros = double.tryParse(litrosCtrl.text.replaceAll(',', '.'))??0;
            await db.inserirColheita({'colaboradorId':idColab,'talhaoId':talhaoSel!['id'],'fazendaId':talhaoSel!['fazendaId'],'data':DateFormat('yyyy-MM-dd').format(DateTime.now()),'qtdLitros':litros.toInt(),'qtdMedidas':litros/60,'valorTotal':valorPrev});
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvo!'))); litrosCtrl.clear(); setState(()=>valorPrev=0);
          }),
      ])),
    );
  }
}

// FAZENDAS + TALHOES COM PRECO
class FazendasPage extends StatefulWidget { @override State<FazendasPage> createState()=>_FazendasPageState(); }
class _FazendasPageState extends State<FazendasPage>{
  final db=DatabaseHelper(); List<Map<String,dynamic>> faz=[];
  @override void initState(){super.initState(); load();}
  load() async { var l=await db.listarFazendas(); setState(()=>faz=l); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text('Fazendas'), backgroundColor: Colors.green[800]),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.green[800], child: Icon(Icons.add), onPressed: () async {
        var n=TextEditingController(); var p=TextEditingController();
        await showDialog(context: context, builder: (_)=>AlertDialog(title: Text('Nova Fazenda'), content: Column(mainAxisSize: MainAxisSize.min, children:[TextField(controller:n, decoration: InputDecoration(labelText:'Nome *')), TextField(controller:p, decoration: InputDecoration(labelText:'Proprietário'))]),
          actions:[TextButton(onPressed:() async {await db.inserirFazenda({'nome':n.text,'proprietario':p.text}); load(); Navigator.pop(context);}, child: Text('Salvar'))]));
      }),
      body: ListView.builder(itemCount: faz.length, itemBuilder: (_,i)=>ListTile(title: Text(faz[i]['nome'], style: TextStyle(fontWeight:FontWeight.bold)), subtitle: Text(faz[i]['proprietario']??''), trailing: Icon(Icons.chevron_right),
        onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>TalhoesPage(fazendaId:faz[i]['id'], fazendaNome:faz[i]['nome']))).then((_)=>load()))),
    );
  }
}
class TalhoesPage extends StatefulWidget { final int fazendaId; final String fazendaNome; const TalhoesPage({required this.fazendaId, required this.fazendaNome}); @override State<TalhoesPage> createState()=>_TalhoesPageState();}
class _TalhoesPageState extends State<TalhoesPage>{
  final db=DatabaseHelper(); List<Map<String,dynamic>> tal=[];
  @override void initState(){super.initState(); load();}
  load() async { var l=await db.listarTalhoesPorFazenda(widget.fazendaId); setState(()=>tal=l); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text(widget.fazendaNome), backgroundColor: Colors.green[800]),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.green[800], child: Icon(Icons.add), onPressed: () async {
        var n=TextEditingController(); var v=TextEditingController(); var pr=TextEditingController(text:'35.00');
        await showDialog(context: context, builder: (_)=>AlertDialog(title: Text('Novo Talhão'), content: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller:n, decoration: InputDecoration(labelText:'Nome *')), TextField(controller:v, decoration: InputDecoration(labelText:'Variedade')), TextField(controller:pr, decoration: InputDecoration(labelText:'Preço medida 60L R\$'), keyboardType: TextInputType.number),
        ]), actions:[TextButton(onPressed:() async {await db.inserirTalhao({'fazendaId':widget.fazendaId,'nome':n.text,'variedade':v.text,'precoMedida':double.tryParse(pr.text.replaceAll(',', '.'))??35.0}); load(); Navigator.pop(context);}, child: Text('Salvar'))]));
      }),
      body: ListView.builder(itemCount: tal.length, itemBuilder: (_,i)=>ListTile(leading: Icon(Icons.grass, color:Colors.green), title: Text(tal[i]['nome']), subtitle: Text(tal[i]['variedade']??''), trailing: Chip(label: Text('R\$ ${tal[i]['precoMedida']}')))),
    );
  }
}

// COLABORADORES - VOLTOU O BOTAO CADASTRAR
class ColaboradoresPage extends StatefulWidget { @override State<ColaboradoresPage> createState()=>_ColabState();}
class _ColabState extends State<ColaboradoresPage>{
  final db=DatabaseHelper(); List<Map<String,dynamic>> lista=[];
  @override void initState(){super.initState(); load();}
  load() async { var l=await db.listarColaboradores(); setState(()=>lista=l); }
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text('Colaboradores'), backgroundColor: Colors.green[800]),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: Colors.green[800], icon: Icon(Icons.person_add), label: Text('Cadastrar'), onPressed: () async {
        var nome=TextEditingController(); var pix=TextEditingController(); var qr=TextEditingController();
        await showDialog(context: context, builder: (_)=>AlertDialog(title: Text('Novo Colaborador'), content: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller:nome, decoration: InputDecoration(labelText:'Nome *')), TextField(controller:pix, decoration: InputDecoration(labelText:'PIX')), TextField(controller:qr, decoration: InputDecoration(labelText:'Código Crachá / QR *')),
        ]), actions:[TextButton(onPressed:() async { if(nome.text.isEmpty||qr.text.isEmpty) return; await db.inserirColaborador({'nome':nome.text,'pix':pix.text,'qrCode':qr.text,'valorMedida':35.0}); load(); Navigator.pop(context); }, child: Text('Salvar'))]));
      }),
      body: ListView.builder(itemCount: lista.length, itemBuilder: (_,i)=>ListTile(leading: Icon(Icons.badge), title: Text(lista[i]['nome']), subtitle: Text('PIX: ${lista[i]['pix']??'-'} | QR: ${lista[i]['qrCode']}'), trailing: IconButton(icon: Icon(Icons.delete, color:Colors.red), onPressed: () async { await db.deletarColaborador(lista[i]['id']); load(); }))),
    );
  }
}

// FECHAMENTO - VOLTOU O PDF + BACKUP
class FechamentoPage extends StatefulWidget { @override State<FechamentoPage> createState()=>_FechState();}
class _FechState extends State<FechamentoPage>{
  final db=DatabaseHelper(); String data = DateFormat('yyyy-MM-dd').format(DateTime.now()); List<Map<String,dynamic>> ranking=[];
  @override void initState(){super.initState(); load();}
  load() async { var r=await db.rankingHoje(data); setState(()=>ranking=r); }

  Future<void> gerarPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context c)=>pw.Column(children:[
      pw.Text('Fechamento - $data - Café Gestor', style: pw.TextStyle(fontSize:20, fontWeight:pw.FontWeight.bold)),
      pw.SizedBox(height:20),
      pw.Table.fromTextArray(headers:['Nome','Litros','Medidas','Valor'], data: ranking.map((e)=>[e['nome'].toString(), e['totalLitros'].toString(), (e['totalMedidas'] as num).toStringAsFixed(2), 'R\$ ${(e['totalValor'] as num).toStringAsFixed(2)}']).toList()),
      pw.SizedBox(height:20),
      pw.Text('60 Litros = 1 medida = R\$35,00 base (pode variar por talhão)', style: pw.TextStyle(fontSize:10)),
    ])));
    await Printing.layoutPdf(onLayout: (f)=>pdf.save());
  }

  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text('Fechamento'), backgroundColor: Colors.green[800],
      actions:[IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: gerarPdf)]),
      body: Column(children:[
        Padding(padding: EdgeInsets.all(8), child: Row(children:[
          Expanded(child: Text('Data: $data', style: TextStyle(fontWeight:FontWeight.bold))),
          ElevatedButton(onPressed:() async { var d=await showDatePicker(context:context, firstDate:DateTime(2023), lastDate:DateTime(2030), initialDate:DateTime.now()); if(d!=null){ setState(()=>data=DateFormat('yyyy-MM-dd').format(d)); load(); } }, child: Text('Trocar data'))
        ])),
        Expanded(child: ListView.builder(itemCount: ranking.length, itemBuilder: (_,i)=>ListTile(title: Text(ranking[i]['nome']), subtitle: Text('${ranking[i]['totalLitros']} L - ${ (ranking[i]['totalMedidas'] as num).toStringAsFixed(2)} medidas'), trailing: Text('R\$ ${(ranking[i]['totalValor'] as num).toStringAsFixed(2)}', style: TextStyle(fontWeight:FontWeight.bold))))),
        Padding(padding: EdgeInsets.all(16), child: Column(children:[
          ElevatedButton.icon(icon: Icon(Icons.picture_as_pdf), label: Text('1. GERAR PDF DO DIA'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, minimumSize: Size(300,50)), onPressed: gerarPdf),
          SizedBox(height:10),
          ElevatedButton.icon(icon: Icon(Icons.backup), label: Text('2. ENVIAR BACKUP\nPara outro gestor'), onPressed: () async { await db.enviarBackupWhatsApp(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, minimumSize: Size(300,70))),
          SizedBox(height:10),
          Text('60 Litros = 1 medida = R\$35,00\nEx: 90L = 1 medida + 30L = R\$52,50', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ])),
      ]),
    );
  }
}

class ScannerPage extends StatelessWidget {
  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text('Aponte para o Crachá')), body: MobileScanner(onDetect: (cap){ final code=cap.barcodes.first.rawValue; if(code!=null) Navigator.pop(context, code); }));
  }
}
