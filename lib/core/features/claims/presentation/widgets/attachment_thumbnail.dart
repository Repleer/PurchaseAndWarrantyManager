import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

import '../../domain/claim.dart';

/// Сіра мініатюра фото або відео дефекту без локального медіафайлу.
class AttachmentThumbnail extends StatelessWidget {
  const AttachmentThumbnail({
    super.key,
    required this.attachment,
    this.width = 200,
  });

  final ClaimAttachment attachment;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 118,
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: attachment.kind == AttachmentKind.video
                ? Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textSecondary,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  )
                : const Icon(
                    Icons.image_outlined,
                    size: 38,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 5),
        Text(attachment.subtitle, style: AppTextStyles.caption),
      ],
    ),
  );
}
