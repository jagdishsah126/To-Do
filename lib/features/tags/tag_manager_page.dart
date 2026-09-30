import 'package:flutter/material.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/domain/tag.dart';
import 'package:uuid/uuid.dart';

class TagManagerPage extends StatefulWidget {
  const TagManagerPage({super.key, required this.tags});

  final TagRepository tags;

  @override
  State<TagManagerPage> createState() => _TagManagerPageState();
}

class _TagManagerPageState extends State<TagManagerPage> {
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tags = await widget.tags.getAll();
    if (mounted) setState(() => _tags = tags);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tags')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ..._tags.map(
            (t) => ListTile(
              leading: CircleAvatar(
                radius: 12,
                backgroundColor: Color(t.colorValue),
              ),
              title: Text(t.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editTag(t),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteTag(t),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add tag'),
            onTap: _addTag,
          ),
        ],
      ),
    );
  }

  Future<void> _addTag() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add tag'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Tag name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result == true && nameController.text.trim().isNotEmpty) {
      final tag = Tag(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
      );
      await widget.tags.create(tag);
      await _load();
    }
    nameController.dispose();
  }

  Future<void> _editTag(Tag tag) async {
    final nameController = TextEditingController(text: tag.name);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit tag'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Tag name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true && nameController.text.trim().isNotEmpty) {
      await widget.tags.update(tag.copyWith(name: nameController.text.trim()));
      await _load();
    }
    nameController.dispose();
  }

  Future<void> _deleteTag(Tag tag) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tag?'),
        content: Text('Delete "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (result == true) {
      await widget.tags.delete(tag.id);
      await _load();
    }
  }
}
