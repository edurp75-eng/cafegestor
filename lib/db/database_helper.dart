import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DatabaseHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'cafe_gestor.db');
    return await openDatabase(path, version: 1, onCreate: (db, v) async {
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
        CREATE TABLE colheitas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          colaboradorId INTEGER,
          talhaoId INTEGER,
          data TEXT,
          qtdMedidas REAL,
          qtdLitros INTEGER,
          valorTotal REAL
        )
      ''');
    });
  }

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
    var res = await database
        .query('colaboradores', where: 'qrCode =?', whereArgs: [qr]);
    return res.isNotEmpty ? res.first : null;
  }

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
      final backupFile = await file
          .copy('${tempDir.path}/backup_vargem_${DateTime.now().day}.db');
      await Share.shareXFiles([XFile(backupFile.path)],
          text: 'Backup CafeGestor 60L - R\$35/medida - Vargem Grande');
    }
  }
}
