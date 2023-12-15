import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final Logger logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Age Estimation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AgeEstimationScreen(),
    );
  }
}

class AgeEstimationScreen extends StatefulWidget {
  const AgeEstimationScreen({Key? key});

  @override
  _AgeEstimationScreenState createState() => _AgeEstimationScreenState();
}

class _AgeEstimationScreenState extends State<AgeEstimationScreen> {
  String name = '';
  int estimatedAge = 0;

  Future<void> getEstimatedAge() async {
    final String apiUrl = 'https://api.agify.io/?name=$name';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          estimatedAge = data['age'] ?? 0;
        });

        // Firestore Integration: Hinzugefügt
        await FirebaseFirestore.instance.collection('ageEstimations').add({
          'name': name,
          'estimatedAge': estimatedAge,
          'timestamp': FieldValue.serverTimestamp(),
        });

      } else {
        setState(() {
          estimatedAge = 0;
        });
      }
    } catch (error) {
      logger.e('Error: $error');
      setState(() {
        estimatedAge = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Age Estimation'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://images.crystalbridges.org/uploads/2015/11/Chaplin-The-Kid.jpg?_gl=1*842f1e*_gcl_au*NzYwMzgwMDAuMTcwMjAzODk0Mw..'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Enter a name',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  getEstimatedAge();
                  FirebaseAnalytics.instance.logEvent(
                    name: 'button_clicked',
                    parameters: null,
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent,
                  elevation: 5,
                ),
                child: const Text('Estimate Age'),
              ),
              const SizedBox(height: 16),
              if (name.isNotEmpty && estimatedAge > 0)
                Text(
                  'The estimated age is $estimatedAge',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 186, 233, 14),
                    fontSize: 28,
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}