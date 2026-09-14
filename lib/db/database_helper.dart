import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DatabaseHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db!= null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'cafe_gestor.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int v) async {
        await db.execute('CREATE TABLE colaboradores(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT, pix TEXT, valorMedida REAL, qrCode TEXT)');
        await db.execute('CREATE TABLE fazendas(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT, proprietario TEXT)');
        await db.execute('CREATE TABLE talhoes(id INTEGER PRIMARY KEY AUTOINCREMENT, fazendaId INTEGER, nome TEXT, variedade TEXT, precoMedida REAL DEFAULT 35.0)');
        await db.execute('CREATE TABLE colheitas(id INTEGER PRIMARY KEY AUTOINCREMENT, colaboradorId INTEGER, talhaoId INTEGER, fazendaId INTEGER, data TEXT, qtdMedidas REAL, qtdLitros INTEGER, valorTotal REAL)');
      },
      onUpgrade: (Database db, int oldV, int newV) async {
        if (oldV < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS fazendas(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT, proprietario TEXT)');
          await db.execute('CREATE TABLE IF NOT EXISTS talhoes(id INTEGER PRIMARY KEY AUTOINCREMENT, fazendaId INTEGER, nome TEXT, variedade TEXT, precoMedida REAL DEFAULT 35.0)');
        }
      },
    );
  }

  Future<int> inserirColaborador(Map<String, dynamic> c) async {
    final d = await db;
    return await d.insert('colaboradores', c);
  }

  Future<List<Map<String, dynamic>>> listarColaboradores() async {
    final d = await db;
    return await d.query('colaboradores');
  }

  Future<Map<String, dynamic>?> getColaboradorByQr(String qr) async {
    final d = await db;
    var r = await d.query('colaboradores', where: 'qrCode =?', whereArgs: [qr]);
    return r.isNotEmpty? r.first : null;
  }

  Future<int> inserirFazenda(Map<String, dynamic> f) async {
    final d = await db;
    return await d.insert('fazendas', f);
  }

  Future<List<Map<String, dynamic>>> listarFazendas() async {
    final d = await db;
    return await d.query('fazendas', orderBy: 'nome');
  }

  Future<int> inserirTalhao(Map<String, dynamic> t) async {
    final d = await db;
    return await d.insert('talhoes', t);
  }

  Future<List<Map<String, dynamic>>> listarTalhoesPorFazenda(int id) async {
    final d = await db;
    return await d.query('talhoes', where: 'fazendaId =?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listarTodosTalhoes() async {
    final d = await db;
    var r = await d.rawQuery('SELECT t.*, f.nome as fazendaNome FROM talhoes t LEFT JOIN fazendas f ON t.fazendaId = f.id ORDER BY f.nome, t.nome');
    return r;
  }

  Future<int> inserirColheita(Map<String, dynamic> c) async {
    final d = await db;
    return await d.insert('colheitas', c);
  }

  Future<List<Map<String, dynamic>>> rankingHoje(String data) async {
    final d = await db;
    var r = await d.rawQuery('SELECT col.nome, col.pix, SUM(co.qtdMedidas) as totalMedidas, SUM(co.qtdLitros) as totalLitros, SUM(co.valorTotal) as totalValor FROM colheitas co JOIN colaboradores col ON co.colaboradorId = col.id WHERE co.data =? GROUP BY col.id ORDER BY totalMedidas DESC', [data]);
    return r;
  }

  Future<void> enviarBackupWhatsApp() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cafe_gestor.db');
    final file = File(path);
    if (await file.exists()) {
      final tempDir = await getTemporaryDirectory();
      final backupFile = await file.copy('${tempDir.path}/backup.db');
      await Share.shareXFiles([XFile(backupFile.path)], text: 'Backup CafeGestor');
    }
  }

  Future<int> deletarColaborador(int id) async {
    final d = await db;
    return await d.delete('colaboradores', where: 'id =?', whereArgs: [id]);
  }

  Future<int> deletarFazenda(int id) async {
    final d = await db;
    return await d.delete('fazendas', where: 'id =?', whereArgs: [id]);
  }

  Future<int> deletarTalhao(int id) async {
    final d = await db;
    return await d.delete('talhoes', where: 'id =?', whereArgs: [id]);
  }
}
