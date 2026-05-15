part of 'caption_widget.dart';

final captionController = CaptionController._internal();

class CaptionButtonController {
  void Function()? _onRemove;

  CaptionButtonController();

  void remove() => _onRemove!();

  void dispose() => _onRemove?.call();
}

class CaptionController {
  void Function(
    Widget Function(BuildContext context) builder,
    CaptionButtonController controller,
  )?
  _onButtonAdd;

  CaptionController._internal();

  void addIconButton({
    required IconButton Function(BuildContext context) builder,
    required CaptionButtonController controller,
  }) => _onButtonAdd!(builder, controller);
}
