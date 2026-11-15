import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/crashlytics/data/crashlytics_service.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/application/profile_controller.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/data/profile_photo_options.dart';
import 'package:warranty_and_purchase_manager/core/features/profile/domain/user_profile.dart';

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
    setState(() => _feedbackMessage = null);
    context.read<ProfileController>().clearFeedback();
    await showDialog<void>(
      context: context,
      builder: (_) => _PhotoUrlDialog(
        initialUrl: context.read<ProfileController>().profile?.photoUrl ?? '',
      ),
    );
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
    return AppShell.main(
      selectedIndex: 3,
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
          child: Column(
            children: [
              SizedBox(
                height: viewport.maxHeight - 76 < 740
                    ? 740
                    : viewport.maxHeight - 76,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 340,
                      child: Consumer<ProfileController>(
                        builder: (context, controller, _) {
                          final bool authLoading = context
                              .select<AuthController, bool>(
                                (auth) => auth.isLoading,
                              );
                          return _buildProfileCard(
                            controller.profile,
                            controller.isOffline,
                            controller.isSaving || authLoading,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Builder(
                        builder: (context) => _buildPasswordCard(
                          context.select<AuthController, bool>(
                            (controller) => controller.isLoading,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) => _buildExtras(
                  context.select<ProfileController, UserProfile?>(
                    (controller) => controller.profile,
                  ),
                  context.select<AuthController, bool>(
                    (controller) => controller.isLoading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile? user, bool isOffline, bool isLoading) {
    final String displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Користувач';
    return AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          ProfileAvatar(
            initials: _initials(displayName),
            image: user?.photoUrl == null
                ? null
                : NetworkImage(user!.photoUrl!),
          ),
          const SizedBox(height: 16),
          Text(
            user?.email ?? 'Email не вказано',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          if (isOffline) ...[
            const SizedBox(height: 6),
            const Text('Показано збережені дані', style: AppTextStyles.caption),
          ],
          const SizedBox(height: 6),
          const Text(
            'JPG або PNG для нового фото профілю.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 22),
          AppButton(
            label: 'Оновити фото',
            icon: Icons.add_photo_alternate_outlined,
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: isLoading ? null : _updatePhoto,
          ),
        ],
      ),
    );
  }

  Widget _buildExtras(UserProfile? user, bool isLoading) {
    final String providers =
        user?.providers
            .map(
              (provider) => provider == 'password'
                  ? 'Email і пароль'
                  : provider == 'google.com'
                  ? 'Google'
                  : provider,
            )
            .join(', ') ??
        '—';
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Додаткові дані акаунта',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 10),
                _profileDetail('ID', user?.uid ?? '—'),
                _profileDetail(
                  'Реєстрація',
                  user?.createdAt?.toLocal().toString().split(' ').first ?? '—',
                ),
                _profileDetail('Спосіб входу', providers),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: 'Підключити Google',
                  icon: Icons.link,
                  variant: AppButtonVariant.secondary,
                  expanded: true,
                  onPressed: isLoading ? null : _linkGoogle,
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
        ],
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
                helperText: 'Щонайменше 8 символів.',
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
              Builder(
                builder: (context) {
                  final String? photoSuccess = context
                      .select<ProfileController, String?>(
                        (controller) => controller.successMessage,
                      );
                  final String? photoError = context
                      .select<ProfileController, String?>(
                        (controller) => controller.errorMessage,
                      );
                  final String? message =
                      _feedbackMessage ?? photoError ?? photoSuccess;
                  final bool isError = _feedbackMessage != null
                      ? _feedbackIsError
                      : photoError != null;
                  return Row(
                    children: [
                      Expanded(
                        child: message == null
                            ? const SizedBox.shrink()
                            : FeedbackBanner(
                                message: message,
                                isError: isError,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onPressed: isLoading ? null : _save,
                      ),
                    ],
                  );
                },
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

class _PhotoUrlDialog extends StatefulWidget {
  const _PhotoUrlDialog({required this.initialUrl});

  final String initialUrl;

  @override
  State<_PhotoUrlDialog> createState() => _PhotoUrlDialogState();
}

class _PhotoUrlDialogState extends State<_PhotoUrlDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _savePhoto() async {
    if (!_formKey.currentState!.validate()) return;
    final ProfileController controller = context.read<ProfileController>();
    final bool saved = await controller.updatePhoto(_urlController.text.trim());
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(
        () => _errorMessage =
            controller.errorMessage ?? 'Не вдалося оновити фото.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Оновити фото профілю'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'HTTPS-посилання на фото',
                ),
                validator: Validators.httpsUrl,
                onChanged: (_) => setState(() {}),
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
                            _urlController.text = url;
                            setState(() {});
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
              if (_urlController.text.startsWith('https://')) ...[
                const SizedBox(height: 16),
                Center(
                  child: ClipOval(
                    child: Image.network(
                      _urlController.text,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const SizedBox(
                              width: 84,
                              height: 84,
                              child: Center(child: CircularProgressIndicator()),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                FeedbackBanner(message: _errorMessage!, isError: true),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Скасувати'),
        ),
        Builder(
          builder: (context) {
            final bool isSaving = context.select<ProfileController, bool>(
              (controller) => controller.isSaving,
            );
            return FilledButton(
              onPressed: isSaving ? null : _savePhoto,
              child: isSaving
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Зберегти'),
                      ],
                    )
                  : const Text('Зберегти'),
            );
          },
        ),
      ],
    );
  }
}
