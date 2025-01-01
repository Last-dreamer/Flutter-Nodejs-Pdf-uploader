import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Uploader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PDFUploaderScreen(),
    );
  }
}

class PDFUploaderScreen extends StatefulWidget {
  const PDFUploaderScreen({Key? key}) : super(key: key);

  @override
  State<PDFUploaderScreen> createState() => _PDFUploaderScreenState();
}

class _PDFUploaderScreenState extends State<PDFUploaderScreen> {
  File? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadPDF() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first.')),
      );
      return;
    }
    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://10.0.2.2:3002/api/notes/673ee89f783ef6a86e150450/add'),
      );

      // Add title field
      request.fields['title'] = 'Sample PDF';

      // Add the PDF file with correct field name 'noteFile'
      request.files.add(
        await http.MultipartFile.fromPath(
          'noteFile', // The field name should match the backend's expected name
          _selectedFile!.path,
          contentType: MediaType('application', 'pdf'), // Explicit MIME type
        ),
      );

      log('Uploading file: ${_selectedFile!.path}');
      log('Request fields: ${request.fields}');
      log('Request files: ${request.files}');

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF uploaded successfully.')),
        );
      } else {
        log('Response status: ${response.statusCode}');
        log('Response body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload PDF. Error: $responseBody')),
        );
      }
    } catch (e) {
      log("Error uploading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Uploader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedFile == null
                ? const Text('No file selected.',
                    style: TextStyle(fontSize: 16))
                : Text('Selected file: ${_selectedFile!.path.split('/').last}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickPDF,
              child: const Text('Pick PDF'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadPDF,
              child: _isUploading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('Upload PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
