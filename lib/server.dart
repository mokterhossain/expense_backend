import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'dart:convert';

class ExpenseService {
  final PostgreSQLConnection _connection;

  ExpenseService(this._connection);

  Future<void> initDatabase() async {
    await _connection.open();
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        date DATE NOT NULL,
        description TEXT
      )
    ''');
  }

  Router get router {
    final router = Router();

    router.get('/expenses', (Request request) async {
      final results = await _connection.query('SELECT * FROM expenses');
      return Response.ok(json.encode(results.map(_rowToJson).toList()));
    });

    router.post('/expenses', (Request request) async {
      final data = await request.readAsString();
      final jsonData = json.decode(data);

      final result = await _connection.query('''
        INSERT INTO expenses (title, amount, date, description)
        VALUES (@title, @amount, @date, @description)
        RETURNING id
      ''', substitutionValues: _parseData(jsonData));

      return Response.ok(json.encode({'id': result[0][0]}));
    });

    router.put('/expenses/<id>', (Request request, String id) async {
      final data = await request.readAsString();
      final jsonData = json.decode(data);

      await _connection.query('''
        UPDATE expenses SET
          title = @title,
          amount = @amount,
          date = @date,
          description = @description
        WHERE id = @id
      ''', substitutionValues: {
        ..._parseData(jsonData),
        'id': int.parse(id)
      });

      return Response.ok(json.encode({'success': true}));
    });

    router.delete('/expenses/<id>', (Request request, String id) async {
      await _connection.query(
          'DELETE FROM expenses WHERE id = @id',
          substitutionValues: {'id': int.parse(id)}
      );
      return Response.ok(json.encode({'success': true}));
    });

    return router;
  }

  Map<String, dynamic> _rowToJson(List row) => {
    'id': row[0],
    'title': row[1],
    'amount': row[2],
    'date': (row[3] as DateTime).toIso8601String(),
    'description': row[4]
  };

  Map<String, dynamic> _parseData(Map data) => {
    'title': data['title'],
    'amount': data['amount'],
    'date': DateTime.parse(data['date']),
    'description': data['description']
  };
}