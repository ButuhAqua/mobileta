import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:apps_break/features/auth/presentation/pages/login.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  Timer? _timer;

  late final AnimationController _pulseCtrl;     // untuk ikon kopi (scale + rotasi halus)
  late final AnimationController _shimmerCtrl;   // untuk shimmer teks
  late final AnimationController _dotsCtrl;      // untuk tiga titik
  late final AnimationController _barCtrl;       // untuk progress bar

  @override
  void initState() {
    super.initState();

    // Splash/loading 2 detik lalu pindah ke LoginPage
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });

    // Ikon kopi: denyut + rotasi kecil
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Shimmer brand text (loop)
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Tiga titik loading (loop)
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Progress bar sampai 100%
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _dotsCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeRed = const Color(0xFFD32F2F); // senada dengan kPrimary milikmu
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ====== Background gradient ======
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFEBEE), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // ====== Accent circles (soft) ======
          Positioned(
            top: -60, left: -40,
            child: _softCircle(const Color(0x22D32F2F), 200),
          ),
          Positioned(
            bottom: -50, right: -30,
            child: _softCircle(const Color(0x331E88E5), 160),
          ),

          // ====== Content ======
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ikon kopi animasi
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) {
                        final scale = 1.0 + (0.06 * math.sin(_pulseCtrl.value * math.pi));
                        final rotate = (math.pi / 180) * (3 * math.sin(_pulseCtrl.value * 2 * math.pi));
                        return Transform.rotate(
                          angle: rotate,
                          child: Transform.scale(
                            scale: scale,
                            child: const Icon(Icons.coffee, size: 96, color: Colors.brown),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // Brand shimmer text
                    _AnimatedShimmerText(
                      controller: _shimmerCtrl,
                      text: 'break.co',
                      baseStyle: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                      ),
                      colors: [
                        themeRed,
                        themeRed.withOpacity(.6),
                        themeRed,
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Progress bar halus
                    _AnimatedProgressBar(controller: _barCtrl, color: themeRed),

                    const SizedBox(height: 14),

                    // Loading... + bouncing dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Loading',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _BouncingDots(controller: _dotsCtrl, color: themeRed),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== helper widget: soft blur-like circle =====
  Widget _softCircle(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 50,
            spreadRadius: 10,
          )
        ],
      ),
    );
  }
}

/// Shimmer text tanpa package eksternal
class _AnimatedShimmerText extends StatelessWidget {
  const _AnimatedShimmerText({
    required this.controller,
    required this.text,
    required this.baseStyle,
    required this.colors,
  });

  final AnimationController controller;
  final String text;
  final TextStyle baseStyle;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value; // 0..1
        // geser gradien bolak-balik agar terlihat menyapu
        final begin = Alignment(-2 + (4 * t), 0);
        final end = Alignment(2 + (4 * t), 0);
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: begin,
              end: end,
              colors: colors,
              stops: const [0.2, 0.5, 0.8],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(text, style: baseStyle),
        );
      },
    );
  }
}

/// Progress bar custom yang mengisi dari kiri ke kanan
class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, c) {
          return AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final w = c.maxWidth * Curves.easeOut.transform(controller.value.clamp(0, 1));
              return Container(
                width: c.maxWidth,
                decoration: BoxDecoration(
                  color: const Color(0x11000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: w,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(.7)],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Tiga titik bouncing untuk efek "Loading..."
class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const dotSize = 6.0;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        // value 0..1 → transform ke tiga fase
        double y(int i) {
          // offset fase masing-masing titik
          final phase = (controller.value + (i * 0.2)) % 1.0;
          // gerak naik-turun sinus
          return -3 * math.sin(phase * 2 * math.pi);
        }

        Widget dot(int i) => Transform.translate(
              offset: Offset(0, y(i)),
              child: Container(
                width: dotSize,
                height: dotSize,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(dotSize),
                ),
              ),
            );

        return Row(
          children: [dot(0), dot(1), dot(2)],
        );
      },
    );
  }
}
