import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Cubits/cart_cubit.dart';
import '../Models/Book.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
      ),
      body: BlocBuilder<CartCubit, Map<Book, int>>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return const Center(
              child: Text("Votre panier est vide."),
            );
          }

          final cartCubit = context.read<CartCubit>();
          final totalPrice = cartCubit.getTotalPrice();

          return FutureBuilder(
            future: cartCubit.fetchOffers(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text("Erreur lors du chargement des offres."),
                );
              }

              final offers = snapshot.data!;
              double bestPrice = totalPrice;
              String bestOfferType = '';

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
                  bestOfferType = offer.type;
                }
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final book = cart.keys.elementAt(index);
                        final quantity = cart[book]!;

                        return ListTile(
                          leading: Image.network(book.cover),
                          title: Text(book.title),
                          subtitle: Text(
                            "${book.price.toStringAsFixed(2)} € x $quantity = ${(book.price * quantity).toStringAsFixed(2)} €",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  cartCubit.removeFromCart(book);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  cartCubit.addToCart(book);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vos offres personnalisées :",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: offers.map((offer) {
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

                            return Opacity(
                              opacity: bestOfferType == offer.type ? 1.0 : 0.5,
                              child: ListTile(
                                title: Text("Offre ${offer.type}"),
                                subtitle: Text(
                                  "Prix avec cette offre : ${calculatedPrice.toStringAsFixed(2)} €",
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Total sans réduction : ${totalPrice.toStringAsFixed(2)} €",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Total avec réduction : ${bestPrice.toStringAsFixed(2)} €",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
