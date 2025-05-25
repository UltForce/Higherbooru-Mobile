import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gallery_feed.dart';
import 'signup_form.dart'; // ⬅️ Make sure this matches your file name

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();

  void loginUser() async {
    var fgbcemail = emailController.text.trim();
    var fgbcpassword = passwordController.text.trim();

    if (fgbcemail.isEmpty || fgbcpassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: fgbcemail,
        password: fgbcpassword,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GalleryFeed()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(60),
          child: Form(
            child: ListView(
              children: [
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
                  onPressed: loginUser,
                  child: const Text("Login"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupForm()),
                    );
                  },
                  child: const Text("Don't have an account? Sign up here"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
