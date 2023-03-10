import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mynotes/assets/constants.dart' as constants;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [Text('JESTES')],
          ),
        ));
  }

  Future<Map<String, dynamic>> _getNotes(String token) async {
    final url = Uri.parse(constants.API_NOTES_CHECK);
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to load notes');
    }
  }
}
