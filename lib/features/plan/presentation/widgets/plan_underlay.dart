import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:printing/printing.dart';

import '../../domain/entities/point_2d.dart';

/// Imagem de referência posicionada no mesmo sistema de coordenadas em metros.
class PlanUnderlay {
  final ui.Image image;
  final Point2D origin;
  final double metersPerPixel;

  const PlanUnderlay({
    required this.image,
    required this.origin,
    required this.metersPerPixel,
  });

  double get widthM => image.width * metersPerPixel;
  double get heightM => image.height * metersPerPixel;

  PlanUnderlay scaledAbout(Point2D pivot, double factor) {
    if (!factor.isFinite || factor <= 0) {
      throw ArgumentError.value(factor, 'factor', 'Deve ser maior que zero.');
    }
    return PlanUnderlay(
      image: image,
      origin: Point2D(
        pivot.x + (origin.x - pivot.x) * factor,
        pivot.y + (origin.y - pivot.y) * factor,
      ),
      metersPerPixel: metersPerPixel * factor,
    );
  }

  static Future<PlanUnderlay> load(
    String path, {
    required bool isPdf,
  }) async {
    Uint8List bytes = await File(path).readAsBytes();
    if (isPdf) {
      bool rendered = false;
      await for (final PdfRaster page
          in Printing.raster(bytes, pages: const [0], dpi: 100)) {
        bytes = await page.toPng();
        rendered = true;
        break;
      }
      if (!rendered) {
        throw const FormatException('O PDF não possui uma primeira página.');
      }
    }

    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 1800,
      allowUpscaling: false,
    );
    try {
      final ui.FrameInfo frame = await codec.getNextFrame();
      return PlanUnderlay(
        image: frame.image,
        origin: const Point2D(0, 0),
        metersPerPixel: 20 / frame.image.width,
      );
    } finally {
      codec.dispose();
    }
  }
}
