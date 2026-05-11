import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import 'library_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    await context.read<LibraryProvider>().loadBooks();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LibraryScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violet.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate().scale(
                  duration: 1200.ms, curve: Curves.easeOut, begin: const Offset(0.5, 0.5)),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.coral.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate().scale(
                  duration: 1200.ms,
                  delay: 200.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(0.5, 0.5)),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [AppColors.violet, AppColors.violetDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet.withOpacity(0.5),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 60),
                  )
                      .animate()
                      .scale(
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.3, 0.3))
                      .fade(duration: 400.ms),

                  const SizedBox(height: 28),

                  // App name
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.violetLight, AppColors.gold],
                    ).createShader(bounds),
                    child: const Text(
                      'BookShelf',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                      .animate()
                      .slideY(
                          begin: 0.4,
                          duration: 600.ms,
                          delay: 300.ms,
                          curve: Curves.easeOutCubic)
                      .fade(delay: 300.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Your personal reading universe',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ).animate().fade(delay: 600.ms, duration: 500.ms),

                  const SizedBox(height: 64),

                  // Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.violet.withOpacity(0.8),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .scaleXY(
                            begin: 0.5,
                            end: 1.2,
                            duration: 600.ms,
                            delay: Duration(milliseconds: 800 + i * 150),
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scaleXY(
                            begin: 1.2,
                            end: 0.5,
                            duration: 600.ms,
                          );
                    }),
                  ).animate().fade(delay: 900.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
