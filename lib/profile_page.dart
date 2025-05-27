import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'signup_form.dart';
import 'follow_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  String? profilePicUrl;
  File? selectedImage;
  bool isLoading = true;
  List<DocumentSnapshot> userPosts = [];
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadUserPosts();
    loadFollowCounts();
  }

  Future<void> loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('tbl_artists')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data != null) {
      nameController.text = data['name'] ?? '';
      bioController.text = data['bio'] ?? '';
      profilePicUrl = data['profilePicture'];
    }
    setState(() => isLoading = false);
  }

  Future<void> loadFollowCounts() async {
    final followersSnap = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .where('artist_id', isEqualTo: user.uid)
        .get();

    final followingSnap = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .where('follower_id', isEqualTo: user.uid)
        .get();

    setState(() {
      followersCount = followersSnap.docs.length;
      followingCount = followingSnap.docs.length;
    });
  }


  Future<void> loadUserPosts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tbl_posts')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() => userPosts = snapshot.docs);
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      selectedImage = File(pickedFile.path);

      final artistRef = FirebaseFirestore.instance.collection('tbl_artists').doc(user.uid);
      final doc = await artistRef.get();
      final existingData = doc.data();
      final oldPath = existingData?['profilePicturePath'];

      // Delete old profile picture from Firebase Storage
      if (oldPath != null && oldPath is String && oldPath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref().child(oldPath).delete();
        } catch (e) {
          debugPrint('Failed to delete old profile picture: $e');
        }
      }

      // Upload new profile picture
      final filePath = 'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(filePath);
      await storageRef.putFile(selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        profilePicUrl = downloadUrl;
      });

      // Save new profile picture URL and path
      await artistRef.update({
        'profilePicture': downloadUrl,
        'profilePicturePath': filePath,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated")),
      );
    }
  }


  Future<void> updateProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Update'),
        content: const Text('Are you sure you want to update your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance.collection('tbl_artists').doc(user.uid).update({
      'name': nameController.text.trim(),
      'bio': bioController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickAndUploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl!) : null,
                child: profilePicUrl == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowListPage(
                          userId: user.uid,
                          isFollowers: true,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text('$followersCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Followers'),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowListPage(
                          userId: user.uid,
                          isFollowers: false,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text('$followingCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Following'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: updateProfile,
              child: const Text("Update Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
