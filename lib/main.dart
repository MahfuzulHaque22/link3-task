import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/screens/sensor_tracking_screen.dart';
import 'package:todo/screens/todo_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do & Sensor Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OnboardingScreen(), // Set the onboarding screen as the home
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLoginScreen();
  }

  _navigateToLoginScreen() async {
    await Future.delayed(const Duration(seconds: 5)); // Wait for 3 seconds
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png'), // Your logo image
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.redAccent,), // Loading animation
          ],
        ),
      ),
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();

  void _saveUsername() async {
    try {
      print("Getting SharedPreferences instance...");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      print("Connected to SharedPreferences");

      String username = _usernameController.text.trim();
      if (username.isEmpty) {
        print("Username is empty. Please enter a username!");
        return;
      }

      print("Saving username: $username");
      await prefs.setString('username', username);
      print("Username saved");

      String? savedUsername = prefs.getString('username');
      print("Retrieved Username: $savedUsername");

      if (savedUsername == username) {
        print("Navigating to HomeScreen");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        print("Failed to save username, mismatch detected");
      }
    } catch (e) {
      print("Error saving username: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Centered image
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Image.asset(
                  'assets/logo2.png', // Ensure this path is correct
                  width: 300,
                  height: 300,
                ),
              ),
              // Floating input box
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.white70),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.white70),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Floating button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: _saveUsername,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 5,
                  ),
                  child: const SizedBox(
                    width: 200,
                    child: Center(
                      child: Text(
                        'Save Username',
                        style: TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double circleDiameter = screenHeight / 2.2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.white70),
        child: Stack(
          children: [
            // Header at the top center
            const Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Link3 Technologies Ltd',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8), // Space between header and subtitle
                    Text(
                      'Innovating the Future',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Image between the header and the circular container
            Positioned(
              top: 220, // Adjust the position based on your layout
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/home.png', // Replace with your image path
                      width: 350, // Adjust the width as needed
                      height: 300, // Adjust the height as needed
                    ),
                    const SizedBox(height: 8), // Space between image and subtitle
                    const Text(
                      'Empowering Users with Technology',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Circular container at the bottom, half visible
            Positioned(
              bottom: -circleDiameter / 2, // Half of the circle will be below the screen
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: circleDiameter,
                  height: circleDiameter,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent, // Background color of the circular container
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 140.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ToDoListScreen()),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 18.0, bottom: 18.0, left: 12.0, right: 12.0),
                                  child: Text('To-Do List',style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent),),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10), // Space between buttons
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SensorTrackingScreen()),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(top:18.0, bottom: 18.0),
                                  child: Text('Sensor Tracking',style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent),),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
