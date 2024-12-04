import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henripottier/views/book_list_view.dart';
import 'Cubits/books_cubit.dart';
import 'Cubits/cart_cubit.dart';
import 'Services/books_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BooksCubit(BooksService())..loadBooks(),
        ),
        BlocProvider(
          create: (context) => CartCubit(),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BookListView(),
      ),
    );
  }
}