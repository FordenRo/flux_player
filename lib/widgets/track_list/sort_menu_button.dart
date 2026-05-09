import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';
import 'track_list.dart';

class SortMenuButton extends StatelessWidget {
  final void Function(Sorting sort) onSelected;

  const SortMenuButton({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) => OverlayMenuButton(
    alignment: .center,
    style: .new(padding: .zero, itemStyle: .new(height: 30)),
    onSelected: onSelected,
    items: [
      _buildItem('Name', Sorting.name),
      _buildItem('Artist', Sorting.artist),
      _buildItem('Date added', Sorting.dateAdded),
      _buildItem('Last played', Sorting.lastPlayed),
      _buildItem('Play count', Sorting.playCount),
    ],
    child: Padding(
      padding: const .symmetric(horizontal: 10, vertical: 5),
      child: Row(
        spacing: 8,
        children: [
          SizedBox(),
          Text('Name', style: .new(color: Colors.grey.shade500)),
          Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade500),
        ],
      ),
    ),
  );

  OverlayMenuItem<T> _buildItem<T>(String text, T value) => OverlayMenuItem<T>(
    value: value,
    child: Padding(padding: const .symmetric(horizontal: 8), child: Text(text)),
  );
}
