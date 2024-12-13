import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview(String postId, String userId, String content, double rating) async {
    try {
      await _firestore.collection('reviews').add({
        'postId': postId,
        'userId': userId,
        'content': content,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding review: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReviews(String postId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('reviews')
          .where('postId', isEqualTo: postId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'content': doc['content'],
          'userId': doc['userId'],
          'rating': doc['rating'],  // Récupération de la note
          'timestamp': doc['timestamp'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching reviews: $e");
      rethrow;
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
    } catch (e) {
      print("Error deleting review: $e");
      rethrow;
    }
  }
}
