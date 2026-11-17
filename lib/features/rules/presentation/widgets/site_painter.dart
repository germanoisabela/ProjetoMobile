import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../plan/domain/entities/plan.dart';
import '../../domain/entities/site.dart';
import '../../domain/services/building_rule_checker.dart';

/// Desenha o terreno, a construção dentro dele e as distâncias até as divisas.
class SitePainter extends CustomPainter {
  final Plan plan;
  final Site site;

  const SitePainter({required this.plan, required this.site});

  static const double _margin = 44;
  static const Color _warningColor = Color(0xFFE65100); // laranja escuro
  static const Color _errorColor = Color(0xFFC62828);   // vermelho

  @override
  void paint(Canvas canvas, Size size) {
    // Escala: pixels por metro, para o terreno inteiro caber na tela.
    final double scale = math.min(
      (size.width - 2 * _margin) / site.widthM,
      (size.height - 2 * _margin) / site.lengthM,
    );
    final Offset origin = Offset(
      (size.width - site.widthM * scale) / 2,
      (size.height - site.lengthM * scale) / 2,
    );

    // Converte metros (no sistema do terreno) em pixels.
    Offset toCanvas(double x, double y) {
      return Offset(origin.dx + x * scale, origin.dy + y * scale);
    }

    final double left = site.leftSetbackM;
    final double right = site.rightSetbackM(plan);
    final double front = site.frontSetbackM;
    final double rear = site.rearSetbackM(plan);

    // ---------- Terreno ----------
    final Rect siteRect = Rect.fromPoints(
      toCanvas(0, 0),
      toCanvas(site.widthM, site.lengthM),
    );
    canvas.drawRect(siteRect, Paint()..color = Colors.white);
    canvas.drawRect(
      siteRect,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ---------- Construção ----------
    // Cada vértice da planta é deslocado para a posição dentro do terreno.
    final List<Offset> footprint = plan.vertices
        .map((v) => toCanvas(left + v.x - plan.minX, rear + v.y - plan.minY))
        .toList();
    final Path building = Path()..addPolygon(footprint, true);

    canvas.drawPath(building, Paint()..color = AppColors.highlight);
    canvas.drawPath(
      building,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    // ---------- Distâncias até as divisas ----------
    final Rect b = Rect.fromPoints(
      toCanvas(left, rear),
      toCanvas(left + plan.boundingWidthM, rear + plan.boundingHeightM),
    );

    // Esquerda
    _drawDistance(
      canvas,
      Offset(siteRect.left, b.center.dy),
      Offset(b.left, b.center.dy),
      left,
      isNeighbor: true,
      labelOffset: const Offset(0, -12),
    );
    // Direita
    _drawDistance(
      canvas,
      Offset(b.right, b.center.dy),
      Offset(siteRect.right, b.center.dy),
      right,
      isNeighbor: true,
      labelOffset: const Offset(0, -12),
    );
    // Fundos (em cima)
    _drawDistance(
      canvas,
      Offset(b.center.dx, siteRect.top),
      Offset(b.center.dx, b.top),
      rear,
      isNeighbor: true,
      labelOffset: const Offset(34, 0),
    );
    // Frente (embaixo, lado da rua)
    _drawDistance(
      canvas,
      Offset(b.center.dx, b.bottom),
      Offset(b.center.dx, siteRect.bottom),
      front,
      isNeighbor: false,
      labelOffset: const Offset(34, 0),
    );

    // Identificação da rua
    _drawText(
      canvas,
      'RUA (frente)',
      Offset(siteRect.center.dx, siteRect.bottom + 22),
      AppColors.textSecondary,
      fontSize: 11,
    );
  }

  /// Linha de cota entre [from] e [to], com o valor escrito no meio.
  /// A cor indica a situação: vermelho (fora do terreno),
  /// laranja (menos de 1,50 m de um vizinho) ou verde (ok).
  void _drawDistance(
    Canvas canvas,
    Offset from,
    Offset to,
    double valueM, {
    required bool isNeighbor,
    required Offset labelOffset,
  }) {
    Color color = AppColors.primary;
    if (valueM < 0) {
      color = _errorColor;
    } else if (isNeighbor &&
        valueM < BuildingRuleChecker.civilCodeDistanceM - 0.001) {
      color = _warningColor;
    }

    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color
        ..strokeWidth = 1.5,
    );

    _drawText(
      canvas,
      '${formatDecimal(valueM)} m',
      (from + to) / 2 + labelOffset,
      color,
      withBackground: true,
    );
  }

  /// Escreve um texto centralizado em [center].
  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    Color color, {
    double fontSize = 12,
    bool withBackground = false,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset topLeft =
        center - Offset(textPainter.width / 2, textPainter.height / 2);

    if (withBackground) {
      // Fundo branco semitransparente para o texto não se perder no desenho.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (topLeft & textPainter.size).inflate(3),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xE6FFFFFF),
      );
    }
    textPainter.paint(canvas, topLeft);
  }

  @override
  bool shouldRepaint(covariant SitePainter oldDelegate) {
    return oldDelegate.plan != plan || oldDelegate.site != site;
  }
}
