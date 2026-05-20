import 'package:flutter/material.dart';

class SearchField extends StatefulWidget {
  const SearchField({required this.onChanged, required this.hint, super.key});
  final void Function(String query) onChanged;
  final String hint;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(horizontal: 18),
    child: TextField(
      controller: controller,
      onChanged: widget.onChanged,
      style: const .new(fontSize: 14),
      decoration: .new(
        icon: Icon(Icons.search, color: Colors.grey.shade600, size: 18),
        hintText: widget.hint,
        hintStyle: .new(color: Colors.grey.shade500),
        border: .none,
        isDense: true,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade600),
                onPressed: () {
                  controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        contentPadding: const .symmetric(vertical: 12),
      ),
    ),
  );
}
