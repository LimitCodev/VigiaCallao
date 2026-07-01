import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// Pantalla de login (Sección 13.1). En escritorio aprovechamos el
/// ancho con un layout split: panel de marca a la izquierda (gradiente
/// institucional, el único lugar donde el azul marino domina toda
/// la superficie, a propósito, como "puerta de entrada") y formulario
/// a la derecha sobre el fondo grafito estándar de la app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _handleLogin() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Ingresa tu usuario y contraseña.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.backendUrl}/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': _userCtrl.text.trim(),
              'password': _passCtrl.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => _loading = false);

      if (res.statusCode == 200) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        setState(() => _error = 'Usuario o contraseña incorrectos.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo conectar al backend. Verifica que el servidor esté corriendo.';
      });
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Panel de marca — visible solo en ventanas anchas de escritorio
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.brandGradient),
              child: Stack(
                children: [
                  Positioned(
                    right: -80,
                    top: -80,
                    child: _glowCircle(260, AppColors.accent.withValues(alpha: 0.18)),
                  ),
                  Positioned(
                    left: -60,
                    bottom: -60,
                    child: _glowCircle(220, AppColors.accent.withValues(alpha: 0.12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGlow,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.visibility_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('VigíaCallao', style: AppTextStyles.displayLg.copyWith(fontSize: 38)),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: 380,
                          child: Text(
                            'Inteligencia aplicada a las cámaras que ya existen '
                            'en el puerto. Detección en tiempo real de vehículos '
                            'detenidos en zonas restringidas.',
                            style: AppTextStyles.bodyLg.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _statRow('730', 'cámaras IP en la red municipal'),
                        const SizedBox(height: AppSpacing.sm),
                        _statRow('S/. 0', 'en licencias de software (open source)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Panel de formulario
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bienvenido de vuelta', style: AppTextStyles.displayMd),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Ingresa tus credenciales para acceder al centro de control.',
                        style: AppTextStyles.bodyMd,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Usuario', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _userCtrl,
                        style: AppTextStyles.bodyLg,
                        decoration: const InputDecoration(
                          hintText: 'tu.usuario',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Contraseña', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: AppTextStyles.bodyLg,
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleLogin,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Ingresar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _statRow(String value, String label) {
    return Row(
      children: [
        Text(value, style: AppTextStyles.titleLg.copyWith(color: AppColors.accent)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.bodySm)),
      ],
    );
  }
}
