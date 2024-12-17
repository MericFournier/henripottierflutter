import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Cubits/comment_cubit.dart';
import '../Models/Book.dart';

class BookDetailsView extends StatefulWidget {
  final Book book;

  const BookDetailsView({super.key, required this.book});

  @override
  _BookDetailsViewState createState() => _BookDetailsViewState();
}

class _BookDetailsViewState extends State<BookDetailsView> {
  final _commentController = TextEditingController();
  int _rating = 1;
  bool _isEditing = false;
  bool _hadComment = false;
  String? _currentReviewId;


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.email != null) {
      // Charger les commentaires pour le livre
      context.read<CommentCubit>().fetchComments(widget.book.isbn);

      // Vérifier si l'utilisateur a déjà commenté ce livre
      context.read<CommentCubit>().fetchUserComment(widget.book.isbn, user.email!).then((existingComment) {
        if (existingComment != null) {
          setState(() {
            _hadComment = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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

            // Section des avis des utilisateurs
            const SizedBox(height: 16),
            const Text(
              "Avis des utilisateurs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            BlocBuilder<CommentCubit, List<Map<String, dynamic>>>(
              builder: (context, comments) {
                // Trouver le commentaire de l'utilisateur ou retourner null si non trouvé
                final userComment = user != null
                    ? comments.firstWhere(
                      (c) => c['userEmail'] == user.email,
                  orElse: () => <String, dynamic>{}, // Valeur par défaut valide
                )
                    : null;


                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isUserComment = user != null && comment['userEmail'] == user.email;

                        return ListTile(
                          title: Text('${comment['userEmail']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${comment['rating']} étoiles',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 4), // Un espace entre les lignes
                              Text(comment['comment']),
                            ],
                          ),
                          trailing: isUserComment
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                    _currentReviewId = comment['id'];
                                    _rating = comment['rating'].toInt();
                                    _commentController.text = comment['comment'];
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  if (comment['id'] != null) {
                                    await context.read<CommentCubit>().deleteComment(comment['id']);
                                    setState(() {
                                      _hadComment = false;
                                    });
                                  }
                                },
                              ),
                            ],
                          )
                              : null,
                        );
                      },
                    ),

                    // Formulaire d'ajout ou de modification d'avis
                    if (_isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            "Modifier votre avis",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < _rating ? Icons.star : Icons.star_border,
                                  color: index < _rating ? Colors.yellow : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _rating = index + 1;
                                  });
                                },
                              );
                            }),
                          ),
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(labelText: 'Modifier votre commentaire'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              if (_currentReviewId != null) {
                                // Mise à jour de l'avis
                                await context.read<CommentCubit>().editComment(
                                  _currentReviewId!, // Utilisation de l'ID de commentaire existant
                                  _commentController.text,
                                  _rating.toDouble(), // Assurez-vous que le rating est un double
                                );
                                setState(() {
                                  _isEditing = false;
                                  _currentReviewId = null;
                                  _commentController.clear();
                                  _rating = 1;
                                });
                              }
                            },
                            child: const Text('Modifier l\'avis'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _currentReviewId = null;
                                _commentController.clear();
                                _rating = 1;
                              });
                            },
                            child: const Text('Annuler'),
                          ),
                        ],
                      )
                    else if (user != null && !_hadComment)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            "Laisser un avis",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < _rating ? Icons.star : Icons.star_border,
                                  color: index < _rating ? Colors.yellow : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _rating = index + 1;
                                  });
                                },
                              );
                            }),
                          ),
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(labelText: 'Votre commentaire'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              if (user != null) {
                                await context.read<CommentCubit>().addComment(
                                  widget.book.isbn,
                                  user.email!,
                                  _commentController.text,
                                  _rating,
                                );
                                _commentController.clear();
                                setState(() {
                                  _rating = 1;
                                  _hadComment = true;
                                });
                              }
                            },
                            child: const Text('Ajouter l\'avis'),
                          ),
                        ],
                      )

                  ],
                );
              },
            ),


          ],
        ),
      ),
    );
  }
}
