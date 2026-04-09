import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/services/technician_location_update_service.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _hasInitialized = false;
  bool _isUserLogout = false;

  late AnimationController _logoController;
  late AnimationController _taglineController;
  late AnimationController _pulseController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _taglineController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _taglineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (!_hasInitialized) {
      _hasInitialized = true;
      _isUserLogout = LocalStore.getLogoutStatus();
      _startAnimationSequence();
    }
  }

  void _startAnimationSequence() async {
    _pulseController.repeat(reverse: true);

    // 1. Wait for Logo animation
    await _logoController.forward();

    // 2. Wait for Tagline animation
    if (mounted) {
      await _taglineController.forward();
    }

    // 3. Wait 1 second AFTER all animations are done
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      _initializeApp();
    }
  }

  void _initializeApp() async {
    if (mounted) {
      if (LocalStore.getUID() != null && !_isUserLogout) {
        context.read<LoginBloc>().add(LoadWorkerData(uid: LocalStore.getUID()));
        final loginBloc = context.read<LoginBloc>();
        await for (final state in loginBloc.stream) {
          if (state is LoginSuccess || state is LoginLoadWorkerData) {
            TechnicianLocationUpdateService.updateLocationNow();
            _navigateWithFadeOut(() => const Home());
            break;
          } else if (state is LoginLoadWorkerDataFailure) {
            _navigateWithFadeOut(() => LoginPage());
            break;
          }
        }
      } else {
        _navigateWithFadeOut(() => LoginPage());
      }
    }
  }

  void _navigateWithFadeOut(Widget Function() pageBuilder) async {
    if (mounted) {
      await Future.wait([
        _logoController.reverse(),
        _taglineController.reverse(),
      ]);
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              pageBuilder(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // 1. Solid Background
              Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.primary,
              ),

              // 2. Large Shape at Bottom (Rectangle + Triangle Top)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(screenWidth, screenHeight * 0.35),
                  painter: BottomShapePainter(
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),

              // 3. Central Content (Logo & Text)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _logoController,
                        _pulseController,
                      ]),
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    color: Colors.white,
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                // Text
                                Text(
                                  state.locale.languageCode == "ar"
                                      ? "ابو جلمبو"
                                      : "Abo Glumbo",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BottomShapePainter extends CustomPainter {
  final Color color;
  BottomShapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    // Draws a pentagon shape (rectangle with a triangle on top)
    path.moveTo(0, size.height); // bottom left
    path.lineTo(0, size.height * 0.6); // top of rectangle part
    path.lineTo(size.width / 2, 0); // peak of triangle
    path.lineTo(size.width, size.height * 0.6); // top of rectangle right
    path.lineTo(size.width, size.height); // bottom right
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

