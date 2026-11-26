import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/repositories/project_repository.dart';

/// Tela de apresentação exibida antes da área principal do SmartFloor.
class WelcomePage extends StatelessWidget {
  final AuthRepository? authRepository;
  final ProjectRepository? projectRepository;

  const WelcomePage({
    super.key,
    this.authRepository,
    this.projectRepository,
  });

  void _openHome(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(
          authRepository: authRepository,
          projectRepository: projectRepository,
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Planeje seu espaço'),
        content: const Text(
          'Capture um ambiente com a câmera, importe uma imagem ou PDF e '
          'organize seus projetos para transformar suas ideias em plantas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _BrandMark()),
                  const SizedBox(height: 16),
                  Text(
                    'SmartFloor',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transforme espaços em novos planos.',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _RoomPreview(),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.photo_camera_outlined,
                          title: 'Capturar ambiente',
                          subtitle: 'Câmera, AR ou LiDAR',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.image_outlined,
                          title: 'Imagem ou PDF',
                          subtitle: 'Importe sua planta',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.draw_outlined,
                          title: 'Plantas',
                          subtitle: 'Organize seus projetos',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _openHome(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Começar agora'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _showMore(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('Saiba mais'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(painter: _BrandMarkPainter()),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final house = Path()
      ..moveTo(size.width * 0.16, size.height * 0.43)
      ..lineTo(size.width * 0.5, size.height * 0.14)
      ..lineTo(size.width * 0.84, size.height * 0.43)
      ..lineTo(size.width * 0.84, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.87,
        size.width * 0.77,
        size.height * 0.87,
      )
      ..lineTo(size.width * 0.23, size.height * 0.87)
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.87,
        size.width * 0.16,
        size.height * 0.8,
      )
      ..close();
    canvas.drawPath(house, outlinePaint);

    final leafPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final leaf = Path()
      ..moveTo(size.width * 0.48, size.height * 0.67)
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.52,
        size.width * 0.53,
        size.height * 0.37,
        size.width * 0.67,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.49,
        size.width * 0.61,
        size.height * 0.61,
        size.width * 0.48,
        size.height * 0.67,
      )
      ..close();
    canvas.drawPath(leaf, leafPaint);
    canvas.drawLine(
      Offset(size.width * 0.46, size.height * 0.68),
      Offset(size.width * 0.61, size.height * 0.45),
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => false;
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomPreview extends StatelessWidget {
  const _RoomPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 190,
        child: const _RoomIllustration(),
      ),
    );
  }
}

class _RoomIllustration extends StatelessWidget {
  const _RoomIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE9F0E9), Color(0xFFC9D8C9)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 20,
              width: constraints.maxWidth * 0.36,
              height: 112,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FCF8),
                  border: Border.all(color: Colors.white, width: 5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(color: const Color(0xFFBDD7D4)),
                    ),
                    Container(width: 4, color: Colors.white),
                    Expanded(
                      child: Container(color: const Color(0xFFD4E3DE)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 18,
              child: Icon(
                Icons.weekend_rounded,
                size: constraints.maxWidth * 0.43,
                color: const Color(0xFF9D8D7D),
              ),
            ),
            Positioned(
              right: 14,
              top: 18,
              width: constraints.maxWidth * 0.43,
              height: 132,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF174B38),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB7CFBB), width: 3),
                ),
                child: const CustomPaint(painter: _FloorPlanPainter()),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 22,
              child: Container(color: const Color(0xFFE6DFD2)),
            ),
          ],
        );
      },
    );
  }
}

class _FloorPlanPainter extends CustomPainter {
  const _FloorPlanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF8BB39A).withOpacity(0.28)
      ..strokeWidth = 0.7;
    for (var x = 10.0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 10.0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final planPaint = Paint()
      ..color = const Color(0xFFD2E7D7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final plan = Path()
      ..moveTo(size.width * 0.15, size.height * 0.18)
      ..lineTo(size.width * 0.82, size.height * 0.18)
      ..lineTo(size.width * 0.82, size.height * 0.78)
      ..lineTo(size.width * 0.15, size.height * 0.78)
      ..close()
      ..moveTo(size.width * 0.48, size.height * 0.18)
      ..lineTo(size.width * 0.48, size.height * 0.53)
      ..lineTo(size.width * 0.82, size.height * 0.53)
      ..moveTo(size.width * 0.15, size.height * 0.49)
      ..lineTo(size.width * 0.48, size.height * 0.49);
    canvas.drawPath(plan, planPaint);
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) => false;
}
