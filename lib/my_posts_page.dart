import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'edit_post_page.dart';
import 'post_details_page.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<DocumentSnapshot> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMyPosts();
  }

  Future<void> loadMyPosts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tbl_posts')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      posts = snapshot.docs;
      isLoading = false;
    });
  }

  void _confirmDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('tbl_posts').doc(postId).delete();
      loadMyPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Posts"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(child: Text('You haven’t posted anything yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final data = posts[index].data() as Map<String, dynamic>;
          final imageUrls = List<String>.from(data['image_url'] ?? []);
          final timestamp = data['timestamp'] as Timestamp?;
          final formattedDate = timestamp != null
              ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
              : 'Unknown date';

          return InkWell(
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailsPage(
                  postId: data['post_id'],
                  content: data['content'],
                  imageUrls: imageUrls,
                ),
              ),
            );
          },
          child: Card(

          margin: const EdgeInsets.only(bottom: 20),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['content'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  if (imageUrls.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, i) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrls[i],
                                fit: BoxFit.cover,
                                width: 200,
                                height: 200,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('❤️ ${data['likes_count'] ?? 0}  💬 ${data['comments_count'] ?? 0}'),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                    Row(
                      children:[
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPostPage(post: posts[index]),
                              ),
                            ).then((_) => loadMyPosts());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeletePost(posts[index].id),
                        ),
                      ]
                    ),

                ],
              ),
            ),
          ),
          );

        },
      ),
    );
  }
}
