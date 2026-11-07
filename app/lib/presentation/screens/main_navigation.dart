import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'collections/collections_screen.dart';
import 'products/products_screen.dart';
import 'profile/profile_screen.dart';
import 'routine/routine_home_screen.dart';

enum MainTab {
  products('urunler', 'Ürünler', Icons.shopping_bag_outlined),
  collections('koleksiyon', 'Koleksiyon', Icons.bookmarks_outlined),
  routine('rutin', 'Rutin', Icons.calendar_today_outlined),
  profile('profil', 'Profil', Icons.person_outline);

  const MainTab(this.slug, this.label, this.icon);

  final String slug;
  final String label;
  final IconData icon;

  static MainTab fromSlug(String? slug) =>
      values.firstWhere((t) => t.slug == slug, orElse: () => MainTab.routine);
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialTab = MainTab.routine});

  final MainTab initialTab;

  /// Alt çubuktaki bir sekmeye geçer (ör. Koleksiyon'dan "Ürün ekle").
  static void select(BuildContext context, MainTab tab) =>
      context.findAncestorStateOfType<_MainNavigationState>()?._select(tab);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late MainTab _tab = widget.initialTab;

  static const _screens = [
    ProductsScreen(),
    CollectionsScreen(),
    RoutineHomeScreen(),
    ProfileScreen(),
  ];

  void _select(MainTab tab) => setState(() => _tab = tab);

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Başka bir ekrandan "Koleksiyonuma git" gibi bir bağlantıyla gelinirse.
    if (oldWidget.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab.index, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.softGreen, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (final tab in MainTab.values)
                Expanded(
                  child: Semantics(
                    selected: tab == _tab,
                    button: true,
                    child: InkWell(
                      onTap: () => setState(() => _tab = tab),
                      splashColor: AppColors.lightGreen,
                      highlightColor: AppColors.lightGreen,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tab.icon,
                              size: 21,
                              color: tab == _tab
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tab.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: tab == _tab
                                    ? AppColors.primary
                                    : AppColors.textGrey,
                                fontWeight: tab == _tab
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
