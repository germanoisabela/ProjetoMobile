import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/utils/painter_image.dart';
import '../../../plan/domain/entities/plan.dart';
import '../../../plan/presentation/widgets/plan_painter.dart';
import '../../../plan/presentation/widgets/plan_viewport.dart';
import '../../../rules/domain/entities/rule_settings.dart';
import '../../../rules/domain/entities/site.dart';
import '../../../rules/presentation/widgets/site_painter.dart';
import '../../data/pdf_report_generator.dart';

/// Visualizador do relatório em PDF, com opções de compartilhar e imprimir.
class ReportPage extends StatefulWidget {
  final Plan plan;
  final Site site;
  final RuleSettings settings;

  const ReportPage({
    super.key,
    required this.plan,
    required this.site,
    required this.settings,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late final Future<Uint8List> _pdf = _generate();

  Future<Uint8List> _generate() async {
    const Size drawingSize = Size(640, 440);

    final PlanViewport viewport = PlanViewport.fit(
      plan: widget.plan,
      canvasSize: drawingSize,
      margin: 56,
      growth: 1.0,
    );
    final Uint8List planImage = await paintToPng(
      PlanPainter(plan: widget.plan, viewport: viewport, showHandles: false),
      drawingSize,
    );

    final Uint8List siteImage = await paintToPng(
      SitePainter(plan: widget.plan, site: widget.site),
      drawingSize,
    );

    return const PdfReportGenerator().generate(
      plan: widget.plan,
      site: widget.site,
      settings: widget.settings,
      planImage: planImage,
      siteImage: siteImage,
    );
  }

  String get _fileName {
    final String safe = widget.plan.name.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return 'SmartFloor_$safe.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatório em PDF',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: PdfPreview(
        build: (format) => _pdf,
        pdfFileName: _fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
