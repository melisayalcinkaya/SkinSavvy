import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/text_utils.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../state/session_controller.dart';
import '../../widgets/app_snack.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  bool _showPassword = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() {
      final session = context.read<SessionController>();
      return _isLogin
          ? session.signIn(_emailCtrl.text, _passwordCtrl.text)
          : session.signUp(_nameCtrl.text, _emailCtrl.text, _passwordCtrl.text);
    });
  }

  Future<void> _tryDemo() =>
      _run(() => context.read<SessionController>().signInDemo());

  /// Başarılı girişte yönlendirici oturum değişikliğini görür ve kullanıcıyı
  /// karşılama akışına ya da ana sayfaya kendisi götürür.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMode(bool login) => setState(() {
    _isLogin = login;
    _formKey.currentState?.reset();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'SkinSavvy',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin
                          ? 'Tekrar hoş geldiniz!'
                          : 'Cildinize özel rutin oluşturun',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _formCard(),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? 'Hesabınız yok mu? '
                              : 'Hesabınız var mı? ',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: _busy ? null : () => _setMode(!_isLogin),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(
                            _isLogin ? 'Kayıt olun' : 'Giriş yapın',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _demoButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            _toggle(),
            const SizedBox(height: 18),
            if (!_isLogin) ...[
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  'Adınız Soyadınız',
                  Icons.person_outline,
                ),
                validator: (v) => sanitizeInput(v ?? '').length < 2
                    ? 'Lütfen adınızı girin.'
                    : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: _decoration('ornek@email.com', Icons.mail_outline),
              validator: (v) => isValidEmail(v ?? '')
                  ? null
                  : 'Geçerli bir e-posta adresi girin.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              autofillHints: [
                _isLogin ? AutofillHints.password : AutofillHints.newPassword,
              ],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _busy ? null : _submit(),
              decoration: _decoration('Şifre', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Şifreyi gizle' : 'Şifreyi göster',
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textLight,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Şifrenizi girin.';
                if (!_isLogin && v.length < minPasswordLength) {
                  return 'Şifre en az $minPasswordLength karakter olmalı.';
                }
                return null;
              },
            ),
            if (_isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ForgotPasswordScreen(initialEmail: _emailCtrl.text),
                    ),
                  ),
                  child: const Text(
                    'Şifremi unuttum',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              )
            else
              const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
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

  Widget _demoButton() => OutlinedButton.icon(
    onPressed: _busy ? null : _tryDemo,
    icon: const Icon(
      Icons.play_circle_outline,
      color: AppColors.primary,
      size: 18,
    ),
    label: const Text(
      'Demo hesabıyla dene',
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _toggle() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: _toggleBtn('Giriş Yap', _isLogin, () => _setMode(true)),
        ),
        Expanded(
          child: _toggleBtn('Kayıt Ol', !_isLogin, () => _setMode(false)),
        ),
      ],
    ),
  );

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) => Semantics(
    button: true,
    selected: active,
    child: GestureDetector(
      onTap: _busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.primary : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    ),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textLight),
    prefixIcon: Icon(icon, color: AppColors.secondary),
  );
}
