import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Indicador de progresso do fluxo: círculos numerados ligados por linhas.
/// Exemplo com currentStep = 1 e totalSteps = 4:  (1)───(2)───(3)───(4)
class CaptureStepIndicator extends StatelessWidget {
  final String title;
  final int currentStep;
  final int totalSteps;

  const CaptureStepIndicator({
    super.key,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
  });

  /// Círculo numerado de um passo.
  /// Passos já alcançados ficam verdes; os demais, cinza.
  Widget _buildCircle(int step) {
    final bool reached = step <= currentStep;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? AppColors.primary : Colors.grey.shade300,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: reached ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// Linha que liga um círculo ao próximo.
  Widget _buildLine(int step) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: step < currentStep ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Linha de cima: título + etiqueta "Etapa X de Y"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.highlight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Etapa $currentStep de $totalSteps',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Linha de baixo: círculos e linhas intercalados
            Row(
              children: [
                for (int step = 1; step <= totalSteps; step++) ...[
                  _buildCircle(step),
                  if (step < totalSteps) _buildLine(step),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
