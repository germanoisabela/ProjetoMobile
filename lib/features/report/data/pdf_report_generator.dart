import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../../plan/domain/entities/floor_plan.dart';
import '../../plan/domain/entities/plan.dart';
import '../../rules/domain/entities/building_alert.dart';
import '../../rules/domain/entities/rule_settings.dart';
import '../../rules/domain/entities/site.dart';
import '../../rules/domain/entities/suggestion.dart';
import '../../rules/domain/services/building_rule_checker.dart';
import '../../rules/domain/services/suggestion_engine.dart';

/// Monta o relatório em PDF.
class PdfReportGenerator {
  const PdfReportGenerator();

  static final PdfColor _primary = PdfColor.fromInt(0xFF1B5E20);
  static final PdfColor _light = PdfColor.fromInt(0xFFDCEFDD);
  static final PdfColor _muted = PdfColor.fromInt(0xFF5F6F65);
  static final PdfColor _error = PdfColor.fromInt(0xFFC62828);
  static final PdfColor _errorBg = PdfColor.fromInt(0xFFFDECEA);
  static final PdfColor _warning = PdfColor.fromInt(0xFFE65100);
  static final PdfColor _warningBg = PdfColor.fromInt(0xFFFFF3E0);
  static final PdfColor _infoBg = PdfColor.fromInt(0xFFF1F8F2);

  Future<Uint8List> generate({
    required Plan plan,
    required Site site,
    required RuleSettings settings,
    required Uint8List planImage,
    required Uint8List siteImage,
    FloorPlan? floorPlan,
    DateTime? generatedAt,
  }) async {
    final List<BuildingAlert> alerts = const BuildingRuleChecker().check(
      plan: plan,
      site: site,
      settings: settings,
      occupiedAreaM2: floorPlan?.builtAreaM2,
    );
    final List<Suggestion> suggestions = const SuggestionEngine().suggest(
      plan: plan,
      site: site,
      settings: settings,
      occupiedAreaM2: floorPlan?.builtAreaM2,
    );
    final DateTime date = generatedAt ?? DateTime.now();

    final pw.Document doc = pw.Document(
      title: 'SmartFloor - ${plan.name}',
      author: 'SmartFloor',
    );

    final pw.MemoryImage planPicture = pw.MemoryImage(planImage);
    final pw.MemoryImage sitePicture = pw.MemoryImage(siteImage);
    final double builtArea = floorPlan?.builtAreaM2 ?? plan.areaM2;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        footer: _footer,
        build: (pw.Context context) => [
          _title(plan, date),
          _section('Resumo da planta'),
          pw.Row(
            children: [
              _metric('${formatDecimal(builtArea)} m²', 'Área construída'),
              pw.SizedBox(width: 8),
              _metric('${formatDecimal(plan.perimeterM)} m', 'Perímetro'),
              if (floorPlan == null) ...[
                pw.SizedBox(width: 8),
                _metric('${plan.walls.length}', 'Paredes'),
              ] else ...[
                pw.SizedBox(width: 8),
                _metric('${floorPlan.rooms.length}', 'Cômodos'),
              ],
            ],
          ),
          if (floorPlan != null) ...[
            _section('Cômodos'),
            for (final Plan room in floorPlan.rooms)
              pw.Container(
                width: double.infinity,
                margin: pw.EdgeInsets.only(bottom: 5),
                padding: pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: _light,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  '${room.name}: ${formatDecimal(room.areaM2)} m² '
                  '(${room.vertices.length} paredes)',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
          ],
          _section('Planta baixa com medições'),
          _picture(planPicture),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < plan.walls.length; i++)
                _chip(
                  'Parede ${i + 1}: ${formatDecimal(plan.walls[i].lengthM)} m',
                ),
            ],
          ),
          _section('Terreno e posição da construção (aproximação retangular)'),
          pw.Text(
            'Terreno de ${formatDecimal(site.widthM)} x '
            '${formatDecimal(site.lengthM)} m '
            '(${formatDecimal(site.areaM2)} m²).',
            style: pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 8),
          _picture(sitePicture),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('Esquerda: ${formatDecimal(site.leftSetbackM)} m'),
              _chip('Direita: ${formatDecimal(site.rightSetbackM(plan))} m'),
              _chip('Fundos: ${formatDecimal(site.rearSetbackM(plan))} m'),
              _chip('Frente: ${formatDecimal(site.frontSetbackM)} m'),
            ],
          ),
          pw.SizedBox(height: 8),
          ..._settingsLines(settings),
          _section('Alertas da análise preliminar'),
          ...alerts.map(_alertBox),
          _section('Sugestões'),
          if (suggestions.isEmpty)
            pw.Text(
              'Nenhuma sugestão: a configuração atual respeita as regras '
              'verificadas.',
              style: pw.TextStyle(fontSize: 11, color: _muted),
            )
          else
            ...suggestions.map(_suggestionBox),
          pw.SizedBox(height: 18),
          _disclaimer(),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _title(Plan plan, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SmartFloor',
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
        pw.Text(
          'Relatório de análise preliminar de planta baixa',
          style: pw.TextStyle(fontSize: 13, color: _muted),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _primary, thickness: 1.5),
        pw.SizedBox(height: 4),
        pw.Text(
          'Ambiente: ${plan.name}',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Gerado em ${_formatDateTime(date)}',
          style: pw.TextStyle(fontSize: 10, color: _muted),
        ),
      ],
    );
  }

  pw.Widget _section(String title) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: 18, bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: _primary,
        ),
      ),
    );
  }

  pw.Widget _metric(String value, String label) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _light,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
            ),
            pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _muted)),
          ],
        ),
      ),
    );
  }

  pw.Widget _picture(pw.MemoryImage image) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.SizedBox(
        height: 260,
        width: double.infinity,
        child: pw.Image(image, fit: pw.BoxFit.contain),
      ),
    );
  }

  pw.Widget _chip(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _light,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10)),
    );
  }

  List<pw.Widget> _settingsLines(RuleSettings settings) {
    final List<String> lines = [
      if (settings.minFrontSetbackM > 0)
        'Recuo frontal mínimo: ${formatDecimal(settings.minFrontSetbackM)} m',
      if (settings.minSideSetbackM > 0)
        'Recuo lateral mínimo: ${formatDecimal(settings.minSideSetbackM)} m',
      if (settings.minRearSetbackM > 0)
        'Recuo de fundos mínimo: ${formatDecimal(settings.minRearSetbackM)} m',
      if (settings.maxOccupancyPercent > 0)
        'Taxa de ocupação máxima: '
            '${formatDecimal(settings.maxOccupancyPercent)}%',
    ];

    if (lines.isEmpty) {
      return [
        pw.Text(
          'Nenhum parâmetro municipal foi informado.',
          style: pw.TextStyle(fontSize: 10, color: _muted),
        ),
      ];
    }

    return [
      pw.Text(
        'Parâmetros do município informados pelo usuário:',
        style: pw.TextStyle(fontSize: 10, color: _muted),
      ),
      for (final String line in lines)
        pw.Text(line, style: pw.TextStyle(fontSize: 10)),
    ];
  }

  pw.Widget _alertBox(BuildingAlert alert) {
    final PdfColor color = _severityColor(alert.severity);
    final PdfColor background = _severityBackground(alert.severity);

    return pw.Container(
      width: double.infinity,
      margin: pw.EdgeInsets.only(bottom: 8),
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: color, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            alert.title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(alert.message, style: pw.TextStyle(fontSize: 10)),
          if (alert.reference != null) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              alert.reference!,
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _suggestionBox(Suggestion suggestion) {
    return pw.Container(
      width: double.infinity,
      margin: pw.EdgeInsets.only(bottom: 8),
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _primary, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            suggestion.title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(suggestion.message, style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _disclaimer() {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _light,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'Verificação preliminar. Este relatório não substitui a análise de '
        'um profissional habilitado nem a consulta à legislação e à '
        'prefeitura do município.',
        style: pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SmartFloor - verificação preliminar',
            style: pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  PdfColor _severityColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.error => _error,
      AlertSeverity.warning => _warning,
      AlertSeverity.info => _primary,
    };
  }

  PdfColor _severityBackground(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.error => _errorBg,
      AlertSeverity.warning => _warningBg,
      AlertSeverity.info => _infoBg,
    };
  }

  String _formatDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }
}
