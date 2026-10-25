import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Круглий аватар: фото користувача або ініціали, якщо фото ще немає.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.size = 144,
    this.image,
  });

  final String initials;
  final double size;

  /// Фото профілю. Поки його немає (без бекенду) — показуються ініціали.
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
      ),
      child: image == null
          ? _buildInitials()
          : ClipOval(
              child: Image(
                image: image!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildInitials(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _buildInitials(),
              ),
            ),
    );
  }

  Widget _buildInitials() {
    return Text(
      initials,
      style: TextStyle(
        fontSize: size * 0.3,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}
