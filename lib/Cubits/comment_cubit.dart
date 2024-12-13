import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommentCubit extends Cubit<List<Map<String, dynamic>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CommentCubit() : super([]);

  // Récupérer les commentaires pour un livre spécifique
  void fetchComments(String bookIsbn) {
    _firestore
        .collection('reviews')
        .where('bookIsbn', isEqualTo: bookIsbn)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final comments = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'userEmail': doc['userEmail'],
          'rating': doc['rating'],
          'comment': doc['comment'],
          'timestamp': doc['timestamp'],
        };
      }).toList();
      emit(comments);
    });
  }

  // Vérifier si l'utilisateur a déjà commenté un livre
  Future<Map<String, dynamic>?> fetchUserComment(String bookIsbn, String userEmail) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('bookIsbn', isEqualTo: bookIsbn)
        .where('userEmail', isEqualTo: userEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    } else {
      return null;
    }
  }

  // Ajouter un commentaire
  Future<void> addComment(String bookIsbn, String userEmail, String comment, int rating) async {
    await _firestore.collection('reviews').add({
      'bookIsbn': bookIsbn,
      'userEmail': userEmail,
      'comment': comment,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Modifier un commentaire
  Future<void> editComment(String commentId, String comment, double rating) async {
    await _firestore.collection('reviews').doc(commentId).update({
      'comment': comment,
      'rating': rating,
    });
  }

  // Supprimer un commentaire
  Future<void> deleteComment(String commentId) async {
    await _firestore.collection('reviews').doc(commentId).delete();
  }
}
