import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_form.dart';

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
      home: RegisterForm(),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  var nameController = TextEditingController();
  var bioController = TextEditingController();
  var profilePicUrlController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();

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
                TextFormField(
                  controller: profilePicUrlController,
                  decoration: const InputDecoration(
                      labelText: "Profile Picture URL (Firebase Storage)"),
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
}
