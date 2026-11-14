import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder = placeholder ??
        Container(
          width: width,
          height: height,
          color: AppTheme.surfaceContainerLow,
          child: const Center(
            child: Icon(Icons.fastfood, color: AppTheme.outline),
          ),
        );

    final defaultError = errorWidget ?? defaultPlaceholder;

    if (imageUrl.isEmpty) {
      return defaultError;
    }

    // Jika gambar berupa data Base64 (hasil dari Choose File / Galeri)
    if (imageUrl.startsWith('data:image') || imageUrl.startsWith('data:;base64,')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => defaultError,
        );
      } catch (_) {
        return defaultError;
      }
    }

    // Di platform Web (Chrome), CachedNetworkImage sering terhalang CORS browser
    // saat mencoba mengunduh byte gambar via XMLHttpRequest.
    // Image.network menggunakan tag <img> browser native yang kebal CORS.
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return defaultPlaceholder;
        },
        errorBuilder: (context, error, stackTrace) {
          return defaultError;
        },
      );
    }

    // Di Android / iOS / Desktop, gunakan CachedNetworkImage untuk performa caching optimal
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => defaultPlaceholder,
      errorWidget: (_, __, ___) => defaultError,
    );
  }
}
