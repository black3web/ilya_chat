// File: lib/features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/utils/validators.dart';
import '../providers/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  String? _generatedId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(currentUserProvider.notifier).register(
        displayName: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final user = ref.read(currentUserProvider);
      if (user != null) {
        setState(() => _generatedId = user.id);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/home');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.4,
                colors: [Color(0xFF180010), AppColors.background],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Icon(Icons.arrow_back_ios_rounded,
                              color: AppColors.silver, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const AppLogoText(fontSize: 28),
                    const SizedBox(height: 4),
                    const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 30),
                    // ID notice banner
                    GlassContainer(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 14,
                      borderColor: AppColors.neonRed.withOpacity(0.4),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.neonRed, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'سيتم توليد معرف (ID) فريد مكوّن من 12 رقماً لحسابك تلقائياً ولا يمكن تغييره أبداً.',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 22,
                      showNeonGlow: true,
                      glowIntensity: 0.12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NeonText(text: AppStrings.register, fontSize: 20, glowRadius: 8),
                          const SizedBox(height: 24),
                          _field(
                            controller: _nameCtrl,
                            label: AppStrings.displayName,
                            hint: AppStrings.enterName,
                            icon: Icons.badge_outlined,
                            validator: AppValidators.validateDisplayName,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _usernameCtrl,
                            label: AppStrings.username,
                            hint: AppStrings.enterUsername,
                            icon: Icons.alternate_email_rounded,
                            prefix: '@',
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9_]')),
                            ],
                            validator: AppValidators.validateUsername,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _passCtrl,
                            label: AppStrings.password,
                            hint: AppStrings.enterPassword,
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.silverDim,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: AppValidators.validatePassword,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _confirmCtrl,
                            label: 'تأكيد كلمة المرور',
                            hint: 'أعد إدخال كلمة المرور',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureConfirm,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.silverDim,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'هذا الحقل مطلوب'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _errorBanner(_error!),
                          ],
                          if (_generatedId != null) ...[
                            const SizedBox(height: 12),
                            _idBanner(_generatedId!),
                          ],
                          const SizedBox(height: 24),
                          NeonButton(
                            label: AppStrings.register,
                            onTap: _register,
                            isLoading: _loading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          AppStrings.hasAccount,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const NeonText(
                              text: AppStrings.login,
                              fontSize: 13,
                              glowRadius: 6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefix,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
          fontFamily: 'Cairo', fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.silverDim, size: 20),
        prefixText: prefix,
        prefixStyle: const TextStyle(
            color: AppColors.neonRed,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.neonRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neonRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.neonRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 12, color: AppColors.neonRed)),
          ),
        ],
      ),
    );
  }

  Widget _idBanner(String id) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.idCopied)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.online.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.online.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تم إنشاء حسابك!',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.online,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'معرّفك: $id\n(اضغط للنسخ - لا يمكن تغييره)',
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
