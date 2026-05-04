import 'package:flutter/material.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign, size: 80, color: Color(0xFF16a34a)),
          SizedBox(height: 16),
          Text('Reportes', style: TextStyle(fontSize: 24)),
          Text('Próximamente', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}