import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/pages/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _cepController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _cepController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirme que leu os termos e a política de privacidade'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  InputDecoration _decoration({
    required String label,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBCFCB)),
      ),
    );
  }

  Widget _requiredField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: action,
      decoration: _decoration(label: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Preencha este campo';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SmartFloor',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.home_work_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Faça o seu cadastro',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _requiredField(
                      controller: _nameController,
                      label: 'Nome',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(label: 'E-mail'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Preencha seu e-mail';
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Informe um e-mail válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _requiredField(
                      controller: _phoneController,
                      label: 'Telefone',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    _requiredField(
                      controller: _whatsappController,
                      label: 'Celular',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(label: 'CEP'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _cityController,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(label: 'Cidade'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(label: 'Idade'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final age = int.tryParse(value);
                        if (age == null || age < 1 || age > 120) {
                          return 'Informe uma idade válida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration(
                        label: 'Senha',
                        suffix: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe uma senha';
                        }
                        if (value.length < 6) {
                          return 'Use pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmation,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      decoration: _decoration(
                        label: 'Confirmar senha',
                        suffix: IconButton(
                          tooltip: _obscureConfirmation
                              ? 'Mostrar confirmação'
                              : 'Ocultar confirmação',
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmation =
                                !_obscureConfirmation,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Confirmar senha',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (value) => setState(
                        () => _acceptedTerms = value ?? false,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text(
                        'Li e concordo com os termos e condições',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _register,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
