import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_form.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const mainPage());
}

class mainPage extends StatelessWidget {
  const mainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SignupForm(),
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  var nameController = TextEditingController();
  var bioController = TextEditingController();
  var profilePicUrlController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  File? selectedImage;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artist Registration')),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(60),
          child: Form(
            child: ListView(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextFormField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: "Bio"),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Profile Picture", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickAndUploadImage,
                      child: Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                          selectedImage != null ? FileImage(selectedImage!) : null,
                          child: selectedImage == null
                              ? const Icon(Icons.camera_alt, size: 40, color: Colors.white70)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: pickAndUploadImage,
                        icon: const Icon(Icons.upload),
                        label: const Text("Upload Profile Picture"),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: registerUser,
                  child: const Text("Register"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginForm()),
                    );
                  },
                  child: const Text("Already have an account? Login here"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void registerUser() async {
    var fgbcName = nameController.text.trim();
    var fgbcBio = bioController.text.trim();
    var fgbcProfilePicture = profilePicUrlController.text.trim();
    var fgbcEmail = emailController.text.trim();
    var fgbcPassword = passwordController.text.trim();

    if (fgbcName.isEmpty ||
        fgbcBio.isEmpty ||
        fgbcProfilePicture.isEmpty ||
        fgbcEmail.isEmpty ||
        fgbcPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Registration'),
        content: const Text('Are you sure you want to register with these details?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: fgbcEmail, password: fgbcPassword);
      String userId = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('tbl_artists').doc(userId).set({
        'user_id': userId,
        'name': fgbcName,
        'bio': fgbcBio,
        'profilePicture': fgbcProfilePicture,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User Registered Successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginForm()),
      );

      nameController.clear();
      bioController.clear();
      profilePicUrlController.clear();
      emailController.clear();
      passwordController.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    }
  }


  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });

      String fileName = 'profile_pictures/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.putFile(selectedImage!);
      String downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        profilePicUrlController.text = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture uploaded")),
      );
    }
  }

}
