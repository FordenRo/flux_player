import 'package:flutter/material.dart';
import 'package:flutter_show_menu/flutter_show_menu.dart';

const OverlayMenuStyle overlayMenuStyle = .new(
  itemStyle: .new(height: 30),
  padding: .zero,
);

Future<T?> showSimpleMenu<T>({
  required BuildContext context,
  required List<SimpleMenuItem<T>> items,
  T? initialValue,
  Offset offset = .zero,
  MenuPosition position = .bottom,
  MenuAlignment alignment = .start,
  OverlayMenuController? controller,
}) => showOverlayMenu(
  context: context,
  style: overlayMenuStyle,
  items: items
      .map(
        (e) => OverlayMenuItem<T>(
          child: Padding(
            padding: const .symmetric(horizontal: 10),
            child: Text(e.text),
          ),
          onTap: e.onTap,
          value: e.value,
        ),
      )
      .toList(),
  initialValue: initialValue,
  position: position,
  alignment: alignment,
  controller: controller,
  offset: offset,
);

class SimpleMenuItem<T> {
  const SimpleMenuItem({required this.text, this.onTap, this.value});
  final T? value;
  final String text;
  final void Function()? onTap;

  OverlayMenuItem<T> toOverlayItem() => OverlayMenuItem<T>(
    value: value,
    child: Padding(
      padding: const .symmetric(horizontal: 10),
      child: Text(text),
    ),
    onTap: onTap,
  );
}
