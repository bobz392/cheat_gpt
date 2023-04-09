import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_chat_gpt/provider/user_token_provider.dart';
import 'package:my_chat_gpt/utils/gpt_colors.dart';
import 'package:url_launcher/url_launcher_string.dart';

class _SaveTokenPageState extends ConsumerState<SaveTokenPage> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const buttonWidth = 600.0;
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(
          flex: 1,
        ),
        const Text(
          'Enter your token to use',
          style: TextStyle(
            color: ChatGptColors.subTitle,
            fontSize: 16,
          ),
        ),
        const SizedBox(
          height: 16.0,
        ),
        TextButton(
            onPressed: () {
              launchUrlString('https://platform.openai.com/account/api-keys');
            },
            child: const Text(
              "Where to find?",
              style: TextStyle(
                color: ChatGptColors.link,
                fontSize: 12,
              ),
            )),
        const SizedBox(
          height: 60.0,
        ),
        Container(
          width: buttonWidth,
          decoration: const BoxDecoration(
              border: Border(
            bottom: BorderSide(
              color: ChatGptColors.mainPurple,
            ),
          )),
          child: TextField(
            cursorColor: ChatGptColors.mainPurple,
            keyboardType: TextInputType.text,
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'your token. start with sk...',
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ChatGptColors.mainPurple)),
            ),
          ),
        ),
        const SizedBox(height: 40.0),
        SizedBox(
            width: buttonWidth,
            height: 40,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateColor.resolveWith(
                    (states) => ChatGptColors.mainPurple),
              ),
              onPressed: () {
                var token = _textController.text;
                if (token.isNotEmpty && token.startsWith('sk-')) {
                  ref.read(tokenProvider.notifier).writeToken(token);
                }
              },
              child: const Text('Save Token'),
            )),
        const Spacer(
          flex: 2,
        ),
        const Text('power by ultraman, it\'s none of my business.'),
        const SizedBox(height: 5.0),
      ],
    ))));
  }
}

class SaveTokenPage extends ConsumerStatefulWidget {
  const SaveTokenPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _SaveTokenPageState();
  }
}
