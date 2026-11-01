// ============================================================
// lib/presentation/screens/profile/edit_profile_screen.dart
// ============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../auth/forgot_password_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Melis Yalçınkaya');
  final _emailCtrl = TextEditingController(text: 'melis@email.com');
  final _bioCtrl = TextEditingController(text: '');
  File? _selectedImage;
  bool _isLoading = false;

  static const int _maxNameLength = 60;
  static const int _maxBioLength = 150;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML tag temizle
        .replaceAll(RegExp('[<>"\']'), '') // tehlikeli karakterler
        .trim();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  Future<void> _pickImage() async {
    // Gerçek uygulamada image_picker:
    // final picker = ImagePicker();
    // final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    // if (picked != null) {
    //   final file = File(picked.path);
    //   final bytes = await file.length();
    //   if (bytes > 5 * 1024 * 1024) { _showError('Max 5MB'); return; }
    //   final ext = file.path.split('.').last.toLowerCase();
    //   if (!['jpg','jpeg','png'].contains(ext)) { _showError('Sadece JPG/PNG'); return; }
    //   setState(() => _selectedImage = file);
    // }
    _showInfo('Fotoğraf seçici — image_picker paketi kullanılacak.');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Gerçek uygulamada Firebase:
      // final user = FirebaseAuth.instance.currentUser!;
      // await user.updateDisplayName(_sanitize(_nameCtrl.text));
      // if (_emailCtrl.text != user.email) {
      //   await user.verifyBeforeUpdateEmail(_sanitize(_emailCtrl.text));
      // }
      // await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      //   'name': _sanitize(_nameCtrl.text),
      //   'bio': _sanitize(_bioCtrl.text),
      //   'updatedAt': FieldValue.serverTimestamp(),
      // });

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _showSuccess('Profil güncellendi');
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Güncelleme sırasında hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ));

  void _showSuccess(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(msg),
        ]),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ));

  void _showInfo(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _avatarSection(),
                  const SizedBox(height: 16),
                  _infoCard(),
                  const SizedBox(height: 12),
                  _securityCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            _buildBottomBar(),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          ),
          const Expanded(
              child: Text('Profil Düzenle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark))),
          const SizedBox(width: 48),
        ]),
      );

  Widget _avatarSection() => Center(
        child: Stack(children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.3), blurRadius: 16)
              ],
            ),
            child: _selectedImage != null
                ? ClipOval(
                    child: Image.file(_selectedImage!, fit: BoxFit.cover))
                : const Center(
                    child: Text('M',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600))),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ),
          ),
        ]),
      );

  Widget _infoCard() => _card(
        title: 'Kişisel Bilgiler',
        icon: Icons.person_outline,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fieldLabel('Ad Soyad *'),
          TextFormField(
            controller: _nameCtrl,
            maxLength: _maxNameLength,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(_maxNameLength)],
            decoration: _inputDec('Ad Soyad', Icons.person_outline),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ad soyad zorunludur.';
              if (v.trim().length < 3) return 'En az 3 karakter giriniz.';
              if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(v.trim())) {
                return 'Sadece harf ve boşluk kullanınız.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _fieldLabel('E-posta *'),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            decoration: _inputDec('ornek@email.com', Icons.mail_outline),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'E-posta zorunludur.';
              if (!_isValidEmail(v.trim()))
                return 'Geçerli bir e-posta giriniz.';
              return null;
            },
          ),
          const SizedBox(height: 4),
          const Text(
            '* E-posta değişikliğinde doğrulama maili gönderilir.',
            style: TextStyle(fontSize: 10, color: AppColors.textGrey),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Hakkımda (Opsiyonel)'),
          TextFormField(
            controller: _bioCtrl,
            maxLength: _maxBioLength,
            maxLines: 3,
            inputFormatters: [LengthLimitingTextInputFormatter(_maxBioLength)],
            decoration: InputDecoration(
              hintText: 'Kendinizden kısaca bahsedin...',
              hintStyle:
                  const TextStyle(color: AppColors.textLight, fontSize: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.softGreen, width: 2)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.softGreen, width: 2)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2)),
              filled: true,
              fillColor: AppColors.cream,
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                final s = _sanitize(v);
                if (s.isEmpty) return 'Geçersiz karakter içeriyor.';
              }
              return null;
            },
          ),
        ]),
      );

  Widget _securityCard() => _card(
        title: 'Güvenlik',
        icon: Icons.shield_outlined,
        child: Column(children: [
          _securityTile(
            icon: Icons.lock_outline,
            title: 'Şifre Değiştir',
            subtitle: 'Son değişiklik: 3 ay önce',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen())),
          ),
          const Divider(height: 1, color: AppColors.softGreen),
          _securityTile(
            icon: Icons.delete_outline,
            title: 'Hesabı Sil',
            subtitle: 'Bu işlem geri alınamaz',
            isDestructive: true,
            onTap: _showDeleteAccountDialog,
          ),
        ]),
      );

  Widget _securityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) =>
      ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isDestructive ? const Color(0xFFFFEEE8) : AppColors.lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18,
              color: isDestructive ? AppColors.accent : AppColors.primary),
        ),
        title: Text(title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDestructive ? AppColors.accent : AppColors.textDark,
            )),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        trailing: Icon(Icons.chevron_right,
            color: isDestructive ? AppColors.accent : AppColors.textLight,
            size: 18),
      );

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hesabı Sil',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.accent)),
        content: const Text(
            'Hesabınızı silmek istediğinizden emin misiniz?\n\nTüm verileriniz (rutinler, ürünler, yorumlar) kalıcı olarak silinecektir. Bu işlem geri alınamaz.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textGrey, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal',
                  style: TextStyle(color: AppColors.textGrey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Gerçek uygulamada: FirebaseAuth.instance.currentUser?.delete()
            },
            child: const Text('Hesabı Sil',
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(children: [
          Expanded(
              child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.softGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('İptal',
                style: TextStyle(
                    color: AppColors.textDark, fontWeight: FontWeight.w500)),
          )),
          const SizedBox(width: 12),
          Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                              Icon(Icons.check, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Kaydet',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ]),
                ),
              )),
        ]),
      );

  Widget _card(
          {required String title,
          required IconData icon,
          required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 17),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.softGreen),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _fieldLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey)),
      );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
        counterText: '',
      );
}
