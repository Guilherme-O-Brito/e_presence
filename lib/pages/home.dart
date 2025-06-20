import 'package:e_presence/pages/create_classroom.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'E-Presence',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 54, 243),
      ),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
          ),
          icon: const Icon(Icons.add_circle_outline, size: 32),
          label: const Text(
            'Iniciar uma Aula',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CreateClassroom()));
          },
        ),
      ),
    );
  }
}
