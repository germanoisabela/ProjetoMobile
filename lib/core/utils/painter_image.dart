import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Desenha um [CustomPainter] fora da tela e devolve uma imagem PNG.
Future<Uint8List> paintToPng(
  CustomPainter painter,
  Size size, {
  double pixelRatio = 3,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);

  canvas.scale(pixelRatio);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  painter.paint(canvas, size);

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(
    (size.width * pixelRatio).round(),
    (size.height * pixelRatio).round(),
  );
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);

  return data!.buffer.asUint8List();
}
