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

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: cart.entries.map((entry) {
                    final book = entry.key; // Accédez à Book ici
                    final quantity = entry.value;

                    return ListTile(
                      leading: Image.network(book.cover), // Utilisez book.cover
                      title: Text(book.title), // Utilisez book.title
                      subtitle: Text("Quantité : $quantity\nPrix : ${book.price.toStringAsFixed(2)} €"), // Affichez le prix du livre
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
                child: Text(
                  "Prix total : ${cartCubit.getTotalPrice().toStringAsFixed(2)} €",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
