import 'package:dart_openai/openai.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:my_chat_gpt/pages/chats/chat_types.dart';
import 'package:my_chat_gpt/provider/message_provider.dart';
import 'package:my_chat_gpt/provider/openai_provider.dart';
import 'package:my_chat_gpt/provider/prompt_provider.dart';
// import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:my_chat_gpt/provider/user_token_provider.dart';
import 'package:my_chat_gpt/utils/gpt_colors.dart';
import 'package:uuid/uuid.dart';

import 'package:my_chat_gpt/widgets/prompt_list_widget.dart';

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
  final _flutterTts = FlutterTts();
  final _chatTypeTabController =
      MacosTabController(initialIndex: 0, length: ChatType.values.length);
  final _textEditingController = TextEditingController();

  @override
  void initState() {
    OpenAI.apiKey = widget.token;
    debugPrint("token = ${widget.token}");
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _chatTypeTabController.dispose();
    _textEditingController.dispose();
    _flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectPromptProvider, (previous, next) {
      if (next.isNotEmpty) {
        _textEditingController.text = next;
      }
    });
    final messages = ref.watch(messagesProvider);
    ref.listenManual(promptResponseProvider, (previous, next) {
      if (next != null) {
        if (next.finish == false) {
          _textEditingController.text = next.content;
          _textEditingController.selection =
              TextSelection.collapsed(offset: next.content.length);
        } else {
          final textMessage = types.TextMessage(
            author: _gpt,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: _uuid.v4(),
            text: next.content.trim(),
          );
          ref.watch(messagesProvider.notifier).addTextMessage(textMessage);
          _textEditingController.text = '';
        }
        ref.watch(sendEnableProvider.notifier).update((state) => next.finish);
      }
    });

    final enableSend = ref.watch(sendEnableProvider);

    const chatTheme = DefaultChatTheme(
      backgroundColor: GptColors.mainBlack,
      inputBackgroundColor: GptColors.secondaryBlack,
      inputBorderRadius: BorderRadius.zero,
      inputTextStyle: TextStyle(fontFamily: 'RooneySans'),
    );
    return Container(
        color: GptColors.mainBlack,
        child: SafeArea(
          maintainBottomViewPadding: true,
          child: Chat(
            theme: chatTheme,
            messages: messages,
            onSendPressed: _handleSendPressed,
            showUserNames: true,
            showUserAvatars: false,
            user: _user,
            onBackgroundTap: () async {
              await _flutterTts.stop();
            },
            // textMessageBuilder: (type,
            //     {required messageWidth, required showName}) {},
            useTopSafeAreaInset: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            customBottomWidget: _chatInputWidget(enableSend),
            // onMessageDoubleTap: (context, message) {},
            onMessageTap: _chatTap,
          ),
        ));
  }

  void _addMessage(types.Message message) {
    ref.watch(messagesProvider.notifier).addTextMessage(message);
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
    final chatType = _chatTypeTabController.index.toChatType;
    if (chatType == ChatType.cn) {
      _sendPromptToGpt('Translate into Chinese: ${message.text}');
    } else if (chatType == ChatType.jap) {
      _sendPromptToGpt('Translate into Japanese: ${message.text}');
    } else if (chatType == ChatType.en) {
      _sendPromptToGpt('Translate into English: ${message.text}');
    } else if (chatType == ChatType.image) {
      _sendImage(message.text);
    } else {
      _sendPromptToGpt(message.text);
    }
    ref.watch(selectPromptProvider.notifier).update((state) => '');
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

  void _sendPromptToGpt(String prompt) async {
    ref.read(promptResponseProvider.notifier).chatStart(prompt);
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
      await _flutterTts.stop();
      final chatType = _chatTypeTabController.index.toChatType;
      final tts = chatType.ttsLanguage;
      if (tts != null) {
        await _flutterTts.setLanguage(tts);
      }
      var result = _flutterTts.speak(message.text);
      debugPrint('speak result = $result');
      var data = ClipboardData(text: message.text);
      Clipboard.setData(data);
    } else if (message is types.ImageMessage) {
      var data = ClipboardData(text: message.uri);
      debugPrint(message.metadata.toString());
      Clipboard.setData(data);
    }
  }

  Widget _createSegment() {
    final tabs = ChatType.values
        .map((value) => MacosTab(label: value.displayName, active: false))
        .toList();

    return MacosSegmentedControl(
      tabs: tabs,
      controller: _chatTypeTabController,
    );
  }

  Widget _chatInputWidget(bool sendEnable) {
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
        onSendPressed: _handleSendPressed,
        options: InputOptions(
          textEditingController: _textEditingController,
          sendButtonVisibilityMode: sendEnable
              ? SendButtonVisibilityMode.always
              : SendButtonVisibilityMode.hidden,
          onTextChanged: (text) {
            debugPrint('text -> $text');
            if (_chatTypeTabController.index.toChatType == ChatType.chat &&
                text.startsWith('/') &&
                text.length == 1) {
              // show menu
              _showChatPrompts();
            }
          },
        ),
      )
    ]);
  }

  void _showChatPrompts() {
    showMacosSheet(
      context: context,
      barrierDismissible: true,
      barrierColor: GptColors.secondaryBlack.withOpacity(0.3),
      builder: (context) {
        return const MacosSheet(
          child: PromptListWidget(),
        );
      },
    );
  }
}
