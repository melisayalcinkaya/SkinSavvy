import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML tag temizle
        .replaceAll(RegExp('[<>"\']'), '') // tehlikeli karakterler
        .trim();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Gerçek uygulamada Firebase:
      // await FirebaseAuth.instance
      //   .sendPasswordResetEmail(email: _sanitize(_emailCtrl.text));

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Firebase hata kodlarına göre mesaj:
      // FirebaseAuthException ile e.code kontrolü yapılır
      // 'user-not-found' → "Bu e-posta ile kayıtlı hesap bulunamadı."
      // 'invalid-email'  → "Geçersiz e-posta adresi."
      // 'too-many-requests' → "Çok fazla deneme. Lütfen bekleyin."
      _showError('Bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _emailSent ? _successView() : _formView(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white.withOpacity(0.95),
    padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
    child: Row(children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
      ),
      GestureDetector(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
        child: const Text('Şifremi unuttum',
          style: TextStyle(color: AppColors.primary, fontSize: 14)),
      ),
      const SizedBox(width: 48),
    ]),
  );

  Widget _formView() => Form(
    key: _formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      // İkon
      Center(
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20)],
          ),
          child: const Icon(Icons.lock_reset_outlined, color: AppColors.primary, size: 38),
        ),
      ),
      const SizedBox(height: 24),
      const Text('Şifrenizi mi unuttunuz?',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 8),
      const Text(
        'E-posta adresinizi girin. Şifre sıfırlama bağlantısı göndereceğiz.',
        style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
      ),
      const SizedBox(height: 28),

      // E-posta alanı
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('E-posta Adresi',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textGrey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'ornek@email.com',
              hintStyle: TextStyle(color: AppColors.textLight),
              prefixIcon: Icon(Icons.mail_outline, color: AppColors.secondary),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'E-posta adresi zorunludur.';
              if (!_isValidEmail(_sanitize(v.trim()))) return 'Geçerli bir e-posta giriniz.';
              return null;
            },
          ),
        ]),
      ),
      const SizedBox(height: 24),

      // Gönder butonu
      SizedBox(width: double.infinity, child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: _isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.send_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Sıfırlama Bağlantısı Gönder',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
        ),
      )),
      const SizedBox(height: 16),

      // Giriş sayfasına dön
      Center(child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Text('Giriş sayfasına dön',
          style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
      )),
    ]),
  );

  Widget _successView() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(height: 40),
      // Başarı ikonu
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 48),
      ),
      const SizedBox(height: 28),
      const Text('E-posta Gönderildi! 📬',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 12),
      Text(
        '"${_emailCtrl.text}" adresine şifre sıfırlama bağlantısı gönderildi.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.6),
      ),
      const SizedBox(height: 28),

      // Adımlar
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(children: [
          _stepRow('1', 'E-postanızı kontrol edin'),
          const SizedBox(height: 12),
          _stepRow('2', 'Gelen bağlantıya tıklayın'),
          const SizedBox(height: 12),
          _stepRow('3', 'Yeni şifrenizi belirleyin'),
        ]),
      ),
      const SizedBox(height: 20),

      // Bilgi kutusu
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(
            'E-posta gelmezse spam/gereksiz klasörünü kontrol edin. Bağlantı 24 saat geçerlidir.',
            style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.5),
          )),
        ]),
      ),
      const SizedBox(height: 24),

      // Tekrar gönder
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () => setState(() => _emailSent = false),
        icon: const Icon(Icons.refresh, color: AppColors.primary, size: 16),
        label: const Text('Farklı E-posta ile Dene',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.softGreen, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      )),
      const SizedBox(height: 12),

      // Giriş sayfasına dön
      SizedBox(width: double.infinity, child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Giriş Sayfasına Dön',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      )),
    ],
  );

  Widget _stepRow(String number, String text) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
      child: Center(child: Text(number,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
    ),
    const SizedBox(width: 12),
    Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500)),
  ]);
}