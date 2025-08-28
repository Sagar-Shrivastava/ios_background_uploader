import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ios_background_uploader/ios_background_uploader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS Background Uploader Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UploadDemoPage(),
    );
  }
}

class UploadDemoPage extends StatefulWidget {
  const UploadDemoPage({super.key});

  @override
  State<UploadDemoPage> createState() => _UploadDemoPageState();
}

class _UploadDemoPageState extends State<UploadDemoPage> {
  double _progress = 0.0;
  String _status = 'Idle';
  String _response = '';
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _listenToEvents();
  }

  void _listenToEvents() {
    _eventSub = IosBackgroundUploader.uploadEvents.listen((event) {
      setState(() {
        final status = event['status'];
        if (status == 'progress') {
          _status = 'Uploading...';
          _progress = (event['progress'] ?? 0.0) * 100;
        } else if (status == 'completed') {
          _status = 'Completed ✅';
          _progress = 100.0;
          _response = event['response'] ?? '';
        } else if (status == 'failed') {
          _status = 'Failed ❌';
          _response = event['error'] ?? 'Unknown error';
        }
      });
    });
  }

  Future<void> _startUpload() async {
    setState(() {
      _status = 'Starting upload...';
      _progress = 0.0;
      _response = '';
    });

    final files = [
      '/path/to/file1.jpg', // Replace with real file paths
      '/path/to/file2.jpg',
    ];

    await IosBackgroundUploader.uploadFiles(
      url: 'https://your-api-endpoint.com/upload',
      files: files,
      method: 'POST',
      headers: {
        'Authorization': 'Bearer your-token',
      },
      fields: {
        'user_id': '12345',
      },
      tag: 'example_upload',
    );
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Background Upload Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text('Progress: ${_progress.toStringAsFixed(2)}%'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _startUpload,
              child: const Text('Start Upload'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Response: $_response',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
