import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../onboarding/onboarding_flow.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                ), 
                const SizedBox(height: 14),
                const Text('SkinSavvy', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text(_isLogin ? 'Tekrar hoş geldiniz!' : 'Cildinize özel rutin oluşturun',
                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 4))]),
                  child: Column(children: [
                    _toggle(),
                    const SizedBox(height: 18),
                    _input(hint: 'ornek@email.com', icon: Icons.mail_outline),
                    const SizedBox(height: 14),
                    _input(hint: '••••••••', icon: Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingFlow())),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                            Text('Giriş Yap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                            SizedBox(width: 8), Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Hesabınız yok mu? ', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  GestureDetector(onTap: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Kayıt olun' : 'Giriş yapın', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Expanded(child: _toggleBtn('Giriş Yap', _isLogin, () => setState(() => _isLogin = true))),
      Expanded(child: _toggleBtn('Kayıt Ol', !_isLogin, () => setState(() => _isLogin = false))),
    ]),
  );

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(gradient: active ? AppGradients.primary : null, borderRadius: BorderRadius.circular(10)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textGrey)),
    ),
  );

  Widget _input({required String hint, required IconData icon, bool isPassword = false}) => TextField(
    obscureText: isPassword && !_showPassword,
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: AppColors.textLight),
      prefixIcon: Icon(icon, color: AppColors.secondary),
      suffixIcon: isPassword
          ? IconButton(icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textLight),
              onPressed: () => setState(() => _showPassword = !_showPassword))
          : null,
    ),
  );
}