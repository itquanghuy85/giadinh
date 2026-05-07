import 'package:family_finance/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingKey = 'hasSeenOnboarding';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Quản lý chi tiêu gia đình',
      desc: 'Theo dõi thu chi, quản lý nhiều ví tiền dễ dàng cho cả gia đình.',
    ),
    _OnboardingSlide(
      icon: Icons.calendar_month_rounded,
      title: 'Theo dõi lịch và sự kiện',
      desc: 'Lên kế hoạch sự kiện, nhắc nhở kỷ niệm quan trọng trong gia đình.',
    ),
    _OnboardingSlide(
      icon: Icons.family_restroom_rounded,
      title: 'Chia sẻ với cả nhà',
      desc: 'Quản lý quỹ chung, theo dõi công nợ và đồng bộ dữ liệu với tất cả thành viên.',
    ),
  ];

  Future<void> _done() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    widget.onDone();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  if (_page < _slides.length - 1) ...[
                    TextButton(
                      onPressed: _done,
                      child: const Text('Bỏ qua', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      child: const Text('Tiếp theo', style: TextStyle(color: Colors.white)),
                    ),
                  ] else ...[
                    const Spacer(),
                    SizedBox(
                      width: double.infinity / 2,
                      child: FilledButton(
                        onPressed: _done,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                        ),
                        child: const Text('Bắt đầu ngay!', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const Spacer(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({required this.icon, required this.title, required this.desc});
  final IconData icon;
  final String title;
  final String desc;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}
