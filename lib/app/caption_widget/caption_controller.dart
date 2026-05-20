part of 'caption_widget.dart';

final captionController = CaptionController._internal();

class CaptionButtonController {
  CaptionButtonController();
  void Function()? _onRemove;

  void remove() => _onRemove!();

  void dispose() => _onRemove?.call();
}

class CaptionController {
  CaptionController._internal();
  late void Function(
    Widget Function(BuildContext context) builder,
    CaptionButtonController controller,
  )?
  _onButtonAdd;

  void addIconButton({
    required IconButton Function(BuildContext context) builder,
    required CaptionButtonController controller,
  }) => _onButtonAdd!(builder, controller);
}
