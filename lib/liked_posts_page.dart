import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'post_details_page.dart';

class LikedPostsPage extends StatefulWidget {
  const LikedPostsPage({super.key});

  @override
  State<LikedPostsPage> createState() => _LikedPostsPageState();
}

class _LikedPostsPageState extends State<LikedPostsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<List<DocumentSnapshot>> fetchLikedPosts() async {
    // Get liked post IDs by current user
    final likesSnapshot = await FirebaseFirestore.instance
        .collection('tbl_likes')
        .where('user_id', isEqualTo: currentUser?.uid ?? '')
        .get();

    final postIds = likesSnapshot.docs.map((doc) => doc['post_id'] as String).toList();

    if (postIds.isEmpty) return [];

    // Fetch posts matching the liked post IDs
    final postsSnapshot = await FirebaseFirestore.instance
        .collection('tbl_posts')
        .where(FieldPath.documentId, whereIn: postIds)
        .get();

    return postsSnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liked Posts")),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: fetchLikedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("You haven't liked any posts yet."));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id;
              final content = postData['content'] ?? '';
              final imageUrls = (postData['image_url'] as List<dynamic>?)?.cast<String>() ?? [];

              return ListTile(
                leading: imageUrls.isNotEmpty
                    ? Image.network(imageUrls[0], width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported),
                title: Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailsPage(
                        postId: postId,
                        content: content,
                        imageUrls: imageUrls,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
