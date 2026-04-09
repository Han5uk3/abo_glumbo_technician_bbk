import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/services/technician_location_update_service.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
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
  late AnimationController _iconsController;
  late AnimationController _pulseController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<double> _iconsAnimation;
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

    _iconsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    _iconsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconsController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (!_hasInitialized) {
      _hasInitialized = true;
      _isUserLogout = LocalStore.getLogoutStatus();
      _startAnimationSequence();
      _initializeApp();
    }
  }

  void _startAnimationSequence() async {
    _pulseController.repeat(reverse: true);

    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) _taglineController.forward();
  }

  void _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));

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
    await Future.wait([
      _logoController.reverse(),
      _taglineController.reverse(),
      _iconsController.reverse(),
    ]);

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
    _iconsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildServiceIcon(
    IconData icon,
    double posX,
    double posY,
    Duration delay,
  ) {
    return Positioned(
      left: posX,
      top: posY,
      child: Icon(icon, color: Colors.white.withOpacity(0.2), size: 28),
    );
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
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0A2A5E), Color(0xFF1E5AB6)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -150,
                      left: -150,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                    Positioned(
                      top: screenHeight * 0.3,
                      right: -80,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildServiceIcon(
                Icons.build,
                50,
                120,
                const Duration(milliseconds: 0),
              ),
              _buildServiceIcon(
                Icons.handyman,
                screenWidth - 90,
                100,
                const Duration(milliseconds: 500),
              ),
              _buildServiceIcon(
                Icons.lightbulb_outline,
                screenWidth - 100,
                screenHeight * 0.4,
                const Duration(milliseconds: 1000),
              ),
              _buildServiceIcon(
                Icons.water_drop_outlined,
                40,
                screenHeight * 0.6,
                const Duration(milliseconds: 1500),
              ),
              _buildServiceIcon(
                Icons.settings,
                screenWidth - 80,
                screenHeight * 0.72,
                const Duration(milliseconds: 2000),
              ),
              _buildServiceIcon(
                Icons.electrical_services,
                60,
                screenHeight * 0.8,
                const Duration(milliseconds: 2500),
              ),

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
                          child: SizedBox(
                            width: 140,
                            height: 140,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                color: Colors.white,
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: Text(
                        state.locale.languageCode == "ar"
                            ? "ابو جلمبو"
                            : 'Abo Glumbo',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _taglineAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          state.locale.languageCode == "ar"
                              ? "خدمات إصلاح وصيانة سريعة وموثوقة في أي وقت وأي مكان"
                              : 'Repair & Maintenance, Anytime – Anywhere',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.8,
                            height: 1.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
