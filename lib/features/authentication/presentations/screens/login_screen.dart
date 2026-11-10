import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindclash/core/theme/app_colors.dart';
import 'package:mindclash/core/theme/app_decorations.dart';
import 'package:mindclash/core/theme/app_text_styles.dart';
import 'package:mindclash/core/widgets/mindclash_logo.dart';
import 'package:mindclash/features/authentication/presentations/cubits/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidCanvas,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.cyberCrimson,
              ),
            );
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('مرحباً بك في ساحة Mind Clash!'),
                backgroundColor: AppColors.hyperEmerald,
              ),
            );
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const MindClashLogo(
                        size: 90,
                        showWordmark: true,
                        showTagline: true,
                      ),
                      const SizedBox(height: 36),

                      // Glass Card Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppDecorations.glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'تسجيل الدخول',
                              style: AppTextStyles.h1(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أدخل بياناتك للمنافسة في حرب العقول',
                              style: AppTextStyles.bodySmall(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Email Input
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: AppDecorations.inputDecoration(
                                hintText: 'example@domain.com',
                                labelText: 'البريد الإلكتروني',
                                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.neonLavender, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty || !value.contains('@')) {
                                  return 'يرجى إدخال بريد إلكتروني صحيح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: AppDecorations.inputDecoration(
                                hintText: '••••••••',
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.neonLavender, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty || value.length < 8) {
                                  return 'كلمة المرور يجب أن لا تقل عن 8 أحرف';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            ElevatedButton(
                              style: AppDecorations.primaryButtonStyle(),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthCubit>().login(
                                              email: _emailController.text.trim().toLowerCase(),
                                              password: _passwordController.text,
                                            );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text('دخول المعركة ⚔️', style: AppTextStyles.button()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Signup Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ليس لديك حساب بعد؟ ', style: AppTextStyles.bodySmall()),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed('/signup'),
                            child: Text(
                              'إنشاء حساب جديد',
                              style: AppTextStyles.bodySmall(color: AppColors.mintCyan).copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
