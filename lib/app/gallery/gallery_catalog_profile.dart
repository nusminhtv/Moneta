import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';
import 'package:moneta/design_system/atoms/moneta_badge.dart';
import 'package:moneta/design_system/atoms/moneta_chip.dart';
import 'package:moneta/design_system/molecules/moneta_search_field.dart';

/// Gallery sections for 📱 08 Profile & Settings.
///
/// Its own file for the same reason the auth, home, budget and insight spreads
/// are: two agents editing one list collide on every line.
final List<GallerySection> profileSections = [
  // --- PROFILE: add sections below ---
  GallerySection(
    component: 'SearchField',
    figmaNodeId: '35:38',
    // Both authored states, reached the way a user reaches them — by there
    // being text or not. There is no `state` parameter to pass.
    variants: [
      GalleryVariant(
        'State=Empty',
        (_) => const MonetaSearchField(placeholder: 'Search transactions'),
      ),
      GalleryVariant(
        'State=Filled',
        (_) => MonetaSearchField(
          placeholder: 'Search transactions',
          controller: TextEditingController(text: 'Highlands'),
          clearSemanticLabel: 'Clear search',
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'Chip',
    figmaNodeId: '17:65',
    // All six. `leadingIcon` is a boolean property rather than a variant axis,
    // so it does not appear here — `17:65` authors no node for "Filter,
    // unselected, with a glyph".
    variants: [
      for (final type in MonetaChipType.values)
        for (final selected in [false, true])
          GalleryVariant(
            'Type=${type.figmaName}, Selected=$selected',
            (_) => MonetaChip(
              label: type.figmaName,
              type: type,
              selected: selected,
              onSelected: () {},
              onClose: () {},
              closeSemanticLabel: 'Remove ${type.figmaName}',
            ),
          ),
    ],
  ),
  GallerySection(
    component: 'Badge',
    figmaNodeId: '17:32',
    // All ten, built from the enums so a sixth tone cannot be added without
    // appearing here. The dot is a boolean *property*, not a variant axis —
    // `17:32` authors no node for a dotless Success/Sm — so it is exercised by
    // the component's tests rather than by entries here.
    variants: [
      for (final tone in MonetaBadgeTone.values)
        for (final size in MonetaBadgeSize.values)
          GalleryVariant(
            'Tone=${tone.figmaName}, ${size.figmaName}',
            (_) => MonetaBadge(
              label: tone.figmaName,
              tone: tone,
              size: size,
            ),
          ),
    ],
  ),
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
