import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henripottier/views/book_details_view.dart';
import 'package:henripottier/views/book_list_view.dart';
import 'package:henripottier/views/cart_view.dart';
import 'Cubits/books_cubit.dart';
import 'Cubits/cart_cubit.dart';
import 'Models/Book.dart';
import 'Services/books_service.dart';
import 'Services/offers_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
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
          create: (context) => CartCubit(OfferService()),
        ),
      ],
      child: MaterialApp(
        title: 'Henri Potier',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route? _onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const BookListView());
      case '/cart':
        return MaterialPageRoute(builder: (_) => const CartView());
      case '/book_details':
        if (args is Book) {
          return MaterialPageRoute(
            builder: (_) => BookDetailsView(book: args),
          );
        }
        return _errorRoute();
      default:
        return _errorRoute();
    }
  }

  Route _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text('Page non trouvée'),
        ),
      ),
    );
  }
}