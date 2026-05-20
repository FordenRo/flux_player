part of 'caption_widget.dart';

final captionController = CaptionController._internal();

class CaptionWidgetController {
  CaptionWidgetController();
  void Function()? _onRemove;

  void remove() => _onRemove!();

  void dispose() => _onRemove?.call();
}

class CaptionController {
  CaptionController._internal();
  late void Function(
    Widget Function(BuildContext context) builder,
    CaptionWidgetController controller,
  )?
  _onWidgetAdd;

  void addWidget({
    required Widget Function(BuildContext context) builder,
    required CaptionWidgetController controller,
  }) => _onWidgetAdd!(builder, controller);
}
