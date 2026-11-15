import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';

/// Картка документа покупки з прев'ю та двома режимами перегляду.
class PurchaseDocumentCard extends StatelessWidget {
  const PurchaseDocumentCard({
    super.key,
    required this.title,
    required this.fileName,
    this.assetPath,
  });

  final String title;
  final String? fileName;
  final String? assetPath;

  void _openPreview(BuildContext context, {required bool zoom}) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 850,
          height: 650,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$title · ${fileName ?? 'Файл не додано'}',
                        style: AppTextStyles.cardTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Закрити',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: zoom
                    ? InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5,
                        child: SizedBox.expand(child: _preview()),
                      )
                    : _preview(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    final Widget fallback = Container(
      color: AppColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(fileName ?? 'Файл не додано', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Попередній перегляд недоступний',
            style: AppTextStyles.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    if (assetPath == null) return fallback;
    return Image.asset(
      assetPath!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 12,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$title · ${fileName ?? 'Файл не додано'}',
                    style: AppTextStyles.bodyStrong,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _previewButton(
                  icon: Icons.zoom_in_outlined,
                  tooltip: 'Збільшити',
                  onPressed: () => _openPreview(context, zoom: true),
                ),
                const SizedBox(width: 4),
                _previewButton(
                  icon: Icons.open_in_full,
                  tooltip: 'Розгорнути',
                  onPressed: () => _openPreview(context, zoom: false),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _preview()),
        ],
      ),
    );
  }

  Widget _previewButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: 17),
    color: AppColors.primary,
    style: IconButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
