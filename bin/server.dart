import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:expense_backend/server.dart';

void main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

  final connection = PostgreSQLConnection(
    env['DB_HOST']!,
    int.parse(env['DB_PORT']!),
    env['DB_NAME']!,
    username: env['DB_USER']!,
    password: env['DB_PASSWORD']!,
  );

  final expenseService = ExpenseService(connection);
  await expenseService.initDatabase();

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE',
    'Access-Control-Allow-Headers': 'Content-Type',
  }))

      .addHandler(expenseService.router);

  final port = int.parse(Platform.environment['PORT'] ?? '8088');
  final httpServer = await serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on ${httpServer.address.host}:${httpServer.port}');
  print('Test');
}