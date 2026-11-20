import 'package:flutter/material.dart';

class ZenithBrand {
  static const teal = Color(0xFF0B6C7D);
  static const coral = Color(0xFFF18176);
  static const paleTeal = Color(0xFFE7F1F3);
  static const paleCoral = Color(0xFFFDEBE8);

  static const logoAsset = 'assets/icons/logo.png';
}

class ZenithLogo extends StatelessWidget {
  const ZenithLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Zenith Square logo',
      image: true,
      child: Image.asset(
        ZenithBrand.logoAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class ZenithBrandTitle extends StatelessWidget {
  const ZenithBrandTitle({super.key, this.title, this.logoSize = 34});

  final String? title;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZenithLogo(size: logoSize),
        if (title != null) ...[
          const SizedBox(width: 8),
          Flexible(child: Text(title!, overflow: TextOverflow.ellipsis)),
        ],
      ],
    );
  }
}
