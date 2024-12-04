import 'dart:convert';
import '../Models/Book.dart';
import 'package:http/http.dart' as http;


class BooksService {
  Future<List<Book>> fetchBooks() async {
    final url = Uri.parse('https://henri-potier.techx.fr/books');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }
}