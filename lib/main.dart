import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_chat_gpt/pages/chat_page.dart';
import 'package:my_chat_gpt/pages/save_token_page.dart';
import 'package:my_chat_gpt/provider/user_token_provider.dart';

import 'package:my_chat_gpt/utils/gpt_colors.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('cheat-gpp');
    setWindowMinSize(const Size(1100, 700));
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenProvider);
    debugPrint("token = $token");
    return MaterialApp(
      theme: chatGptTheme,
      debugShowCheckedModeBanner: false,
      home: token == null
          ? const Text('waiting')
          : token.isEmpty
              ? const SaveTokenPage()
              : ChatPage(
                  token: token,
                ),
    );
  }
}
