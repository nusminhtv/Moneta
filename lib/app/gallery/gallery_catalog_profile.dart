import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';

/// Gallery sections for 📱 08 Profile & Settings.
///
/// Its own file for the same reason the auth, home, budget and insight spreads
/// are: two agents editing one list collide on every line.
final List<GallerySection> profileSections = [
  // --- PROFILE: add sections below ---
  GallerySection(
    component: 'Avatar',
    figmaNodeId: '21:121',
    // All twelve. Built from the enums rather than written out, so a fifth size
    // or a fourth type cannot be added without appearing here.
    variants: [
      for (final type in MonetaAvatarType.values)
        for (final size in MonetaAvatarSize.values)
          GalleryVariant(
            'Type=${_figmaType(type)}, ${size.figmaName}',
            (_) => MonetaAvatar(
              type: type,
              size: size,
              name: 'Minh Tran',
              // A 1×1 transparent pixel, so the image variant renders itself
              // rather than falling through to initials. `21:121` calls the
              // image variants placeholders and this is the smallest honest
              // placeholder there is.
              image: type == MonetaAvatarType.image ? _pixel : null,
            ),
          ),
    ],
  ),
];

/// Figma's name for a type: `Image`, `Initials`, `Icon`.
String _figmaType(MonetaAvatarType type) =>
    type.name[0].toUpperCase() + type.name.substring(1);

/// A 1×1 transparent PNG. No I/O, no network, no asset bundle.
final MemoryImage _pixel = MemoryImage(
  Uint8List.fromList(const [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    10,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    0,
    1,
    0,
    0,
    5,
    0,
    1,
    13,
    10,
    45,
    180,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ]),
);
