import 'package:flutter_bloc/flutter_bloc.dart';

import '../Models/Book.dart';
import '../Services/books_service.dart';

class BooksCubit extends Cubit<List<Book>> {
  final BooksService _booksService;

  BooksCubit(this._booksService) : super([]);

  Future<void> loadBooks() async {
    try {
      final books = await _booksService.fetchBooks();
      emit(books);
    } catch (e) {
      emit([]);
    }
  }
}
