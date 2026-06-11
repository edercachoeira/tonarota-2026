import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  String? _token;

  // Em ambiente web local, aponta para localhost. Em produção, se adapta.
  final String baseUrl = kIsWeb ? 'http://localhost:8080/api' : 'http://10.0.2.2:8080/api';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'content-type': 'application/json',
      'accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _getHeaders(),
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<http.Response> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _getHeaders(),
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
