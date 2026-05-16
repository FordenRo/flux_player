import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';
import '../simple_menu.dart';
import 'track_list.dart';

class SortMenuButton extends StatelessWidget {
  final void Function(Sorting sort) onSelected;
  final Sorting value;

  const SortMenuButton({
    super.key,
    required this.onSelected,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => OverlayMenuButton(
    alignment: .center,
    style: overlayMenuStyle,
    onSelected: onSelected,
    items: Sorting.values
        .map((e) => SimpleMenuItem(text: e.title, value: e).toOverlayItem())
        .toList(),
    child: Padding(
      padding: const .symmetric(horizontal: 10, vertical: 5),
      child: Row(
        spacing: 8,
        children: [
          SizedBox(),
          Text(value.title, style: .new(color: Colors.grey.shade500)),
          Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade500),
        ],
      ),
    ),
  );
}

extension on Sorting {
  String get title => switch (this) {
    .name => 'Название',
    .artist => 'Автор',
  };
}
