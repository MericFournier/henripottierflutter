import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Cubits/books_cubit.dart';
import '../Cubits/cart_cubit.dart';
import '../Models/Book.dart';
import 'cart_view.dart';
import 'Login.dart';

class BookListView extends StatelessWidget {
  const BookListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Row(
                children: [
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final user = snapshot.data;

                      return IconButton(
                        icon: Icon(
                          user != null ? Icons.exit_to_app : Icons.account_circle,
                        ),
                        onPressed: () {
                          if (user != null) {
                            FirebaseAuth.instance.signOut();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vous avez été déconnecté.')),
                            );
                          } else {
                            // Si l'utilisateur n'est pas connecté, redirigez vers la page de connexion
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const Spacer(),
                  const Text("Liste des Livres"),
                  const Spacer(), // Spacer pour centrer le texte
                ],
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<CartCubit, Map<Book, int>>(
            builder: (context, cart) {
              // Calculez le nombre total d'éléments dans le panier
              final totalItems = cart.values.fold(0, (sum, quantity) => sum + quantity);

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // Si l'utilisateur est connecté, naviguer vers le panier
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CartView()),
                        );
                      } else {
                        // Si l'utilisateur n'est pas connecté, afficher un message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Veuillez vous connecter pour accéder au panier.')),
                        );
                      }
                    },
                  ),
                  if (totalItems > 0) // Affichez la pastille seulement si totalItems > 0
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red, // Couleur de la pastille
                          borderRadius: BorderRadius.circular(10), // Rond
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$totalItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],

      ),
      body: BlocBuilder<BooksCubit, List<Book>>(
        builder: (context, books) {
          if (books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return BlocBuilder<CartCubit, Map<Book, int>>(
            builder: (context, cart) {
              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final cartCubit = context.read<CartCubit>();

                  final quantity = cartCubit.getQuantity(book);
                  final isInCart = cartCubit.isInCart(book);

                  return ListTile(
                    leading: Image.network(book.cover),
                    title: Text(book.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${book.price.toStringAsFixed(2)} €"),
                        if (quantity > 0)
                          Text(
                            "Quantité : $quantity",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/book_details',
                        arguments: book,
                      );
                    },
                    trailing: FirebaseAuth.instance.currentUser == null
                        ? null // Aucun widget n'est affiché si l'utilisateur n'est pas connecté
                        : IconButton(
                      icon: Icon(
                        Icons.add_shopping_cart,
                        color: isInCart ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        cartCubit.addToCart(book);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
