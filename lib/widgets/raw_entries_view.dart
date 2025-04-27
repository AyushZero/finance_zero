import 'package:flutter/material.dart';

class RawEntriesView extends StatelessWidget {
  final List<String> entries;
  final Function(int) onDeleteEntry;

  const RawEntriesView({
    super.key,
    required this.entries,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No raw entries yet.', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Add entries by typing or speaking below.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key('entry_$index'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDeleteEntry(index),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ListTile(
              title: Text(entries[index]),
              leading: const Icon(Icons.note_alt),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDeleteEntry(index),
              ),
            ),
          ),
        );
      },
    );
  }
}