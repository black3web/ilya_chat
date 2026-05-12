// File: lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Background ──────────────────────────────────────
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceLight = Color(0xFF1A1A25);

  // ── Neon Red System ──────────────────────────────────
  static const Color neonRed = Color(0xFFFF0033);
  static const Color neonRedDim = Color(0xFFCC0028);
  static const Color neonRedGlow = Color(0x55FF0033);
  static const Color neonRedFaint = Color(0x22FF0033);
  static const Color darkRed = Color(0xFF8B0000);

  // ── Silver / Metallic ────────────────────────────────
  static const Color silver = Color(0xFFB0B8C8);
  static const Color silverDim = Color(0xFF6B7280);
  static const Color silverLight = Color(0xFFE2E8F0);

  // ── Glass ────────────────────────────────────────────
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // ── Status Colors ────────────────────────────────────
  static const Color online = Color(0xFF00FF88);
  static const Color offline = Color(0xFF6B7280);
  static const Color typing = Color(0xFF00BFFF);
  static const Color readReceipt = Color(0xFF00BFFF);
  static const Color sentReceipt = Color(0xFF9CA3AF);

  // ── Text ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFECECEC);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF4B5563);
  static const Color textLink = Color(0xFF60A5FA);

  // ── Message Bubbles ──────────────────────────────────
  static const Color myBubble = Color(0x33FF0033);
  static const Color myBubbleBorder = Color(0x55FF0033);
  static const Color otherBubble = Color(0x1AFFFFFF);
  static const Color otherBubbleBorder = Color(0x26FFFFFF);

  // ── Story Ring Colors ────────────────────────────────
  static const Color storyUnseen = Color(0xFF00FF88);
  static const Color storySeen = Color(0xFF4B5563);

  // ── Admin / Superuser ────────────────────────────────
  static const Color superuserCrown = Color(0xFFFFD700);
  static const Color superuserCrownAccent = Color(0xFFFF0033);

  // ── Rank Colors (Discord style) ──────────────────────
  static const List<Color> rankColors = [
    Color(0xFFFF6B6B), // Owner - Red
    Color(0xFFFFD93D), // Admin - Gold
    Color(0xFF6BCB77), // Moderator - Green
    Color(0xFF4D96FF), // Member - Blue
    Color(0xFF9CA3AF), // Guest - Gray
  ];

  // ── 30 Profile Gradients ─────────────────────────────
  static const List<List<Color>> profileGradients = [
    [Color(0xFF0A0A0F), Color(0xFF1A0A14)],
    [Color(0xFF0D0D1A), Color(0xFF1A0D2E)],
    [Color(0xFF0A0F0A), Color(0xFF0A1A0A)],
    [Color(0xFF0F0A0A), Color(0xFF2A0A0A)],
    [Color(0xFF0A0D14), Color(0xFF0A142A)],
    [Color(0xFF14100A), Color(0xFF2A1A0A)],
    [Color(0xFF0A0F14), Color(0xFF0A1A28)],
    [Color(0xFF10080C), Color(0xFF200A14)],
    [Color(0xFF080A10), Color(0xFF0A1020)],
    [Color(0xFF0C0A08), Color(0xFF1A1408)],
    [Color(0xFF0A0C10), Color(0xFF12182A)],
    [Color(0xFF100A14), Color(0xFF201028)],
    [Color(0xFF080C0A), Color(0xFF0C1A12)],
    [Color(0xFF0C0808), Color(0xFF1A0C0C)],
    [Color(0xFF08080C), Color(0xFF10101E)],
    [Color(0xFF0E0A0C), Color(0xFF1E1016)],
    [Color(0xFF0A0E10), Color(0xFF0A1A20)],
    [Color(0xFF100C08), Color(0xFF201808)],
    [Color(0xFF080C10), Color(0xFF0C1620)],
    [Color(0xFF0C100A), Color(0xFF181E0A)],
    [Color(0xFF10080A), Color(0xFF20080C)],
    [Color(0xFF080A0E), Color(0xFF0A0E1C)],
    [Color(0xFF0E0E08), Color(0xFF1C1C08)],
    [Color(0xFF080E0C), Color(0xFF081C16)],
    [Color(0xFF0C0C10), Color(0xFF14141E)],
    [Color(0xFF100A0C), Color(0xFF1E0A14)],
    [Color(0xFF0A100C), Color(0xFF0A1E12)],
    [Color(0xFF0C0A10), Color(0xFF160A1E)],
    [Color(0xFF100C0A), Color(0xFF1E140A)],
    [Color(0xFF0A0C0E), Color(0xFF0A141A)],
  ];

  // ── Icon Link Colors ─────────────────────────────────
  static const List<Color> iconLinkColors = [
    Color(0xFFFF0033), Color(0xFFFF6B35), Color(0xFFFFD700),
    Color(0xFF00FF88), Color(0xFF00BFFF), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFFFFFFFF), Color(0xFF9CA3AF),
    Color(0xFF34D399), Color(0xFFF59E0B), Color(0xFFEF4444),
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFF6366F1),
    Color(0xFF14B8A6),
  ];
}
