import 'dart:convert';
import '../Models/offer.dart';
import 'package:http/http.dart' as http;


class OfferService {
  Future<List<Offer>> fetchOffers(List<String> isbns) async {
    final isbnString = isbns.join(',');
    final url = Uri.parse('https://henri-potier.techx.fr/books/$isbnString/commercialOffers');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final offers = (data['offers'] as List)
          .map((json) => Offer.fromJson(json))
          .toList();
      return offers;
    } else {
      throw Exception('Failed to load offers');
    }
  }
}