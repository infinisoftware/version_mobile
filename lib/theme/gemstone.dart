import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colors of the 8 levels, same values as frontend/src/utils/gemstone.ts.
class Gemstone {
  const Gemstone({
    required this.id,
    required this.name,
    required this.icon,
    required this.accent,
    required this.tileText,
    required this.badgeText,
    required this.header,
    required this.button,
    required this.buttonText,
    this.cardMiddle = const Color(0xF21E293B),
  });

  final int id;
  final String name;
  final IconData icon;
  final Color accent;
  final Color tileText;
  final Color badgeText;
  final List<Color> header;
  final List<Color> button;
  final Color buttonText;
  final Color cardMiddle;

  List<Color> get cardGradient => [accent.withValues(alpha: 0.25), cardMiddle, AppColors.background];
}

const _dark = Color(0xFF020617);

const gemstones = <Gemstone>[
  Gemstone(
    id: 1,
    name: 'Bronze',
    icon: Icons.workspace_premium_outlined,
    accent: Color(0xFFD97706),
    tileText: Color(0xFFFCD34D),
    badgeText: Color(0xFFFBBF24),
    header: [Color(0xFFD97706), Color(0xFFC2410C)],
    button: [Color(0xFFD97706), Color(0xFFEA580C)],
    buttonText: Colors.white,
  ),
  Gemstone(
    id: 2,
    name: 'Silver',
    icon: Icons.shield_outlined,
    accent: Color(0xFFCBD5E1),
    tileText: Color(0xFFF1F5F9),
    badgeText: Color(0xFFE2E8F0),
    header: [Color(0xFFCBD5E1), Color(0xFF71717A)],
    button: [Color(0xFFCBD5E1), Color(0xFFA1A1AA)],
    buttonText: _dark,
  ),
  Gemstone(
    id: 3,
    name: 'Gold',
    icon: Icons.emoji_events_outlined,
    accent: Color(0xFFFACC15),
    tileText: Color(0xFFFDE047),
    badgeText: Color(0xFFFDE047),
    header: [Color(0xFFFACC15), Color(0xFFF59E0B)],
    button: [Color(0xFFFACC15), Color(0xFFF59E0B)],
    buttonText: _dark,
  ),
  Gemstone(
    id: 4,
    name: 'Platinum',
    icon: Icons.auto_awesome_outlined,
    accent: Color(0xFF22D3EE),
    tileText: Color(0xFFA5F3FC),
    badgeText: Color(0xFF67E8F9),
    header: [Color(0xFF67E8F9), Color(0xFF14B8A6)],
    button: [Color(0xFF22D3EE), Color(0xFF14B8A6)],
    buttonText: _dark,
  ),
  Gemstone(
    id: 5,
    name: 'Master',
    icon: Icons.emoji_events_outlined,
    accent: Color(0xFFA855F7),
    tileText: Color(0xFFE9D5FF),
    badgeText: Color(0xFFD8B4FE),
    header: [Color(0xFFA855F7), Color(0xFF7C3AED)],
    button: [Color(0xFFA855F7), Color(0xFF7C3AED)],
    buttonText: Colors.white,
  ),
  Gemstone(
    id: 6,
    name: 'Titanium',
    icon: Icons.shield_outlined,
    accent: Color(0xFF10B981),
    tileText: Color(0xFFA7F3D0),
    badgeText: Color(0xFF6EE7B7),
    header: [Color(0xFF34D399), Color(0xFF0D9488)],
    button: [Color(0xFF10B981), Color(0xFF0D9488)],
    buttonText: Colors.white,
  ),
  Gemstone(
    id: 7,
    name: 'Diamond',
    icon: Icons.diamond_outlined,
    accent: Color(0xFF38BDF8),
    tileText: Color(0xFFBAE6FD),
    badgeText: Color(0xFF7DD3FC),
    header: [Color(0xFF38BDF8), Color(0xFF2563EB)],
    button: [Color(0xFF38BDF8), Color(0xFF2563EB)],
    buttonText: Colors.white,
    cardMiddle: Color(0x4D1E3A8A),
  ),
  Gemstone(
    id: 8,
    name: 'Master Diamond',
    icon: Icons.diamond_outlined,
    accent: Color(0xFFF43F5E),
    tileText: Color(0xFFFECDD3),
    badgeText: Color(0xFFFDA4AF),
    header: [Color(0xFFF43F5E), Color(0xFFD946EF), Color(0xFF6366F1)],
    button: [Color(0xFFF43F5E), Color(0xFFC026D3), Color(0xFF4F46E5)],
    buttonText: Colors.white,
    cardMiddle: Color(0x4D701A75),
  ),
];

Gemstone gemstoneFor(int displayOrder) =>
    gemstones.firstWhere((g) => g.id == displayOrder, orElse: () => gemstones.first);
