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
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartView()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez vous connecter pour accéder au panier.')),
                );
              }
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
                    trailing: IconButton(
                      icon: Icon(
                        Icons.add_shopping_cart,
                        color: isInCart ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          cartCubit.addToCart(book);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Veuillez vous connecter pour ajouter des livres au panier.')),
                          );
                        }
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
