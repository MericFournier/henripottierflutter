import 'package:flutter_bloc/flutter_bloc.dart';

import '../Models/Book.dart';

class CartCubit extends Cubit<Map<Book, int>> {
  CartCubit() : super({});

  void addToCart(Book book) {
    final updatedCart = Map<Book, int>.from(state);
    updatedCart[book] = (updatedCart[book] ?? 0) + 1;
    emit(updatedCart);
  }

  void removeFromCart(Book book) {
    final updatedCart = Map<Book, int>.from(state);

    if (updatedCart.containsKey(book)) {
      if (updatedCart[book]! > 1) {
        updatedCart[book] = updatedCart[book]! - 1; // Diminue la quantité
      } else {
        updatedCart.remove(book); // Retire complètement si la quantité est 0
      }
    }

    emit(updatedCart);
  }

  int getQuantity(Book book) {
    return state[book] ?? 0;
  }

  bool isInCart(Book book) {
    return state.containsKey(book);
  }

  double getTotalPrice() {
    double total = 0;
    state.forEach((book, quantity) {
      total += book.price * quantity;
    });
    return total;
  }
}
