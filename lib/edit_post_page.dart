import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditPostPage extends StatefulWidget {
  final DocumentSnapshot post;
  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController contentController;
  List<String> existingImages = [];
  List<File> newImages = [];

  @override
  void initState() {
    super.initState();
    contentController = TextEditingController(text: widget.post['content']);
    existingImages = List<String>.from(widget.post['image_url'] ?? []);
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  Future<void> pickNewImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        newImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  void removeExistingImage(int index) {
    setState(() {
      existingImages.removeAt(index);
    });
  }

  void removeNewImage(int index) {
    setState(() {
      newImages.removeAt(index);
    });
  }

  Future<List<String>> uploadNewImages() async {
    List<String> urls = [];
    for (File image in newImages) {
      final ref = FirebaseStorage.instance
          .ref('post_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(image);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  void updatePost() async {
    final updatedContent = contentController.text.trim();

    if (updatedContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Content can't be empty.")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Post'),
        content: const Text('Are you sure you want to update this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );

    if (confirmed == true) {
      List<String> uploadedUrls = await uploadNewImages();
      List<String> finalImages = [...existingImages, ...uploadedUrls];

      await FirebaseFirestore.instance
          .collection('tbl_posts')
          .doc(widget.post.id)
          .update({
        'content': updatedContent,
        'image_url': finalImages,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Edit Content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Current Images"),
            const SizedBox(height: 8),
            if (existingImages.isEmpty)
              const Text("No existing images")
            else
              Wrap(
                spacing: 10,
                children: List.generate(existingImages.length, (i) {
                  return Stack(
                    children: [
                      Image.network(existingImages[i], width: 100, height: 100, fit: BoxFit.cover),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => removeExistingImage(i),
                          child: const CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 12,
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),

            const SizedBox(height: 20),
            const Text("New Images"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: List.generate(newImages.length, (i) {
                return Stack(
                  children: [
                    Image.file(newImages[i], width: 100, height: 100, fit: BoxFit.cover),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => removeNewImage(i),
                        child: const CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 12,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: pickNewImages,
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Add More Images"),
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: updatePost,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
