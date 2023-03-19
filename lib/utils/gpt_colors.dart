import 'package:flutter/material.dart';

class ChatGptColors {
  /// page colors
  static const Color mainBlack = Color(0xff2b2c32);
  static const Color secondaryBlack = Color(0xff36373f);
  static const Color mainTitle = Colors.black;
  static const Color subTitle = Color(0xffC9C4CD);
  static const Color mainPurple = Color(0xff7B57F7);
  static const Color menu = Color(0xff232628);
  static const Color middleMenu = Color(0xff191919);
  static const Color link = Color(0xff80ebf3);

  /// widget colors
  static const Color searchBar = Color(0xff202020);
}

final chatGptTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: ChatGptColors.mainBlack,
  cardColor: ChatGptColors.secondaryBlack,
  // fontFamily: 'RooneySans',
);
