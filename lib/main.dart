import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'dart:async'; // For async operations
import 'package:http/http.dart' as http; // For HTTP requests
// For JSON encoding and decoding
import 'package:geolocator/geolocator.dart'; // For location services

import 'package:flutter/services.dart'; // For handling platform-specific code

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Company Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
      routes: {
        '/attendance': (context) => const AttendancePage(),
        '/register': (context) => const NewDevicePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  String? _welcomeMessage; // New variable to store the welcome message

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _authenticateWithEmailPassword(email, password);
  }

  Future<void> _authenticateWithEmailPassword(
      String email, String password) async {
    final url = Uri.parse('https://reliancehrconsulting.com/atte/applogin.php');
    final prefs = await SharedPreferences.getInstance();
    final uniqueID = prefs.getString('uniqueID');

    if (uniqueID == null) {
      setState(() {
        _errorMessage = 'Device is not registered. Please register first.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'email': email,
          'password': password,
          'unique_id': uniqueID,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey('error')) {
          setState(() {
            _errorMessage = responseData['error'];
            _isLoading = false;
          });
          return;
        }

        final isDeviceRegistered = await _verifyDeviceRegistration(email);
        if (!isDeviceRegistered) {
          setState(() {
            _errorMessage = 'Device is not registered for this email.';
            _isLoading = false;
          });
          return;
        }

        final username =
            responseData['username']; // Fetch the username from the response
        setState(() {
          _welcomeMessage =
              "Hey $username, Welcome"; // Update the welcome message
          _isLoading = false;
        });

        // Save the username to SharedPreferences
        await prefs.setString(
            'username', username); // Storing the username in SharedPreferences
        // Wait for 5 seconds before navigating
        await Future.delayed(const Duration(seconds: 3));

        Navigator.pushReplacementNamed(context, '/attendance');
      } else {
        setState(() {
          _errorMessage = 'Error connecting to the server. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'An error occurred. Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  Future<bool> _verifyDeviceRegistration(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final uniqueID = prefs.getString('uniqueID');

    if (uniqueID == null) {
      setState(() {
        _errorMessage = 'Device is not registered. Please register first.';
        _isLoading = false;
      });
      return false;
    }

    final url = Uri.parse(
        'https://reliancehrconsulting.com/atte/deviceVerification.php');
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'email': email,
          'unique_id': uniqueID,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['isRegistered'] ?? false;
      } else {
        setState(() {
          _errorMessage = 'Error connecting to the server. Please try again.';
          _isLoading = false;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'An error occurred. Please check your internet connection.';
        _isLoading = false;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(), // Removed company name, kept it empty
        backgroundColor: const Color.fromARGB(
            255, 12, 76, 129), // Added a background color for the app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo at the top, centered
            Center(
              child: Image.asset(
                'assets/images/logo.png', // Make sure to add logo in your assets
                height: 150, // Adjust logo size as needed
              ),
            ),
            const SizedBox(height: 40), // Added some space after the logo

            // Welcome message if available
            if (_welcomeMessage != null) ...[
              Text(
                _welcomeMessage!,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],

            // Email input
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 10),

            // Password input
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 20),

            // Register Button
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pushNamed(context, '/register');
                    },
              child: const Text('Register Device'),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController emailLogoutController = TextEditingController();
  String message = '';
  bool isLoading = false;
  String messageType = '';
  String? username; // Declare username to hold the fetched value

  @override
  void initState() {
    super.initState();
    _loadStoredUsername(); // Fetch username when the page loads
  }

  // Get user location
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog();
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Show location services dialog
  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
              'Please enable location services in your device settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Show loading spinner
  void showSpinner() {
    setState(() {
      isLoading = true;
    });
  }

  // Hide loading spinner
  void hideSpinner() {
    setState(() {
      isLoading = false;
    });
  }

  // Display message with Android-style pop-up
  void displayMessage(String message, String type) {
    setState(() {
      this.message = message;
      messageType = type;
    });

    // Show an Android-style dialog for success or error message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(type == 'success' ? 'Success' : 'Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                // If the message is success and logout, navigate to login
                if (type == 'success') {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Handle login
  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      displayMessage('Please enter your email.', 'error');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uniqueID = prefs.getString('uniqueID');
    if (uniqueID == null) {
      displayMessage(
          'Device is not registered. Please register first.', 'error');
      return;
    }

    showSpinner();
    try {
      final position = await _determinePosition();

      final response = await http.post(
        Uri.parse('https://pan-asia.in/attendance/log.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'login',
          'email': email,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'uniqueID': uniqueID,
        },
      );

      final data = json.decode(response.body);

      if (data['uuid'] != null) {
        displayMessage('Login successful', 'success');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);

        // Check if username is present and non-null before saving it
        if (data['username'] != null && data['username'] is String) {
          await prefs.setString('username', data['username']);
        } else {
          // Handle the case where the username is missing or invalid
          //displayMessage('Username not found in the response', 'error');//
        }
      } else {
        displayMessage(data['error'] ?? 'Login failed', 'error');
      }
    } catch (e) {
      displayMessage('Login failed: ${e.toString()}', 'error');
    } finally {
      hideSpinner();
    }
  }

  // Handle logout
  Future<void> handleLogout() async {
    final email = emailLogoutController.text.trim();
    if (email.isEmpty) {
      displayMessage('Please enter your email.', 'error');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uniqueID = prefs.getString('uniqueID');
    if (uniqueID == null) {
      displayMessage(
          'Device is not registered. Please register first.', 'error');
      return;
    }

    showSpinner();
    try {
      final position = await _determinePosition();

      final response = await http.post(
        Uri.parse('https://pan-asia.in/attendance/log.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'logout',
          'email': email,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'uniqueID': uniqueID,
        },
      );

      final data = json.decode(response.body);

      if (data['message'] != null) {
        displayMessage(
            '$username, see you soon', 'success'); // Fixed string concatenation
      } else {
        displayMessage(data['error'] ?? 'Logout failed', 'error');
      }
    } catch (e) {
      displayMessage('Logout failed: ${e.toString()}', 'error');
    } finally {
      hideSpinner();
    }
  }

  // Load stored username from local storage
  Future<void> _loadStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString('username');
    if (storedUsername != null && storedUsername.isNotEmpty) {
      setState(() {
        username = storedUsername;
      });
    } else {
      displayMessage('No username found in local storage', 'warning');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance System'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 40,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                  ),
                  const SizedBox(height: 20),

                  // Move the username display here, make it bold and large
                  if (username != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Hello $username',
                        style: const TextStyle(
                          fontSize: 24, // Make the text larger
                          fontWeight: FontWeight.bold, // Make it bold
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  const SizedBox(
                      height: 20), // Add some space before the login box
                  // Login Box
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Login', style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailController,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: handleLogin,
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout Box
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Logout', style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailLogoutController,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: handleLogout,
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class NewDevicePage extends StatefulWidget {
  const NewDevicePage({super.key});

  @override
  _NewDevicePageState createState() => _NewDevicePageState();
}

class _NewDevicePageState extends State<NewDevicePage> {
  final TextEditingController emailController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  // Function to check email validity using regex
  bool isValidEmail(String email) {
    const emailPattern = r"^[^\s@]+@[^\s@]+\.[^\s@]+$";
    final regex = RegExp(emailPattern);
    return regex.hasMatch(email);
  }

  // Function to generate uniqueID using device properties
  Future<String> _generateUniqueId() async {
    try {
      final deviceModel = await const MethodChannel('com.example.device/model')
          .invokeMethod<String>('getDeviceModel');
      final manufacturer =
          await const MethodChannel('com.example.device/manufacturer')
              .invokeMethod<String>('getManufacturer');
      final brand = await const MethodChannel('com.example.device/brand')
          .invokeMethod<String>('getBrand');
      final deviceId = await const MethodChannel('com.example.device/device')
          .invokeMethod<String>('getDeviceId');

      return deviceModel! + manufacturer! + brand! + deviceId!;
    } catch (e) {
      // In case of failure, return a default value
      return 'UnknownDevice';
    }
  }

  Future<void> registerDevice() async {
    final email = emailController.text.trim();

    // Email validation
    if (!isValidEmail(email)) {
      setState(() {
        errorMessage = "Please enter a valid email address.";
      });
      return;
    }

    // Show loading spinner
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // First, check if the email is approved or pending
      final approvalResponse = await http.get(
        Uri.parse(
            'https://pan-asia.in/attendance/checkApprovalStatus.php?email=${Uri.encodeComponent(email)}'),
      );

      if (approvalResponse.statusCode == 200) {
        final approvalData = json.decode(approvalResponse.body);
        print('Approval status: $approvalData');
        // Handle approval status based on the response

        if (approvalData['adapprove'] == 'pending') {
          // Generate uniqueID using uuid
          const uuid = Uuid();
          final uniqueID = uuid
              .v4(); // Generates a unique ID (e.g., "9b0c1b8b-d2e4-4e68-b2b0-d11c0b431c1d")

          final registerResponse = await http.post(
            Uri.parse('https://pan-asia.in/attendance/registerDevice.php'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'email': email,
              'uniqueID': uniqueID,
            },
          );

          // Check the status code of the registration request
          if (registerResponse.statusCode != 200) {
            displayMessage(
                'Request failed with status: ${registerResponse.statusCode}',
                'error');
            return;
          }

          final registerData = json.decode(registerResponse.body);

          // Debugging: Log the registration response
          print("Response from registerDevice.php: $registerData");

          if (registerData['status'] == 'success') {
            // If registration is successful, store uniqueID locally
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('uniqueID', uniqueID);
            await prefs.setString('userEmail', email); // Store email

            setState(() {
              errorMessage = 'Your device was registered successfully';
            });
          } else {
            setState(() {
              errorMessage =
                  registerData['error'] ?? 'Failed to register device';
            });
          }
        } else {
          // If the approval status is not pending, show an error
          setState(() {
            errorMessage = 'Device approval status is not pending.';
          });
        }
      } else {
        print(
            'Failed to get approval status. Status code: ${approvalResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to display error or success message
  void displayMessage(String message, String type) {
    // Example: You could use a snackbar or alert dialog to display messages
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: type == 'error' ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Device')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: registerDevice,
                child: const Text('Register Device'),
              ),
          ],
        ),
      ),
    );
  }
}
