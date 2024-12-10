import 'package:flutter_bloc/flutter_bloc.dart';

import '../Models/Book.dart';
import '../Models/offer.dart';
import '../Services/offers_service.dart';

class CartCubit extends Cubit<Map<Book, int>> {
  final OfferService _offerService;

  CartCubit(this._offerService) : super({});

  void addToCart(Book book) {
    final updatedCart = Map<Book, int>.from(state);
    updatedCart[book] = (updatedCart[book] ?? 0) + 1;
    emit(updatedCart);
  }

  void removeFromCart(Book book) {
    final updatedCart = Map<Book, int>.from(state);

    if (updatedCart.containsKey(book)) {
      if (updatedCart[book]! > 1) {
        updatedCart[book] = updatedCart[book]! - 1;
      } else {
        updatedCart.remove(book);
      }
    }

    emit(updatedCart);
  }

  int getQuantity(Book book) {
    return state[book] ?? 0;
  }

  bool isInCart(Book book) {
    return state.containsKey(book) && state[book]! > 0;
  }

  double getTotalPrice() {
    double total = 0;
    state.forEach((book, quantity) {
      total += book.price * quantity;
    });
    return total;
  }

  Future<List<Offer>> fetchOffers() async {
    final isbns = state.keys.map((book) => book.isbn).toList();
    return await _offerService.fetchOffers(isbns);
  }

  Future<double> getBestOffer() async {
    final offers = await fetchOffers();
    final totalPrice = getTotalPrice();

    double bestPrice = totalPrice;

    for (final offer in offers) {
      double calculatedPrice = totalPrice;
      switch (offer.type) {
        case 'percentage':
          calculatedPrice = totalPrice - (totalPrice * (offer.value / 100));
          break;
        case 'minus':
          calculatedPrice = totalPrice - offer.value;
          break;
        case 'slice':
          if (offer.sliceValue != null) {
            calculatedPrice = totalPrice -
                (offer.value * (totalPrice / offer.sliceValue!).floor());
          }
          break;
      }
      if (calculatedPrice < bestPrice) {
        bestPrice = calculatedPrice;
      }
    }

    return bestPrice;
  }
}