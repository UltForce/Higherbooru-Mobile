import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController postController = TextEditingController();
  bool isPosting = false;

  Future<void> submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final content = postController.text.trim();
    if (content.isEmpty) return;

    setState(() => isPosting = true);

    await FirebaseFirestore.instance.collection('tbl_posts').add({
      'user_id': user.uid,
      'content': content,
      'image_url': '', // Optional: handle image upload later
      'timestamp': Timestamp.now(),
      'likes_count': 0,
      'comments_count': 0,
    });

    setState(() => isPosting = false);

    Navigator.pop(context); // Go back to feed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: postController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isPosting ? null : submitPost,
                child: isPosting
                    ? const CircularProgressIndicator()
                    : const Text("Post"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
