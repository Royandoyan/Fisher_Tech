import 'package:flutter/material.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A9BAE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Developer Contacts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'INFORMATION OF DEVELOPER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F3C7E),
                ),
              ),
              const SizedBox(height: 25),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 25,
                children: const [
                  DeveloperProfile(
                    imagePath: 'assets/images/rea.png',
                    name: 'Rea Mae Royandoyan',
                    email: 'reamae@example.com',
                    contact: '+63 912 345 6789',
                  ),
                  DeveloperProfile(
                    imagePath: 'assets/images/charisa.png',
                    name: 'Charsa V. Carpon',
                    email: 'carponcharisa22@example.com',
                    contact: '+63 955 750 8437',
                  ),
                  DeveloperProfile(
                    imagePath: 'assets/images/cristin.png',
                    name: 'Cristina Taduyo',
                    email: 'cristina19ashley@example.com',
                    contact: '+63 934 567 8901',
                  ),
                  DeveloperProfile(
                    imagePath: 'assets/images/eman.png',
                    name: 'Jerecho Eman',
                    email: 'jerechovlcrts@example.com',
                    contact: '+63 965 955 4576',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeveloperProfile extends StatelessWidget {
  final String imagePath;
  final String name;
  final String email;
  final String contact;

  const DeveloperProfile({
    required this.imagePath,
    required this.name,
    required this.email,
    required this.contact,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          // Fallback if image fails to load
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: AssetImage(imagePath),
            child: Image.asset(
              imagePath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.person, size: 30, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF7A9BAE),
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7A9BAE),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              contact,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}