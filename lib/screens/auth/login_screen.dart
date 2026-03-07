import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authActionProvider.notifier).signInWithEmail(
          email:    _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!ok && mounted) _shake();
  }

  Future<void> _googleSignIn() async {
    await ref.read(authActionProvider.notifier).signInWithGoogle();
  }

  void _shake() {
    // A simple visual shake is handled via the error state rebuild.
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
              borderRadius: BorderRadius.circular(12),
            ),
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
              const SizedBox(height: 60),

              // ── Logo + headline ──────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent,
                            AppColors.accentHover,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('⚔️', style: TextStyle(fontSize: 34)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('GuildChat',
                        style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      'Your gaming squad awaits',
                      style: AppTextStyles.chatPreview.copyWith(
                          fontSize: 15, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Email field ──────────────────────────────────
              const FieldLabel('Email'),
              const SizedBox(height: 6),
              InputField(
                controller: _emailCtrl,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // ── Password field ───────────────────────────────
              const FieldLabel('Password'),
              const SizedBox(height: 6),
              InputField(
                controller: _passwordCtrl,
                hint: '••••••••',
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
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

              const SizedBox(height: 8),

              // ── Forgot password ──────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showForgotPassword(context),
                  child: Text(
                    'Forgot password?',
                    style: AppTextStyles.chatPreview.copyWith(
                      color: AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Sign in button ───────────────────────────────
              PrimaryButton(
                label: 'Sign In',
                isLoading: authState.isLoading,
                onTap: _signIn,
              ),

              const SizedBox(height: 16),

              // ── Divider ──────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: AppTextStyles.chatPreview
                          .copyWith(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 16),

              // ── Google sign-in ───────────────────────────────
              GoogleButton(
                isLoading: authState.isLoading,
                onTap: _googleSignIn,
              ),

              const SizedBox(height: 32),

              // ── Register link ────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const RegisterScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account?  ",
                      style: AppTextStyles.chatPreview
                          .copyWith(color: AppColors.textMuted, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Create one',
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
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset Password',
                style: AppTextStyles.screenTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              "We'll send a reset link to your email.",
              style: AppTextStyles.chatPreview
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            InputField(
              controller: ctrl,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Send Reset Link',
              isLoading: false,
              onTap: () async {
                await ref
                    .read(authServiceProvider)
                    .sendPasswordReset(ctrl.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset email sent!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}