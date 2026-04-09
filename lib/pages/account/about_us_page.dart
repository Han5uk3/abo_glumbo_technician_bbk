import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              locale.aboutUsTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FadeSlide(
                  delay: 0,
                  child: Text(
                    locale.aboutUsHeadline,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 100,
                  child: Text(
                    locale.aboutUsIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),

                _FadeSlide(
                  delay: 200,
                  child: _SectionTitle(title: locale.aboutRewardsTitle),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 300,
                  child: _InfoCard(
                    title: locale.aboutIncentiveTitle,
                    description: locale.aboutIncentiveDesc,
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 400,
                  child: _InfoCard(
                    title: locale.aboutEarningsTitle,
                    description: locale.aboutEarningsDesc,
                  ),
                ),
                const SizedBox(height: 24),

                _FadeSlide(
                  delay: 500,
                  child: _SectionTitle(title: locale.aboutSupportTitle),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 600,
                  child: _InfoCard(
                    title: locale.aboutFlexibilityTitle,
                    description: locale.aboutFlexibilityDesc,
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 700,
                  child: _InfoCard(
                    title: locale.aboutNoHuntingTitle,
                    description: locale.aboutNoHuntingDesc,
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 800,
                  child: _InfoCard(
                    title: locale.aboutTransparencyTitle,
                    description: locale.aboutTransparencyDesc,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String description;

  const _InfoCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;

  const _FadeSlide({required this.child, required this.delay});

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
