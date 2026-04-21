import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'map_dashboard.dart';

void main() {
  runApp(const SafeWalkApp());
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeWalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF043464),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

// LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'User';
  
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Color darkNavyColor = const Color(0xFF043464);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                  decoration: BoxDecoration(
                    color: darkNavyColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'SafeWalk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      _buildLabel('USERNAME'),
                      const SizedBox(height: 6),
                      _buildTextField(controller: usernameController),
                      const SizedBox(height: 18),
                      _buildLabel('PASSWORD'),
                      const SizedBox(height: 6),
                      _buildTextField(obscureText: true, controller: passwordController),
                      const SizedBox(height: 18),
                      _buildLabel('ROLE'),
                      const SizedBox(height: 6),
                      _buildDropdown(),
                      const SizedBox(height: 40),
                      Center(
                        child: isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : _buildButton('LOGIN', darkNavyColor, () async {
                                setState(() => isLoading = true);
                                try {
                                  print("Attempting to connect to Login API...");
                                  final response = await http.post(
                                    Uri.parse('https://safewalk.uslsbsit.com/login.php'),
                                    body: jsonEncode({
                                      "username": usernameController.text,
                                      "password": passwordController.text,
                                      "role": selectedRole
                                    }),
                                    headers: {"Content-Type": "application/json"}
                                  );

                                  print("RAW SERVER RESPONSE (LOGIN): '${response.body}'");

                                  final data = jsonDecode(response.body);

                                  if (data['status'] == 'success') {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MapDashboardScreen()),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(data['message']), backgroundColor: Colors.red)
                                    );
                                  }
                                } catch (e) {
                                  print("THE REAL ERROR IS: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                                  );
                                } finally {
                                  setState(() => isLoading = false);
                                }
                              }),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: _buildButton('REGISTER', darkNavyColor, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRole,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20),
          isExpanded: true,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          onChanged: (String? newValue) {
            setState(() {
              selectedRole = newValue!;
            });
          },
          items: <String>['User', 'Admin']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }
}

// REGISTER SCREEN
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Color darkNavyColor = const Color(0xFF043464);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 35.0),
                  decoration: BoxDecoration(
                    color: darkNavyColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25), 
                      
                      _buildLabel('FULL NAME'),
                      const SizedBox(height: 6),
                      _buildTextField(controller: fullNameController),
                      const SizedBox(height: 12),

                      _buildLabel('PHONE NUMBER'),
                      const SizedBox(height: 6),
                      _buildTextField(controller: phoneController),
                      const SizedBox(height: 12),

                      _buildLabel('USERNAME'),
                      const SizedBox(height: 6),
                      _buildTextField(controller: usernameController),
                      const SizedBox(height: 12),

                      _buildLabel('PASSWORD'),
                      const SizedBox(height: 6),
                      _buildTextField(obscureText: true, controller: passwordController),
                      const SizedBox(height: 12),

                      _buildLabel('LOCATION'),
                      const SizedBox(height: 6),
                      _buildTextField(controller: locationController),
                      const SizedBox(height: 30),

                      Center(
                        child: isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : _buildButton('REGISTER', darkNavyColor, () async {
                                setState(() => isLoading = true);
                                try {
                                  print("Attempting to connect to Register API...");
                                  final response = await http.post(
                                    Uri.parse('https://safewalk.uslsbsit.com/register.php'),
                                    body: jsonEncode({
                                      "fullname": fullNameController.text,
                                      "phone": phoneController.text,
                                      "username": usernameController.text,
                                      "password": passwordController.text,
                                      "location": locationController.text,
                                      "role": "User" 
                                    }),
                                    headers: {"Content-Type": "application/json"}
                                  );

                                  print("RAW SERVER RESPONSE (REGISTER): '${response.body}'");

                                  final data = jsonDecode(response.body);

                                  if (data['status'] == 'success') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(data['message']), backgroundColor: Colors.green)
                                    );
                                    Navigator.pop(context); 
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(data['message']), backgroundColor: Colors.red)
                                    );
                                  }
                                } catch (e) {
                                  print("THE REAL ERROR IS: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                                  );
                                } finally {
                                  setState(() => isLoading = false);
                                }
                              }),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: _buildMultilineButton('BACK TO\nLOGIN', darkNavyColor, () {
                          Navigator.pop(context); 
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SHARED HELPER WIDGETS
Widget _buildLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 9, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}

Widget _buildTextField({bool obscureText = false, TextEditingController? controller}) {
  return Container(
    height: 36, 
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4.0),
    ),
    child: TextField(
      controller: controller, 
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    ),
  );
}

Widget _buildButton(String text, Color textColor, VoidCallback onPressed) {
  return SizedBox(
    width: 130,
    height: 38,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
      ),
    ),
  );
}

Widget _buildMultilineButton(String text, Color textColor, VoidCallback onPressed) {
  return SizedBox(
    width: 130,
    height: 44, 
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w800, 
          fontSize: 11, 
          letterSpacing: 0.5,
          height: 1.2, 
        ),
      ),
    ),
  );
}