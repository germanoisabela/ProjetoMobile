import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/device_capture_repository.dart';
import '../../domain/entities/capture_mode.dart';
import '../../domain/entities/captured_input.dart';
import '../../domain/repositories/capture_repository.dart';
import '../widgets/capture_option_card.dart';
import '../widgets/capture_step_indicator.dart';
import 'capture_preview_page.dart';

/// Dados de uma opção exibida na tela (classe privada, só usada aqui).
class _CaptureOption {
  final CaptureMode mode;
  final IconData icon;
  final String title;
  final String description;

  const _CaptureOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Etapa 1 do fluxo: o usuário escolhe COMO quer capturar o ambiente.
class CapturePage extends StatefulWidget {
  final CaptureRepository repository;

  const CapturePage({
    super.key,
    this.repository = const DeviceCaptureRepository(),
  });

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  bool _isSelecting = false;

  // Lista fixa com as três opções. Para adicionar uma nova no futuro,
  // basta incluir mais um item aqui (e no enum CaptureMode).
  static const List<_CaptureOption> _options = [
    _CaptureOption(
      mode: CaptureMode.camera,
      icon: Icons.photo_camera_outlined,
      title: 'Câmera',
      description: 'Tire uma foto do ambiente ou da planta.',
    ),
    _CaptureOption(
      mode: CaptureMode.imageOrPdf,
      icon: Icons.description_outlined,
      title: 'Imagem ou PDF',
      description: 'Envie uma planta baixa já existente.',
    ),
    _CaptureOption(
      mode: CaptureMode.arLidar,
      icon: Icons.view_in_ar_outlined,
      title: 'AR / LiDAR',
      description: 'Escaneie o ambiente em tempo real (Android).',
    ),
  ];

  /// Mostra uma mensagem temporária na parte de baixo da tela.
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Chamada quando o usuário escolhe uma opção.
  Future<void> _onOptionSelected(BuildContext context, CaptureMode mode) async {
    if (_isSelecting) return;
    setState(() => _isSelecting = true);

    try {
      final CaptureRepository repository = widget.repository;
      CapturedInput? input;

      switch (mode) {
        case CaptureMode.camera:
          input = await repository.pickFromCamera();
          break;
        case CaptureMode.imageOrPdf:
          input = await repository.pickImageOrPdf();
          break;
        case CaptureMode.arLidar:
          _showMessage(context, 'Escaneamento AR / LiDAR: em breve!');
          return;
      }

      if (input == null || !context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CapturePreviewPage(input: input!)),
      );
    } on PlatformException {
      if (context.mounted) {
        _showMessage(context, 'Não foi possível abrir essa opção.');
      }
    } on FileSystemException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    } on UnsupportedError catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message ?? 'Opção indisponível.');
      }
    } finally {
      if (mounted) setState(() => _isSelecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // O botão "voltar" aparece sozinho, pois esta tela foi aberta
      // por cima da Home com Navigator.push.
      appBar: AppBar(
        title: const Text(
          'SmartFloor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CaptureStepIndicator(
            title: 'Capturar Ambiente',
            currentStep: 1,
            totalSteps: 4,
          ),
          const SizedBox(height: 24),

          Text(
            'Como você quer capturar seu ambiente?',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Escolha a melhor opção para o seu caso.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Um card para cada opção da lista
          for (final option in _options) ...[
            CaptureOptionCard(
              icon: option.icon,
              title: option.title,
              description: option.description,
              onTap: _isSelecting
                  ? () {}
                  : () => _onOptionSelected(context, option.mode),
            ),
            const SizedBox(height: 12),
          ],

          if (_isSelecting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            ),

          const SizedBox(height: 4),
          _buildTipCard(textTheme),
        ],
      ),
    );
  }

  /// Dica no final da tela.
  Widget _buildTipCard(TextTheme textTheme) {
    return Card(
      color: AppColors.highlight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dica',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Para melhorar os resultados, mantenha o ambiente '
                    'bem iluminado e evite obstruções na imagem.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
