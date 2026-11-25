import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/home/presentation/pages/welcome_page.dart';

/// Widget raiz do app: configura tema e define a primeira tela.
class SmartFloorApp extends StatelessWidget {
  final AuthRepository? authRepository;

  const SmartFloorApp({
    super.key,
    this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFloor',
      debugShowCheckedModeBanner: false, // remove a faixa "DEBUG"
      theme: AppTheme.light,
      home: WelcomePage(authRepository: authRepository),
    );
  }
}
