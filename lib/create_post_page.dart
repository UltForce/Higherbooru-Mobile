import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController postController = TextEditingController();
  bool isPosting = false;
  List<XFile>? selectedImages;

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage();

    if (pickedImages.isNotEmpty) {
      setState(() {
        selectedImages = pickedImages;
      });
    }
  }

  Future<void> submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final content = postController.text.trim();
    if (content.isEmpty && (selectedImages == null || selectedImages!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post must have text or images.")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Post'),
        content: const Text('Are you sure you want to publish this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Post'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isPosting = true);

    final postRef = FirebaseFirestore.instance.collection('tbl_posts').doc();
    final postId = postRef.id;

    List<String> imageUrls = [];

    if (selectedImages != null && selectedImages!.isNotEmpty) {
      for (var img in selectedImages!) {
        String fileName = 'posts/$postId/${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        await storageRef.putFile(File(img.path));
        String downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    }

    await postRef.set({
      'post_id': postId,
      'user_id': user.uid,
      'content': content,
      'image_url': imageUrls,
      'timestamp': Timestamp.now(),
      'likes_count': 0,
      'comments_count': 0,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post successfully created")),
    );
    setState(() => isPosting = false);
    Navigator.pop(context);
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: pickImages,
                icon: const Icon(Icons.image),
                label: const Text("Add Images"),
              ),
            ),
            if (selectedImages != null && selectedImages!.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: selectedImages!.map((img) {
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.file(File(img.path), width: 100, height: 100, fit: BoxFit.cover),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isPosting ? null : submitPost,
                child: isPosting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Post"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
