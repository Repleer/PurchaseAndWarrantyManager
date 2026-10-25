import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/crashlytics/data/crashlytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/profile_photo_options.dart';

/// Екран керування профілем (ФВ-2): дані Firebase Auth, фото та зміна пароля.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final AuthController controller = context.read<AuthController>();
    final bool saved = await controller.changePassword(
      currentPassword: _oldController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    if (saved) {
      _oldController.clear();
      _newController.clear();
      _confirmController.clear();
    }
    setState(() {
      _feedbackIsError = !saved;
      _feedbackMessage = saved
          ? 'Зміни профілю збережено.'
          : controller.failureMessage ?? 'Не вдалося зберегти зміни.';
    });
  }

  void _hideFeedback(String _) {
    if (_feedbackMessage != null) {
      setState(() => _feedbackMessage = null);
    }
  }

  Future<void> _updatePhoto() async {
    final TextEditingController urlController = TextEditingController(
      text: context.read<AuthController>().currentUser?.photoURL ?? '',
    );
    final GlobalKey<FormState> photoFormKey = GlobalKey<FormState>();
    final String? photoUrl = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Оновити фото профілю'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: photoFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'HTTPS-посилання на фото',
                    ),
                    validator: Validators.httpsUrl,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text('Або оберіть готове зображення:'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final String url in ProfilePhotoOptions.urls)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                urlController.text = url;
                                setDialogState(() {});
                              },
                              child: ClipOval(
                                child: Image.network(
                                  url,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (urlController.text.startsWith('https://')) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: ClipOval(
                        child: Image.network(
                          urlController.text,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const SizedBox(
                                  width: 84,
                                  height: 84,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                          errorBuilder: (_, _, _) => const SizedBox(
                            width: 84,
                            height: 84,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () {
                if (photoFormKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(urlController.text.trim());
                }
              },
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
    urlController.dispose();
    if (photoUrl == null || !mounted) return;

    final AuthController controller = context.read<AuthController>();
    final bool saved = await controller.updatePhotoUrl(photoUrl);
    if (!mounted) return;
    setState(() {
      _feedbackIsError = !saved;
      _feedbackMessage = saved
          ? 'Зміни профілю збережено.'
          : controller.failureMessage ?? 'Не вдалося оновити фото.';
    });
  }

  Future<void> _linkGoogle() async {
    final AuthController controller = context.read<AuthController>();
    final bool linked = await controller.linkGoogleToCurrentAccount();
    if (!mounted) return;
    setState(() {
      _feedbackIsError = !linked;
      _feedbackMessage = linked
          ? 'Спосіб входу Google підключено.'
          : controller.failureMessage ?? 'Не вдалося підключити Google.';
    });
  }

  Future<void> _generateTestCrash() async {
    final CrashlyticsService crashService = context.read<CrashlyticsService>();
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Тестова помилка'),
            content: Text(
              crashService.usesFirebaseCrashlytics
                  ? 'Застосунок аварійно завершиться. Звіт з’явиться після '
                      'повторного запуску. Продовжити?'
                  : 'Тестову помилку буде надіслано до Sentry без завершення '
                      'застосунку. Продовжити?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Скасувати'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Згенерувати'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted) {
      crashService.generateTestCrash();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = context.watch<AuthController>();
    final User? user = controller.currentUser;
    return AppShell.main(
      selectedIndex: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 360, child: _buildProfileCard(user)),
            const SizedBox(width: 24),
            Expanded(child: _buildPasswordCard(controller.isLoading)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(User? user) {
    final String displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Користувач';
    final String providers =
        user?.providerData
            .map(
              (provider) => provider.providerId == 'password'
                  ? 'Email і пароль'
                  : provider.providerId == 'google.com'
                  ? 'Google'
                  : provider.providerId,
            )
            .join(', ') ??
        '—';
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ProfileAvatar(
              initials: _initials(displayName),
              image: user?.photoURL == null
                  ? null
                  : NetworkImage(user!.photoURL!),
            ),
            const SizedBox(height: 24),
            Text(displayName, style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'Email не вказано',
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            _profileDetail('ID', user?.uid ?? '—'),
            _profileDetail(
              'Реєстрація',
              user?.metadata.creationTime
                      ?.toLocal()
                      .toString()
                      .split(' ')
                      .first ??
                  '—',
            ),
            _profileDetail('Спосіб входу', providers),
            const SizedBox(height: 24),
            AppButton(
              label: 'Оновити фото',
              icon: Icons.add_photo_alternate_outlined,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: context.watch<AuthController>().isLoading
                  ? null
                  : _updatePhoto,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Підключити Google',
              icon: Icons.link,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: context.watch<AuthController>().isLoading
                  ? null
                  : _linkGoogle,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Згенерувати тестову помилку',
              icon: Icons.bug_report_outlined,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: _generateTestCrash,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(bool isLoading) {
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Змінити пароль', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              const Text(
                'Підтвердьте поточний пароль і введіть новий.',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: 22),
              AppTextField(
                label: 'Старий пароль',
                controller: _oldController,
                icon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.requiredField(value, 'Введіть старий пароль.'),
                onChanged: _hideFeedback,
              ),
              const SizedBox(height: 15),
              AppTextField(
                label: 'Новий пароль',
                controller: _newController,
                icon: Icons.vpn_key_outlined,
                helperText: 'Щонайменше 8 символів, літера й цифра.',
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    Validators.newPassword(value, _oldController.text),
                onChanged: _hideFeedback,
              ),
              const SizedBox(height: 15),
              AppTextField(
                label: 'Підтвердження нового пароля',
                controller: _confirmController,
                icon: Icons.vpn_key_outlined,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    Validators.confirmation(value, _newController.text),
                onChanged: _hideFeedback,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _feedbackMessage == null
                        ? const SizedBox.shrink()
                        : FeedbackBanner(
                            message: _feedbackMessage!,
                            isError: _feedbackIsError,
                          ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Зберегти',
                    icon: Icons.check,
                    leading: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onPressed: isLoading ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text('$label:', style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
