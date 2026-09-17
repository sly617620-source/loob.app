import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A single tab in a [CustomFloatingNavBar].
class NavBarItem {
  /// Icon shown when this tab is inactive.
  final IconData icon;

  /// Icon shown when this tab is the active one. Falls back to [icon]
  /// when omitted.
  final IconData? activeIcon;

  /// Accessible label (screen readers / tooltip). Not rendered as visible
  /// text - the floating-pill look is icon-only by design.
  final String label;

  const NavBarItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });
}

/// A floating, pill-shaped bottom navigation bar.
///
/// - A rounded, elevated "pill" surface holds every tab icon in a row.
/// - The *active* tab lifts out of the pill into its own floating
///   circular badge (filled with [accentColor], white icon) that glides
///   smoothly to the newly-selected tab's position using spring physics.
/// - An optional [centerIndex] (e.g. a central "Add" action) is rendered
///   as its own always-floating prominent blob, independent of the
///   selection state - handy for a FAB-like create/add button sitting in
///   the middle of the bar.
///
/// Usage (matches the classic Home / Likes / Add / Profile / Alerts
/// layout):
/// ```dart
/// CustomFloatingNavBar(
///   currentIndex: _index,
///   onTap: (i) => setState(() => _index = i),
///   centerIndex: 2,
///   items: const [
///     NavBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
///     NavBarItem(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Likes'),
///     NavBarItem(icon: Icons.add_rounded, label: 'Add'),
///     NavBarItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
///     NavBarItem(icon: Icons.notifications_none, activeIcon: Icons.notifications, label: 'Alerts'),
///   ],
/// )
/// ```
///
/// Drop this straight into `Scaffold.bottomNavigationBar` - it manages
/// its own safe-area padding.
class CustomFloatingNavBar extends StatefulWidget {
  /// Index of the currently selected tab (must not equal [centerIndex]
  /// unless the center action is also meant to behave as a persistent
  /// tab).
  final int currentIndex;

  /// Called with the tapped tab's index - including [centerIndex] when
  /// the center action is tapped.
  final ValueChanged<int> onTap;

  /// The full tab set, in display order. If [centerIndex] is set, that
  /// slot's own [NavBarItem.icon] is used as the always-floating center
  /// blob's icon (a plus/add glyph is the typical choice).
  final List<NavBarItem> items;

  /// Index inside [items] that should render as a permanently-floating,
  /// prominent circular action (e.g. "Add") instead of a normal inline
  /// icon that only lifts up when selected. Pass `null` for a plain
  /// bar where every tab behaves the same way.
  final int? centerIndex;

  /// Background of the pill itself.
  final Color barColor;

  /// Fill color of the floating active badge / center blob.
  final Color accentColor;

  /// Icon color for the reference "Add" glyph icon on top of [accentColor].
  final Color accentIconColor;

  /// Color of inactive, inline icons.
  final Color inactiveColor;

  /// Height of the pill surface (excludes the part of the badge that
  /// floats above it).
  final double height;

  /// Horizontal margin between the pill and the screen edges.
  final double margin;

  const CustomFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.centerIndex,
    this.barColor = Colors.white,
    this.accentColor = const Color(0xFFE91E8C), // pink / magenta
    this.accentIconColor = Colors.white,
    this.inactiveColor = const Color(0xFF9AA0A6),
    this.height = 64,
    this.margin = 16,
  }) : assert(items.length >= 2, 'A nav bar needs at least 2 items');

  @override
  State<CustomFloatingNavBar> createState() => _CustomFloatingNavBarState();
}

class _CustomFloatingNavBarState extends State<CustomFloatingNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _fraction = 0; // animated 0..1 horizontal position of the active badge
  double _fromFraction = 0;
  double _toFraction = 0;

  // Tap-bounce for the always-floating center blob.
  bool _centerPressed = false;

  @override
  void initState() {
    super.initState();
    _fraction = _fractionForIndex(widget.currentIndex);
    _fromFraction = _fraction;
    _toFraction = _fraction;

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..addListener(_onTick);
  }

  void _onTick() {
    // Spring-driven progress is a physics simulation, not a 0..1 curve, so
    // we drive it via AnimationController.animateWith(SpringSimulation)
    // and just read `.value` (see _animateTo). The listener only needs to
    // re-lerp using the *current* controller value.
    setState(() {
      _fraction = _fromFraction + (_toFraction - _fromFraction) * _controller.value;
    });
  }

  double _fractionForIndex(int index) {
    final count = widget.items.length;
    return (index + 0.5) / count;
  }

  void _animateTo(double target) {
    _fromFraction = _fraction;
    _toFraction = target;
    _controller.stop();
    // Gentle, slightly bouncy spring - reads as "physical" rather than a
    // linear/eased slide.
    const spring = SpringDescription(mass: 1, stiffness: 260, damping: 22);
    final simulation = SpringSimulation(spring, 0, 1, 0);
    _controller.animateWith(simulation);
  }

  @override
  void didUpdateWidget(covariant CustomFloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final indexChanged = oldWidget.currentIndex != widget.currentIndex;
    final countChanged = oldWidget.items.length != widget.items.length;
    if ((indexChanged || countChanged) && widget.currentIndex != widget.centerIndex) {
      _animateTo(_fractionForIndex(widget.currentIndex));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const badgeSize = 52.0;
    const centerBlobSize = 58.0;
    final showMovingBadge = widget.currentIndex != widget.centerIndex;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset * 0.4 : 12, top: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth - widget.margin * 2;

          return SizedBox(
            height: widget.height + 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The pill surface + inline icons.
                Positioned(
                  left: widget.margin,
                  right: widget.margin,
                  bottom: 0,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.barColor,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: List.generate(
                        widget.items.length,
                        (i) => Expanded(child: _buildSlot(i)),
                      ),
                    ),
                  ),
                ),

                // The moving "active tab" floating badge.
                if (showMovingBadge)
                  Positioned(
                    left: widget.margin + _fraction * barWidth - badgeSize / 2,
                    bottom: widget.height - badgeSize / 2 - 6,
                    child: _FloatingBadge(
                      size: badgeSize,
                      color: widget.accentColor,
                      iconColor: widget.accentIconColor,
                      icon: widget.items[widget.currentIndex].activeIcon ??
                          widget.items[widget.currentIndex].icon,
                    ),
                  ),

                // The always-floating center "Add" blob, if configured.
                if (widget.centerIndex != null)
                  Positioned(
                    left: widget.margin +
                        _fractionForIndex(widget.centerIndex!) * barWidth -
                        centerBlobSize / 2,
                    bottom: widget.height - centerBlobSize / 2 - 10,
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _centerPressed = true),
                      onTapCancel: () => setState(() => _centerPressed = false),
                      onTapUp: (_) => setState(() => _centerPressed = false),
                      onTap: () => widget.onTap(widget.centerIndex!),
                      child: AnimatedScale(
                        scale: _centerPressed ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: _FloatingBadge(
                          size: centerBlobSize,
                          color: widget.accentColor,
                          iconColor: widget.accentIconColor,
                          icon: widget.items[widget.centerIndex!].icon,
                          elevated: true,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlot(int index) {
    final isCenter = index == widget.centerIndex;
    final isActive = index == widget.currentIndex && !isCenter;
    final item = widget.items[index];

    // The center slot's icon is drawn by the always-floating blob above,
    // and the active slot's icon is drawn by the moving badge above - so
    // both leave their inline cell empty to avoid double-drawing.
    if (isCenter || isActive) {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      selected: false,
      label: item.label,
      child: InkResponse(
        onTap: () => widget.onTap(index),
        radius: 28,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        child: Center(
          child: Icon(item.icon, color: widget.inactiveColor, size: 24),
        ),
      ),
    );
  }
}

/// The pink/magenta circular badge used both for the moving "active tab"
/// indicator and the always-floating center action.
class _FloatingBadge extends StatelessWidget {
  final double size;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final bool elevated;

  const _FloatingBadge({
    required this.size,
    required this.color,
    required this.iconColor,
    required this.icon,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: elevated ? 18 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.44),
      ),
    );
  }
}
