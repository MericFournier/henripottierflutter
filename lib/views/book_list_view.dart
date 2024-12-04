import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Cubits/books_cubit.dart';
import '../Cubits/cart_cubit.dart';
import '../Models/Book.dart';
import 'book_details_view.dart';
import 'cart_view.dart';

class BookListView extends StatelessWidget {
  const BookListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des Livres"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartView()),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailsView(book: book),
                        ),
                      );
                    },
                    trailing: IconButton(
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