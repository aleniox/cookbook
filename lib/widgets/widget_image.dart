import 'package:flutter/material.dart';

Widget loadImage(String path, {double? height, BoxFit fit = BoxFit.cover}) {
  // Kiểm tra xem đường dẫn có phải là link mạng (bắt đầu bằng 'http' hoặc 'https') không
  if (path.startsWith('http')) {
    return Image.network(
      path,
      height: height,
      fit: fit,
      // Thêm loadingBuilder và errorBuilder như code cũ nếu muốn
    );
  } else {
    // Nếu không, giả định đó là ảnh assets
    return Image.asset(
      path,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const SizedBox(
        height: 180.0,
        child: Center(child: Icon(Icons.broken_image, size: 50)),
      ),
    );
  }
}