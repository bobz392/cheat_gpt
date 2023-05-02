import 'package:flutter/material.dart';

import '../utils/gpt_theme.dart';

class SplitView extends StatelessWidget {
  const SplitView({
    Key? key,
    required this.middle,
    required this.content,
  }) : super(key: key);

  final Widget middle;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    // return Row(
    //   children: [
    //     SizedBox(
    //       width: kInfoWidth,
    //       child: middle,
    //     ),
    //     Container(width: 0.5, color: Colors.black26),
    //     Expanded(child: content),
    //   ],
    // );
    return content;
  }
}
