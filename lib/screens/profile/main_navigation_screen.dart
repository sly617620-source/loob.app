import 'package:flutter/material.dart';
import 'package:loob/theme/app_colors.dart';
import 'package:loob/models/user_model.dart';
import 'package:loob/screens/market/discover_screen.dart';
import 'package:loob/screens/market/my_purchases_screen.dart';
import 'package:loob/screens/chat/chat_list_screen.dart';
import 'package:loob/screens/seller/seller_dashboard_screen.dart';
import 'package:loob/screens/campaigns/campaigns_screen.dart';
import 'package:loob/screens/campaigns/campaign_dashboard_screen.dart';
import 'package:loob/screens/campaigns/my_submissions_screen.dart';
import 'package:loob/screens/profile/profile_screen.dart';
import 'package:loob/providers/app_provider.dart';
import 'package:loob/widgets/custom_floating_nav_bar.dart';

class _NavTab {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavTab({required this.icon, required this.label, required this.screen});
}

/// Bottom navigation whose tab set changes with the signed-in user's
/// [UserRole] - each account type only sees the screens relevant to it:
/// - campaignCreator: campaign dashboard (manage + review submissions)
/// - seller: seller dashboard (products/orders/analytics)
/// - contentCreator: campaigns feed + my submissions
/// - customer / admin: plain marketplace browsing
///
/// "اكتشف" (marketplace) and "الرسائل" (chat) stay available to everyone
/// so buying/selling and messaging always work regardless of role.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  UserRole? _builtForRole;

  List<_NavTab> _tabsForRole(UserRole role) {
    switch (role) {
      case UserRole.campaignCreator:
        return const [
          _NavTab(icon: Icons.campaign_outlined, label: 'حملاتي', screen: CampaignDashboardScreen()),
          _NavTab(icon: Icons.explore_outlined, label: 'اكتشف', screen: DiscoverScreen()),
          _NavTab(icon: Icons.chat_bubble_outline, label: 'الرسائل', screen: ChatListScreen()),
          _NavTab(icon: Icons.person_outline, label: 'حسابي', screen: ProfileScreen()),
        ];
      case UserRole.seller:
        return const [
          _NavTab(icon: Icons.explore_outlined, label: 'استكشف', screen: DiscoverScreen()),
          _NavTab(icon: Icons.chat_bubble_outline, label: 'الرسائل', screen: ChatListScreen()),
          _NavTab(icon: Icons.storefront_outlined, label: 'متجري', screen: SellerDashboardScreen()),
          _NavTab(icon: Icons.shopping_bag_outlined, label: 'مشترياتي', screen: MyPurchasesScreen()),
          _NavTab(icon: Icons.person_outline, label: 'حسابي', screen: ProfileScreen()),
        ];
      case UserRole.contentCreator:
        return const [
          _NavTab(icon: Icons.campaign_outlined, label: 'الحملات', screen: CampaignsScreen()),
          _NavTab(icon: Icons.send_outlined, label: 'تقديماتي', screen: MySubmissionsScreen()),
          _NavTab(icon: Icons.chat_bubble_outline, label: 'الرسائل', screen: ChatListScreen()),
          _NavTab(icon: Icons.explore_outlined, label: 'اكتشف', screen: DiscoverScreen()),
          _NavTab(icon: Icons.person_outline, label: 'حسابي', screen: ProfileScreen()),
        ];
      case UserRole.customer:
      case UserRole.admin:
        return const [
          _NavTab(icon: Icons.explore_outlined, label: 'استكشف', screen: DiscoverScreen()),
          _NavTab(icon: Icons.chat_bubble_outline, label: 'الرسائل', screen: ChatListScreen()),
          _NavTab(icon: Icons.shopping_bag_outlined, label: 'مشترياتي', screen: MyPurchasesScreen()),
          _NavTab(icon: Icons.person_outline, label: 'حسابي', screen: ProfileScreen()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final role = controller.user?.role ?? UserRole.customer;

    // If the role changes mid-session (e.g. the user switches account type
    // from Settings) the tab set is different, so reset to the first tab
    // instead of pointing at an index that no longer matches the same
    // screen.
    if (_builtForRole != role) {
      _builtForRole = role;
      _currentIndex = 0;
    }

    final tabs = _tabsForRole(role);
    final safeIndex = _currentIndex < tabs.length ? _currentIndex : 0;

    return Scaffold(
      // The floating pill nav sits *over* the content instead of pushing
      // it up, so the body extends underneath it - see extendBody below.
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: CustomFloatingNavBar(
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        // Dark/gold styling so the floating bar matches this app's Black &
        // Gold identity instead of the widget's default white/pink look.
        barColor: AppColors.card,
        accentColor: AppColors.accent,
        accentIconColor: Colors.black,
        inactiveColor: AppColors.textMuted,
        items: tabs
            .map((t) => NavBarItem(icon: t.icon, label: t.label))
            .toList(),
      ),
    );
  }
}
