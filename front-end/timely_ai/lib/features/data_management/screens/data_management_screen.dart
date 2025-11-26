import 'package:flutter/material.dart';

// A generic screen for managing a list of items.
class DataManagementScreen<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T item) itemTitleBuilder;
  final Function(int index) onDelete;
  final Function(BuildContext context, T? item) onEdit;

  const DataManagementScreen({
    super.key,
    required this.title,
    required this.items,
    required this.itemTitleBuilder,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(itemTitleBuilder(item)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => onDelete(index),
              ),
              onTap: () => onEdit(context, item),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onEdit(context, null), // Pass null for creating a new item
        child: const Icon(Icons.add),
      ),
    );
  }
}