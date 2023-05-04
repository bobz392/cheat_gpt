import 'package:dart_openai/openai.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:my_chat_gpt/provider/prompt_provider.dart';
// import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:my_chat_gpt/provider/user_token_provider.dart';
import 'package:my_chat_gpt/utils/gpt_colors.dart';
import 'package:my_chat_gpt/widgets/loading_widget.dart';
import 'package:uuid/uuid.dart';

import 'chat_types.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String token;
  const ChatPage({super.key, required this.token});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ChatPageState();
  }
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(
      id: '82091008-a484-4a89-ae75-a22bf8d6f3ac', firstName: 'coco');
  final _gpt = const types.User(
      id: '82091008-a484-4a29-ae75-a22bf8d6f3ac',
      firstName: 'Chat-GPT(tap to speak)');
  final _uuid = const Uuid();
  final flutterTts = FlutterTts();
  final tabController = MacosTabController(initialIndex: 0, length: 5);

  @override
  void initState() {
    OpenAI.apiKey = widget.token;
    debugPrint("token = ${widget.token}");
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    const chatTheme = DefaultChatTheme(
      backgroundColor: GptColors.mainBlack,
      inputBackgroundColor: GptColors.secondaryBlack,
      inputBorderRadius: BorderRadius.zero,
    );
    return Scaffold(
        body: SafeArea(
      maintainBottomViewPadding: true,
      child: Chat(
        theme: chatTheme,
        messages: _messages,
        onSendPressed: _handleSendPressed,
        showUserNames: true,
        showUserAvatars: false,
        user: _user,
        useTopSafeAreaInset: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        customBottomWidget: _chatTypeSegment(),
        onMessageDoubleTap: (context, message) {},
        onMessageTap: _chatTap,
      ),
    ));
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) {
    if (message.text == '-delete') {
      ref.read(tokenProvider.notifier).removeToken();
      return;
    }
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: message.text.trim(),
    );

    _addMessage(textMessage);
    final chatType = tabController.index.toChatType;
    if (chatType == ChatType.cn) {
      _sendAI('Translate the following text into Chinese: ${message.text}');
    } else if (chatType == ChatType.jap) {
      _sendAI('Translate the following text into Japanese: ${message.text}');
    } else if (chatType == ChatType.en) {
      _sendAI('Translate the following text into English: ${message.text}');
    } else if (chatType == ChatType.image) {
      _sendImage(message.text);
    } else {
      _sendAI(message.text);
    }
  }

  Widget _createSegment() {
    final tabs = ChatType.values
        .map((value) => MacosTab(label: value.displayName, active: false))
        .toList();

    return MacosSegmentedControl(
      tabs: tabs,
      controller: tabController,
    );
  }

  void _sendImage(String prompt) async {
    try {
      OpenAIImageModel image = await OpenAI.instance.image.create(
        prompt: prompt,
        n: 1,
        size: OpenAIImageSize.size1024,
        responseFormat: OpenAIImageResponseFormat.url,
      );

      final imageMessage = types.ImageMessage(
          author: _gpt,
          id: _uuid.v4(),
          name: prompt,
          size: 1024 * 1024,
          uri: image.data.first.url ?? '');
      _addMessage(imageMessage);
    } catch (error) {
      _addErrorMessage(error);
    }
  }

  void _sendAI(String prompt) async {
    try {
      const role = OpenAIChatMessageRole.user;
      OpenAIChatCompletionModel chatCompletion =
          await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(content: prompt, role: role),
        ],
      );
      debugPrint(chatCompletion.usage.toString());
      final result = chatCompletion.choices.first.message.content;
      final textMessage = types.TextMessage(
          author: _gpt,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: _uuid.v4(),
          text: result.trim());
      debugPrint("result = $result");
      _addMessage(textMessage);
    } catch (error) {
      _addErrorMessage(error);
    }
  }

  void _addErrorMessage(Object error) {
    final textMessage = types.TextMessage(
        author: _gpt,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _uuid.v4(),
        text: error.toString());
    _addMessage(textMessage);
  }

  void _chatTap(BuildContext context, types.Message message) async {
    if (message is types.TextMessage) {
      debugPrint('start speak');
      await flutterTts.stop();
      final chatType = tabController.index.toChatType;
      final tts = chatType.ttsLanguage;
      if (tts != null) {
        await flutterTts.setLanguage(tts);
      }
      var result = flutterTts.speak(message.text);
      debugPrint('speak result = $result');
      var data = ClipboardData(text: message.text);
      Clipboard.setData(data);
    } else if (message is types.ImageMessage) {
      var data = ClipboardData(text: message.uri);
      debugPrint(message.metadata.toString());
      Clipboard.setData(data);
    }
  }

  Widget _chatTypeSegment() {
    return Column(children: [
      Container(
        height: 30,
        color: GptColors.mainBlack,
        child: Row(
          children: [
            const Spacer(),
            _createSegment(),
            const SizedBox(width: 30)
          ],
        ),
      ),
      Container(
        height: 0.5,
        color: GptColors.middleMenu,
      ),
      Input(
        // isAttachmentUploading: widget.isAttachmentUploading,
        // onAttachmentPressed: widget.onAttachmentPressed,
        onSendPressed: _handleSendPressed,
        options: InputOptions(
          onTextChanged: (text) {
            debugPrint('text -> $text');
            if (tabController.index.toChatType == ChatType.chat &&
                text.startsWith('/') &&
                text.length == 1) {
              // show menu
              _showChatPrompts();
            }
          },
        ),
      ),
    ]);
  }

  void _showChatPrompts() {
    showMacosSheet(
      context: context,
      barrierDismissible: true,
      barrierColor: GptColors.secondaryBlack.withOpacity(0.3),
      builder: (context) {
        return const MacosSheet(
          child: PromptWidget(),
        );
      },
    );
  }
}

class PromptWidget extends ConsumerWidget {
  const PromptWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(promptsProvider);
    return prompts.when(loading: () {
      debugPrint('loading');
      return const LoadingWidget();
    }, error: (err, stack) {
      return TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Error: $err'));
    }, data: (prompts) {
      debugPrint('${prompts.length}');
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.separated(
            itemBuilder: (context, index) {
              return Container(
                color: index % 2 == 0 ? Colors.blue : Colors.amber,
                child: TextButton(
                  child: Text(
                      '[${prompts[index].first}] ${prompts[index].last}',
                      style: const TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (index != 0) {
                      ref
                          .read(selectPromptProvider.notifier)
                          .update((prompt) => prompts[index].last);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
            separatorBuilder: (context, index) {
              return const Divider(color: GptColors.middleMenu);
            },
            itemCount: prompts.length),
      );
    });
  }
}
