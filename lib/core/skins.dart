import 'package:flutter/material.dart';

class OrbSkin {
  const OrbSkin({
    required this.id,
    required this.name,
    required this.core,
    required this.glow,
    required this.price,
  });

  final String id;
  final String name;
  final Color core;
  final Color glow;
  final int price;
}

const List<OrbSkin> kSkins = [
  OrbSkin(
    id: 'nova',
    name: 'Nova',
    core: Color(0xFFFFFFFF),
    glow: Color(0xFF5CE1FF),
    price: 0,
  ),
  OrbSkin(
    id: 'ember',
    name: 'Ember',
    core: Color(0xFFFFF1C2),
    glow: Color(0xFFFF8A3D),
    price: 40,
  ),
  OrbSkin(
    id: 'mint',
    name: 'Mint',
    core: Color(0xFFE9FFF3),
    glow: Color(0xFF3DFFA2),
    price: 80,
  ),
  OrbSkin(
    id: 'rose',
    name: 'Rose',
    core: Color(0xFFFFE3EF),
    glow: Color(0xFFFF4DA6),
    price: 120,
  ),
  OrbSkin(
    id: 'violet',
    name: 'Violet',
    core: Color(0xFFF1E6FF),
    glow: Color(0xFFA66CFF),
    price: 180,
  ),
  OrbSkin(
    id: 'solar',
    name: 'Solar',
    core: Color(0xFFFFFFE0),
    glow: Color(0xFFFFD60A),
    price: 250,
  ),
  OrbSkin(
    id: 'frost',
    name: 'Frost',
    core: Color(0xFFFFFFFF),
    glow: Color(0xFFB8F3FF),
    price: 350,
  ),
  OrbSkin(
    id: 'void',
    name: 'Void',
    core: Color(0xFF1A1033),
    glow: Color(0xFFFF2E63),
    price: 500,
  ),
];

OrbSkin skinById(String id) =>
    kSkins.firstWhere((s) => s.id == id, orElse: () => kSkins.first);
