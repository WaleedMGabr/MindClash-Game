import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindclash/core/theme/app_colors.dart';
import 'package:mindclash/core/theme/app_decorations.dart';
import 'package:mindclash/core/theme/app_text_styles.dart';
import 'package:mindclash/core/widgets/mindclash_logo.dart';
import 'package:mindclash/features/authentication/presentations/cubits/auth_cubit.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                content: Text('تم إنشاء الحساب بنجاح! مرحباً بك في Mind Clash'),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const MindClashLogo(
                        size: 76,
                        showWordmark: true,
                        showTagline: false,
                      ),
                      const SizedBox(height: 24),

                      // Glass Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppDecorations.glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'إنشاء حساب مقاتل',
                              style: AppTextStyles.h1(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'سجل اسمك وانضم لأقوى تحدي تضليل وذكاء',
                              style: AppTextStyles.bodySmall(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Username Input
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: AppDecorations.inputDecoration(
                                hintText: 'اختر اسماً فريداً',
                                labelText: 'اسم المستخدم (Username)',
                                prefixIcon: const Icon(Icons.person_outline, color: AppColors.neonLavender, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty || value.trim().contains(' ')) {
                                  return 'يرجى إدخال اسم مستخدم بدون مسافات';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

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
                                labelText: 'كلمة المرور (8 أحرف فأكثر)',
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

                            // Submit Button
                            ElevatedButton(
                              style: AppDecorations.primaryButtonStyle(),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthCubit>().signup(
                                              email: _emailController.text.trim().toLowerCase(),
                                              password: _passwordController.text,
                                              username: _usernameController.text.trim().toLowerCase(),
                                            );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text('انضم للقتال ⚡', style: AppTextStyles.button()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('لديك حساب بالفعل؟ ', style: AppTextStyles.bodySmall()),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              'تسجيل الدخول',
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
