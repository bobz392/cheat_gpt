import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:my_chat_gpt/pages/chats/chat_page.dart';
import 'package:my_chat_gpt/pages/token/save_token_page.dart';
import 'package:my_chat_gpt/pages/users/users_page.dart';
import 'package:my_chat_gpt/provider/user_token_provider.dart';
import 'package:my_chat_gpt/utils/gpt_colors.dart';

import 'package:my_chat_gpt/widgets/loading_widget.dart';
import 'package:my_chat_gpt/widgets/split_view_widget.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // config window for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    setWindowTitle('daydayup');
    WindowOptions windowOptions = WindowOptions(
      size: const Size(1100, 700),
      minimumSize: const Size(1100, 700),
      backgroundColor: GptColors.mainBlack.withOpacity(0.4),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenProvider);
    // return MaterialApp(
    //   home: Scaffold(
    //     body: _tokenWidget(token),
    //     // body: Container(
    //     //   color: Colors.redAccent,
    //     // ),
    //   ),
    // );
    return MacosApp(
        theme: MacosThemeData.light(),
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: _tokenWidget(token),
        ));
  }

  Widget _tokenWidget(String? token) {
    // null was unknown status, need reading token from file
    if (token == null) {
      return const LoadingWidget();
    } else {
      if (token.isNotEmpty) {
        return SplitView(
            middle: const UsersWidget(),
            content: ChatPage(
              token: token,
            ));
      } else {
        return const SaveTokenPage();
      }
    }
  }
}
