class Book {
  final String isbn;
  final String title;
  final String cover;
  final double price;

  Book({
    required this.isbn,
    required this.title,
    required this.cover,
    required this.price,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      isbn: json['isbn'],
      title: json['title'],
      cover: json['cover'],
      price: (json['price'] as num).toDouble(),
    );
  }
}
