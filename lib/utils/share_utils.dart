import 'package:flutter/widgets.dart';

/// Rect de origen para el diálogo de compartir.
///
/// iOS exige `sharePositionOrigin` (ancla del popover); sin él share_plus
/// lanza PlatformException. En Android se ignora.
Rect shareOriginOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && box.size != Size.zero) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQuery.of(context).size;
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 1,
    height: 1,
  );
}
