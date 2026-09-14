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
    return await openDatabase(path, version: 2, onCreate: (db, v) async {
      await _criarTabelas(db);
    }, onUpgrade: (db, oldV, newV) async {
      if (oldV < 2) {
        // cria novas tabelas se já tem banco antigo instalado
        await db.execute('''
          CREATE TABLE IF NOT EXISTS fazendas(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT,
            proprietario TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS talhoes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fazendaId INTEGER,
            nome TEXT,
            variedade TEXT,
            precoMedida REAL DEFAULT 35.0
          )
        ''');
        // adiciona colunas novas na colheita se não existirem
        try { await db.execute('ALTER TABLE colheitas ADD COLUMN fazendaId INTEGER'); } catch(e){}
      }
    });
  }

  Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE colaboradores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        pix TEXT,
        valorMedida REAL,
        qrCode TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE fazendas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        proprietario TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE talhoes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fazendaId INTEGER,
        nome TEXT,
        variedade TEXT,
        precoMedida REAL DEFAULT 35.0
      )
    ''');
    await db.execute('''
      CREATE TABLE colheitas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        colaboradorId INTEGER,
        talhaoId INTEGER,
        fazendaId INTEGER,
        data TEXT,
        qtdMedidas REAL,
        qtdLitros INTEGER,
        valorTotal REAL
      )
    ''');
  }

  // COLABORADORES
  Future<int> inserirColaborador(Map<String, dynamic> c) async {
    final database = await db;
    return await database.insert('colaboradores', c);
  }
  Future<List<Map<String, dynamic>>> listarColaboradores() async {
    final database = await db;
    return await database.query('colaboradores');
  }
  Future<Map<String, dynamic>?> getColaboradorByQr(String qr) async {
    final database = await db;
    var res = await database.query('colaboradores', where: 'qrCode =?', whereArgs: [qr]);
    return res.isNotEmpty? res.first : null;
  }

  // FAZENDAS
  Future<int> inserirFazenda(Map<String, dynamic> f) async {
    final database = await db;
    return await database.insert('fazendas', f);
  }
  Future<List<Map<String, dynamic>>> listarFazendas() async {
    final database = await db;
    return await database.query('fazendas', orderBy: 'nome');
  }

  // TALHÕES
  Future<int> inserirTalhao(Map<String, dynamic> t) async {
    final database = await db;
    return await database.insert('talhoes', t);
  }
  Future<List<Map<String, dynamic>>> listarTalhoesPorFazenda(int fazendaId) async {
    final database = await db;
    return await database.query('talhoes', where: 'fazendaId =?', whereArgs: [fazendaId]);
  }
  Future<List<Map<String, dynamic>>> listarTodosTalhoes() async {
    final database = await db;
    var res = await database.rawQuery('''
      SELECT t.*, f.nome as fazendaNome FROM talhoes t
      LEFT JOIN fazendas f ON t.fazendaId = f.id
      ORDER BY f.nome, t.nome
    ''');
    return res;
  }

  // COLHEITAS
  Future<int> inserirColheita(Map<String, dynamic> c) async {
    final database = await db;
    return await database.insert('colheitas', c);
  }

  Future<List<Map<String, dynamic>>> rankingHoje(String data) async {
    final database = await db;
    var res = await database.rawQuery('''
      SELECT col.nome, col.pix, SUM(co.qtdMedidas) as totalMedidas, SUM(co.qtdLitros) as totalLitros, SUM(co.valorTotal) as totalValor
      FROM colheitas co JOIN colaboradores col ON co.colaboradorId = col.id
      WHERE co.data =? GROUP BY col.id ORDER BY totalMedidas DESC
    ''', [data]);
    return res;
  }

  Future<void> enviarBackupWhatsApp() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cafe_gestor.db');
    final file = File(path);
    if (await file.exists()) {
      final tempDir = await getTemporaryDirectory();
      final backupFile = await file.copy('${tempDir.path}/backup_vargem_${DateTime.now().day}.db');
      await Share.shareXFiles([XFile(backupFile.path)], text: 'Backup CafeGestor 60L - R\$35/medida - Vargem Grande');
    }
  }
}
