import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:qBitRemote/widgets/customdivider.dart';

class AddtorrentDialog extends StatefulWidget {
  final Function(String?, String?, List<String>, File?) onAdd;
  final Future<void> Function(
          String? url, String? category, List<String> tags, File? torrentFile)
      addTorrent;
  final List<String> categories;
  final List<String> tags;

  AddtorrentDialog({
    Key? key,
    required this.onAdd,
    required this.addTorrent,
    required this.categories,
    required this.tags,
  }) : super(key: key);

  @override
  _AddtorrentDialogState createState() => _AddtorrentDialogState();
}

class _AddtorrentDialogState extends State<AddtorrentDialog> {
  final TextEditingController _magnetController = TextEditingController();
  String? _selectedCategory;
  List<String> _selectedTags = [];

  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result;
      if (!kIsWeb && Platform.isLinux) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['torrent'],
          allowMultiple: false,
          withData: true, // This ensures we get the file data
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['torrent'],
          allowMultiple: false,
        );
      }

      if (result != null) {
        setState(() {
          _selectedFile = result?.files.first;
        });
        print('File selected: ${_selectedFile?.name}');
      } else {
        print('No file selected');
      }
    } catch (e) {
      print('Error picking file: $e');
      // You can show an error message to the user here if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      autocorrect: false,
                      style: const TextStyle(color: Colors.black),
                      cursorColor: Colors.black,
                      controller: _magnetController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Magnet Link',
                        labelStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.orangeAccent[200],
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: _pickFile,
                      child: Text(
                        _selectedFile != null
                            ? 'Change Torrent File'
                            : 'Select Torrent File',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  if (_selectedFile != null)
                    Text(_selectedFile!.name,
                        style: const TextStyle(color: Colors.black)),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const Text("Categories",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const CustomDivider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: widget.categories.map((String category) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedCategory == category
                            ? Colors.orange
                            : Colors.grey,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Text(category),
                    );
                  }).toList(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Text("Tags",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const CustomDivider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: widget.tags.map((String tag) {
                    return FilterChip(
                      backgroundColor: Colors.grey,
                      disabledColor: Colors.orange,
                      selectedColor: Colors.yellow,
                      checkmarkColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      label: Text(tag,
                          style: const TextStyle(color: Colors.black)),
                      selected: _selectedTags.contains(tag),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: () async {
                  String? url = _magnetController.text.trim().isNotEmpty
                      ? _magnetController.text.trim()
                      : null;
                  File? torrentFile =
                      _selectedFile != null ? File(_selectedFile!.path!) : null;
                  widget.onAdd(
                      url, _selectedCategory, _selectedTags, torrentFile);
                  await widget.addTorrent(
                      url, _selectedCategory, _selectedTags, torrentFile);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Add Torrent',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
