import 'package:flutter/material.dart';

class TagInputField extends StatefulWidget {
  final List<String> initialTags;
  final Function(List<String>) onChanged;
  final String labelText;

  const TagInputField({
    super.key,
    required this.initialTags,
    required this.onChanged,
    this.labelText = 'Tags',
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  late final TextEditingController _textController;
  late final List<String> _tags;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _tags = List<String>.from(widget.initialTags);
  }

  void _addTag() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        widget.onChanged(_tags);
        _textController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.onChanged(_tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: 'Type and press enter to add',
          ),
          onFieldSubmitted: (_) => _addTag(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () => _removeTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}
