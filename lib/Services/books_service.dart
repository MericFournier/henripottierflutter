import 'dart:convert';
import '../Models/Book.dart';
import 'package:http/http.dart' as http;


class BooksService {
  Future<List<Book>> fetchBooks() async {
    final url = Uri.parse('https://henri-potier.techx.fr/books');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print("Book = ");
      print(data);
      return data.map((book) => Book.fromJson(book)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }
}