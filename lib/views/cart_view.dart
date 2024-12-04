import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Cubits/cart_cubit.dart';
import '../Models/Book.dart';
import '../Models/offer.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panier"),
      ),
      body: BlocBuilder<CartCubit, Map<Book, int>>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return const Center(
              child: Text("Votre panier est vide."),
            );
          }

          final cartCubit = context.read<CartCubit>();
          final totalWithoutDiscount = cart.entries
              .map((entry) => entry.key.price * entry.value)
              .reduce((value, element) => value + element);

          // Simuler l'obtention des offres disponibles pour le panier
          // Ici on suppose que les offres sont déjà dans un format récupéré depuis une API.
          List<Offer> offers = [
            Offer(type: 'percentage', value: 10),
            Offer(type: 'minus', value: 15),
            Offer(type: 'slice', sliceValue: 100, value: 12),
          ];

          // Calculer le meilleur prix avec les offres
          double bestPrice = totalWithoutDiscount;
          Offer bestOffer = offers[0];

          for (var offer in offers) {
            double priceAfterOffer = _applyOffer(totalWithoutDiscount, offer);
            if (priceAfterOffer < bestPrice) {
              bestPrice = priceAfterOffer;
              bestOffer = offer;
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: cart.entries.map((entry) {
                    final book = entry.key;
                    final quantity = entry.value;
                    final totalPriceForBook = book.price * quantity;

                    return ListTile(
                      leading: Image.network(book.cover),
                      title: Text(book.title),
                      subtitle: Text(
                        "Quantité : $quantity\nPrix unitaire : ${book.price.toStringAsFixed(2)} €\nTotal : ${totalPriceForBook.toStringAsFixed(2)} €",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          cartCubit.removeFromCart(book);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total sans réduction : ${totalWithoutDiscount.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Offres disponibles :",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...offers.map((offer) {
                      double priceAfterOffer = _applyOffer(totalWithoutDiscount, offer);
                      bool isBestOffer = priceAfterOffer == bestPrice;

                      return Opacity(
                        opacity: isBestOffer ? 1.0 : 0.5, // Meilleure offre sans opacité réduite
                        child: ListTile(
                          title: Text(
                            _offerDescription(offer),
                            style: TextStyle(
                              fontWeight: isBestOffer
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: Text(
                            "${priceAfterOffer.toStringAsFixed(2)} €",
                            style: TextStyle(
                              fontWeight: isBestOffer
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      "Prix total après réduction : ${bestPrice.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Applique l'offre sur le prix total
  double _applyOffer(double totalPrice, Offer offer) {
    switch (offer.type) {
      case 'percentage':
        return totalPrice - (totalPrice * offer.value / 100);
      case 'minus':
        return totalPrice - offer.value;
      case 'slice':
      // Vérifier que sliceValue n'est pas null avant de l'utiliser
        if (offer.sliceValue != null) {
          return totalPrice - (offer.value * (totalPrice / offer.sliceValue!).floor());
        }
        return totalPrice; // Retourner le prix total sans modification si sliceValue est null
      default:
        return totalPrice;
    }
  }

  // Décrire l'offre de manière lisible
  String _offerDescription(Offer offer) {
    switch (offer.type) {
      case 'percentage':
        return "Réduction de ${offer.value}%";
      case 'minus':
        return "Réduction de ${offer.value}€";
      case 'slice':
        return "Remise de ${offer.value}€ par tranche de ${offer.sliceValue}€";
      default:
        return "Offre inconnue";
    }
  }
}
