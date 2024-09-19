import 'package:flutter/material.dart';
import 'dart:io';

class GalleryPage extends StatelessWidget {
  final Directory directory;

  GalleryPage({Key? key, required this.directory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeria'),
      ),
      body: FutureBuilder<List<File>>(
        future: _loadMediaFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma mídia encontrada.'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final file = snapshot.data![index];
              return Image.file(
                file,
                fit: BoxFit.cover,
              );
            },
          );
        },
      ),
    );
  }

  Future<List<File>> _loadMediaFiles() async {
    final List<File> files = [];
    final mediaDir = directory;
    final mediaFiles = mediaDir.listSync();

    for (var file in mediaFiles) {
      if (file is File && (file.path.endsWith('.jpg') || file.path.endsWith('.mp4'))) {
        files.add(file);
      }
    }

    return files;
  }
}
