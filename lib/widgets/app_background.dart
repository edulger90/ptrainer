import 'package:flutter/material.dart';

/// Uygulamanın tüm sayfalarında kullanılan saydam arka plan widget'ı.
/// Performans: Resmi cacheWidth ile ölçeklendirir ve gaplessPlayback ile
/// rebuild sırasında titreme önler.
class AppBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const AppBackground({super.key, required this.child, this.opacity = 0.15});

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğinin piksel cinsinden değeri – resmi bundan büyük
    // decode etmeye gerek yok, bellek kullanımını düşürür.
    final screenWidth = MediaQuery.of(context).size.width;
    final cacheW = (screenWidth * MediaQuery.of(context).devicePixelRatio)
        .toInt();

    return Stack(
      children: [
        // Arka plan görseli - Pilates/Fitness
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
              cacheWidth: cacheW,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey[200]);
              },
            ),
          ),
        ),
        // İçerik
        child,
      ],
    );
  }
}
