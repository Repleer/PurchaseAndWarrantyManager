import 'package:flutter/material.dart';
import 'package:warranty_manager/core/theme/app_colors.dart';

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
        image: image == null
            ? null
            : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      child: image == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.3,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}
