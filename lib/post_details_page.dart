import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PostDetailsPage extends StatefulWidget {
  final String postId;
  final String content;
  final List<String> imageUrls;

  const PostDetailsPage({
    super.key,
    required this.postId,
    required this.content,
    required this.imageUrls,
  });

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  int likes = 0;
  bool isLiked = false;
  String? likeDocId;
  final commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchLikes();
    checkIfLiked();
  }

  Future<void> fetchLikes() async {
    final postSnapshot = await FirebaseFirestore.instance
        .collection('tbl_posts')
        .doc(widget.postId)
        .get();

    if (postSnapshot.exists) {
      setState(() {
        likes = postSnapshot['likes_count'] ?? 0;
      });
    }
  }

  Future<void> checkIfLiked() async {
    final likeSnapshot = await FirebaseFirestore.instance
        .collection('tbl_likes')
        .where('post_id', isEqualTo: widget.postId)
        .where('user_id', isEqualTo: currentUser?.uid ?? '')
        .limit(1)
        .get();

    if (likeSnapshot.docs.isNotEmpty) {
      setState(() {
        isLiked = true;
        likeDocId = likeSnapshot.docs.first.id;
      });
    }
  }

  Future<void> toggleLike() async {
    final postRef =
    FirebaseFirestore.instance.collection('tbl_posts').doc(widget.postId);

    if (!isLiked) {
      // Like the post
      final newLike = await FirebaseFirestore.instance.collection('tbl_likes').add({
        'post_id': widget.postId,
        'user_id': currentUser?.uid ?? '',
      });

      await postRef.update({'likes_count': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        likes += 1;
        likeDocId = newLike.id;
      });
    } else {
      // Unlike the post
      if (likeDocId != null) {
        await FirebaseFirestore.instance
            .collection('tbl_likes')
            .doc(likeDocId)
            .delete();

        await postRef.update({'likes_count': FieldValue.increment(-1)});

        setState(() {
          isLiked = false;
          likes -= 1;
          likeDocId = null;
        });
      }
    }
  }

  Future<void> addComment(String text) async {
    if (text.trim().isEmpty) return;

    final commentId = FirebaseFirestore.instance.collection('tbl_comments').doc().id;

    final batch = FirebaseFirestore.instance.batch();

    // Add the comment
    final commentRef = FirebaseFirestore.instance.collection('tbl_comments').doc(commentId);
    batch.set(commentRef, {
      'comment_id': commentId,
      'post_id': widget.postId,
      'user_id': currentUser?.uid ?? '',
      'content': text.trim(),
      'timestamp': Timestamp.now(),
    });

    // Increment the comment count on the post
    final postRef = FirebaseFirestore.instance.collection('tbl_posts').doc(widget.postId);
    batch.update(postRef, {
      'comments_count': FieldValue.increment(1),
    });

    await batch.commit();

    commentController.clear();
  }


  void _showEditDialog(String commentId, String oldText) {
    final editController = TextEditingController(text: oldText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Comment"),
          content: TextField(
            controller: editController,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('tbl_comments')
                      .doc(commentId)
                      .update({'content': newText});
                }
                Navigator.of(context).pop();
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _deleteComment(String commentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Comment"),
        content: const Text("Are you sure you want to delete this comment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final batch = FirebaseFirestore.instance.batch();

      // Delete the comment
      final commentRef = FirebaseFirestore.instance.collection('tbl_comments').doc(commentId);
      batch.delete(commentRef);

      // Decrease the comments count on the post
      final postRef = FirebaseFirestore.instance.collection('tbl_posts').doc(widget.postId);
      batch.update(postRef, {
        'comments_count': FieldValue.increment(-1),
      });

      await batch.commit();
    }
  }



  Stream<QuerySnapshot> getCommentsStream() {
    return FirebaseFirestore.instance
        .collection('tbl_comments')
        .where('post_id', isEqualTo: widget.postId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.content, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            if (widget.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(widget.imageUrls[index],
                            width: 200, height: 200, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: toggleLike,
                ),
                Text('$likes likes'),
              ],
            ),
            const Divider(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Comments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getCommentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No comments yet."));
                  }

                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentDoc = comments[index];
                      final data = commentDoc.data() as Map<String, dynamic>;
                      final userId = data['user_id'];
                      final commentId = data['comment_id'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('tbl_artists').doc(userId).get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: const Text("Unknown user"),
                              subtitle: Text(data['content'] ?? ''),
                            );
                          }

                          final userData = userSnapshot.data!.data()! as Map<String, dynamic>;

                          final profileUrl = userData['profilePicture'] ?? '';
                          final username = userData['name'] ?? 'Unknown';

                          final formattedTime = DateFormat.yMMMd().add_jm().format(
                              (data['timestamp'] as Timestamp).toDate());

                          final isCommentOwner = userId == currentUser?.uid;
                          final isPostOwner = widget.postId.isNotEmpty &&
                              currentUser?.uid != null &&
                              userId != null &&
                              currentUser!.uid == userId;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: profileUrl.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(username),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['content'] ?? ''),
                                Text(formattedTime, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing: (isCommentOwner || isPostOwner)
                                ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditDialog(commentId, data['content']);
                                } else if (value == 'delete') {
                                  _deleteComment(commentId);
                                }
                              },
                              itemBuilder: (context) => [
                                if (isCommentOwner || isPostOwner)
                                  const PopupMenuItem(value: 'edit', child: Text("Edit")),
                                const PopupMenuItem(value: 'delete', child: Text("Delete")),
                              ],
                            )
                                : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => addComment(commentController.text),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
