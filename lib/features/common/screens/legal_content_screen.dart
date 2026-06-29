import 'package:flutter/material.dart';
import '../../../api/api_service.dart';
import '../../../core/constants/color_constants.dart';

class LegalContentScreen extends StatefulWidget {
  final String type;
  final String title;

  const LegalContentScreen({
    Key? key,
    required this.type,
    required this.title,
  }) : super(key: key);

  @override
  State<LegalContentScreen> createState() => _LegalContentScreenState();
}

class _LegalContentScreenState extends State<LegalContentScreen> {
  final ApiService _api = ApiService();
  Future<dynamic>? _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = _api.getContent(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<dynamic>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final response = snapshot.data;
          if (response == null || response['success'] == false) {
            return Center(
              child: Text(
                response?['message'] ?? 'Content not found',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          final data = response['data'];
          final text = data['text'] ?? 'No content available.';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['title'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      data['title'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 40),
                if (data['updatedAt'] != null)
                  Text(
                    'Last updated: ${DateTime.parse(data['updatedAt']).toLocal().toString().split(' ').first}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
