import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/Book.dart';

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

  // Fonction pour ajouter ou modifier un avis
  void _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'Anonyme'; // Si non connecté, afficher "Anonyme"

    final reviewData = {
      'userName': userName, // Le nom de l'utilisateur, "Anonyme" s'il n'est pas connecté
      'bookIsbn': widget.book.isbn,  // Utilisez isbn ici pour référencer le livre
      'rating': _rating,
      'comment': _commentController.text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Si l'utilisateur édite un avis existant, on met à jour l'avis
    if (_isEditing && _currentReviewId != null) {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(_currentReviewId)
          .update(reviewData);
    } else {
      // Sinon, on ajoute un nouvel avis
      await FirebaseFirestore.instance.collection('reviews').add(reviewData);
    }

    // Remise à zéro après l'ajout/modification
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
    await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Avis supprimé avec succès !"),
    ));
  }

  // Fonction pour vérifier si l'utilisateur a déjà laissé un avis pour ce livre
  Future<void> _checkExistingReview() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final reviewSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('bookIsbn', isEqualTo: widget.book.isbn)  // Utilisez isbn ici pour filtrer par livre
        .get();

    if (reviewSnapshot.docs.isNotEmpty) {
      final review = reviewSnapshot.docs.first;
      setState(() {
        _isEditing = true;
        _currentReviewId = review.id;
        _rating = review['rating'];
        _commentController.text = review['comment'];
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('bookIsbn', isEqualTo: widget.book.isbn)  // Filtrage par isbn
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final reviewId = review.id;
                    final reviewUserName = review['userName']; // Utilisation de 'userName' au lieu de 'userId'

                    return ListTile(
                      title: Text('Note: ${review['rating']} étoiles'),
                      subtitle: Text(review['comment']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(reviewUserName), // Affichage du nom de l'utilisateur
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
