import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _handleCtrl   = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscure        = true;
  bool _obscureConfirm = true;
  String? _validationError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'Display name is required.';
    if (_handleCtrl.text.trim().isEmpty) return 'Handle is required.';
    if (!_handleCtrl.text.startsWith('#')) return 'Handle must start with #';
    if (_emailCtrl.text.trim().isEmpty) return 'Email is required.';
    if (!_emailCtrl.text.contains('@')) return 'Enter a valid email.';
    if (_passwordCtrl.text.length < 6)
      return 'Password must be at least 6 characters.';
    if (_passwordCtrl.text != _confirmCtrl.text)
      return "Passwords don't match.";
    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    setState(() => _validationError = null);

    await ref.read(authActionProvider.notifier).registerWithEmail(
          email:       _emailCtrl.text.trim(),
          password:    _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
          handle:      _handleCtrl.text.trim(),
        );
  }

  Future<void> _googleSignIn() async {
    await ref.read(authActionProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authActionProvider);

    ref.listen<AuthActionState>(authActionProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(authActionProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          size: 22, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Create Account',
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 20)),
                ],
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Text(
                  'Join GuildChat and find your squad',
                  style: AppTextStyles.chatPreview.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const FieldLabel('Display Name'),
              const SizedBox(height: 6),
              InputField(
                controller: _nameCtrl,
                hint: 'NightWarden',
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              const FieldLabel('Handle'),
              const SizedBox(height: 4),
              Text(
                'This is how friends find you. Must start with #',
                style: AppTextStyles.chatPreview.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              InputField(
                controller: _handleCtrl,
                hint: '#nightwarden_gg',
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              const FieldLabel('Email'),
              const SizedBox(height: 6),
              InputField(
                controller: _emailCtrl,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              const FieldLabel('Password'),
              const SizedBox(height: 6),
              InputField(
                controller: _passwordCtrl,
                hint: '••••••••',
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const FieldLabel('Confirm Password'),
              const SizedBox(height: 6),
              InputField(
                controller: _confirmCtrl,
                hint: '••••••••',
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              if (_validationError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: AppTextStyles.chatPreview.copyWith(
                            fontSize: 12.5,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Create Account',
                isLoading: authState.isLoading,
                onTap: _register,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: AppTextStyles.chatPreview.copyWith(
                            color: AppColors.textMuted, fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 16),

              GoogleButton(
                isLoading: authState.isLoading,
                onTap: _googleSignIn,
              ),

              const SizedBox(height: 28),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account?  ',
                      style: AppTextStyles.chatPreview.copyWith(
                          color: AppColors.textMuted, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Sign in',
                          style: AppTextStyles.chatPreview.copyWith(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}