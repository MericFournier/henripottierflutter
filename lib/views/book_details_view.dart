import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/Book.dart';
import '../firebase/firebase_comments.dart'; // Import du service CommentService

class BookDetailsView extends StatefulWidget {
  final Book book;
  const BookDetailsView({super.key, required this.book});

  @override
  _BookDetailsViewState createState() => _BookDetailsViewState();
}

class _BookDetailsViewState extends State<BookDetailsView> {
  final _commentController = TextEditingController();
  int _rating = 1; // Initialisez la valeur du rating à 1
  bool _isEditing = false;
  String? _currentReviewId;

  final CommentService _commentService = CommentService(); // Instance du service CommentService

  // Fonction pour ajouter ou modifier un avis
  void _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'Anonyme'; // Si non connecté, afficher "Anonyme"

    // Si l'utilisateur édite un avis existant
    if (_isEditing && _currentReviewId != null) {
      await _commentService.addReview(
        widget.book.isbn, // Utilisez l'ISBN du livre pour identifier
        user?.uid ?? '', // Utilisez l'UID de l'utilisateur
        _commentController.text,
        _rating.toDouble(), // Convertir l'entier en double
      );
    } else {
      // Sinon, on ajoute un nouvel avis
      await _commentService.addReview(
        widget.book.isbn,
        user?.uid ?? '',
        _commentController.text,
        _rating.toDouble(),
      );
    }

    // Réinitialisation des champs après l'ajout/modification
    _commentController.clear();
    setState(() {
      _isEditing = false;
      _rating = 1; // Réinitialisation de la note
    });

    // Affichage d'un message de succès
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEditing ? "Avis modifié avec succès !" : "Avis ajouté avec succès !"),
    ));
  }

  // Fonction pour supprimer un avis
  void _deleteReview(String reviewId) async {
    await _commentService.deleteReview(reviewId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Avis supprimé avec succès !"),
    ));
  }

  // Fonction pour vérifier si l'utilisateur a déjà laissé un avis pour ce livre
  Future<void> _checkExistingReview() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // Utilisation de la méthode getReviews pour récupérer les revues
    final reviews = await _commentService.getReviews(widget.book.isbn);

    // Vérifiez si l'utilisateur a déjà laissé un avis pour ce livre
    final existingReview = reviews.firstWhere(
          (review) => review['userId'] == user.uid,
      orElse: () => {},
    );

    if (existingReview.isNotEmpty) {
      setState(() {
        _isEditing = true;
        _currentReviewId = existingReview['id'];
        _rating = existingReview['rating'].toInt();
        _commentController.text = existingReview['content'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                widget.book.cover,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.book.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "${widget.book.price.toStringAsFixed(2)} €",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              "Synopsis",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.book.synopsis.map((paragraph) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  paragraph,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              );
            }),

            // Section des avis
            const SizedBox(height: 16),
            const Text(
              "Avis des utilisateurs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('bookIsbn', isEqualTo: widget.book.isbn)  // Filtrage par isbn
                  .orderBy('timestamp', descending: true)
                  .snapshots()
                  .map((snapshot) => snapshot.docs.map((doc) {
                return {
                  'id': doc.id,
                  'userName': doc['userName'],
                  'rating': doc['rating'],
                  'comment': doc['comment'],
                  'timestamp': doc['timestamp'],
                };
              }).toList()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final reviewId = review['id'];
                    final reviewUserName = review['userName'];

                    return ListTile(
                      title: Text('Note: ${review['rating']} étoiles'),
                      subtitle: Text(review['comment']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(reviewUserName),
                          if (reviewUserName != 'Anonyme') ...[
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                  _currentReviewId = reviewId;
                                  _rating = review['rating'];
                                  _commentController.text = review['comment'];
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteReview(reviewId),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // Formulaire d'ajout/modification d'avis
            const SizedBox(height: 16),
            Text(
              _isEditing ? "Modifier votre avis" : "Laisser un avis",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            // Section pour les étoiles
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating
                        ? Icons.star // Etoile pleine
                        : Icons.star_border, // Etoile vide
                    color: index < _rating ? Colors.yellow : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1; // Met à jour la note
                    });
                  },
                );
              }),
            ),

            // Champ pour le commentaire
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Votre commentaire'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text(_isEditing ? 'Modifier l\'avis' : 'Ajouter l\'avis'),
            ),
          ],
        ),
      ),
    );
  }
}
