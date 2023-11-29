import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:my_chat_gpt/pages/chats/chat_types.dart';
import 'package:my_chat_gpt/provider/message_provider.dart';
import 'package:my_chat_gpt/provider/openai_provider.dart';
import 'package:my_chat_gpt/provider/prompt_provider.dart';
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
  final _user = const types.User(
      id: '82091008-a484-4a89-ae75-a22bf8d6f3ac', firstName: 'coco');
  final _gpt = const types.User(
      id: '82091008-a484-4a29-ae75-a22bf8d6f3ac',
      firstName: 'Chat-GPT(tap to speak)');
  final _uuid = const Uuid();
  final _flutterTts = FlutterTts();
  final _chatTypeTabController =
      MacosTabController(initialIndex: 0, length: ChatType.values.length);
  final _modelTypeController = MacosTabController(length: 2);
  final _textEditingController = TextEditingController();

  @override
  void initState() {
    OpenAI.apiKey = widget.token;
    debugPrint("token = ${widget.token}");
    _modelTypeController.addListener(() {
      int index = _modelTypeController.index;
      ref.watch(modelTypeProvider.notifier).update((state) => index);
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _chatTypeTabController.dispose();
    _modelTypeController.dispose();
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
    final currentModelIndex = ref.watch(modelTypeProvider.notifier);
    final messages = ref.watch(messagesProvider);
    ref.listen(promptResponseProvider, (previous, next) {
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
          ref.read(messagesProvider.notifier).addTextMessage(textMessage);
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
        messageMinWidth: double.infinity);
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _onKeyEvent,
      child: Container(
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
              onBackgroundTap: () {
                _flutterTts.stop();
              },
              useTopSafeAreaInset: true,
              textMessageBuilder: _textMessageBuild,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              customBottomWidget:
                  _chatInputWidget(enableSend, currentModelIndex.state),
              // onMessageDoubleTap: (context, message) {},
              onMessageTap: _chatTap,
            ),
          )),
    );
  }

  MatchText get codeMatcher {
    final codePattern = PatternStyle(
        '```',
        RegExp('```[a-z]*\\n[\\s\\S]*?\n``[`]?'),
        '',
        const TextStyle(
          fontFamily: 'RooneySans',
        ));
    return MatchText(
        pattern: codePattern.pattern,
        style: codePattern.textStyle,
        renderText: ({required String str, required String pattern}) {
          debugPrint('codeMatcher ${codePattern.textStyle}');
          var lines = str.split('\n');
          lines.removeLast();
          if (lines.isNotEmpty) {
            lines.removeAt(0);
          }
          return {
            'display': lines.join('\n'),
          };
        });
  }

  MatchText get commentMatcher {
    final codePattern = PatternStyle(
        '#',
        RegExp('\\s*//.*\\s'),
        '#',
        const TextStyle(
          fontFamily: 'RooneySans',
          color: Color(0xff008100),
          fontWeight: FontWeight.w300,
        ));
    return MatchText(
        pattern: codePattern.pattern,
        style: codePattern.textStyle,
        renderText: ({required String str, required String pattern}) {
          debugPrint('commentMatcher $str');
          return {
            'display': str,
          };
        });
  }

  TextMessage _textMessageBuild(message,
      {required int messageWidth, required bool showName}) {
    return TextMessage(
      emojiEnlargementBehavior: EmojiEnlargementBehavior.never,
      hideBackgroundOnEmojiMessages: true,
      message: message,
      showName: showName,
      usePreviewData: false,
      options: TextMessageOptions(
        matchers: [
          // commentMatcher, // TODO: comment matcher
          codeMatcher,
        ],
      ),
    );
  }

  void _addMessage(types.Message message) {
    ref.watch(messagesProvider.notifier).addTextMessage(message);
  }

  void _handleSendPressed(types.PartialText message) {
    if (message.text == '-delete') {
      ref.read(tokenProvider.notifier).removeToken();
      return;
    }
    String prompt;
    final displayMessage = message.text.trim();
    final chatType = _chatTypeTabController.index.toChatType;
    if (chatType == ChatType.cn) {
      prompt = 'Translate into Chinese: $displayMessage';
    } else if (chatType == ChatType.jap) {
      prompt = 'Translate into Japanese: $displayMessage';
    } else if (chatType == ChatType.en) {
      prompt = 'Translate into English: $displayMessage';
    } else if (chatType == ChatType.image) {
      _sendImage(displayMessage);
      return;
    } else {
      prompt = displayMessage;
    }
    String model;
    if (_modelTypeController.index == 0) {
      model = "gpt-3.5-turbo";
    } else {
      model = "gpt-4-1106-preview";
    }
    _sendPromptToGpt(prompt, model);
    // add my prompt message
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: displayMessage,
    );
    _addMessage(textMessage);
    // clear select prompt
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

  void _sendPromptToGpt(String prompt, String model) async {
    ref.read(promptResponseProvider.notifier).chatStart(prompt, model);
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

  Widget _createModelTypeSegment(int currentModelIndex) {
    final tabs = ['gpt-3.5', 'gpt-4.0']
        .map((value) => MacosTab(label: value, active: false))
        .toList();

    final segment = MacosSegmentedControl(
      tabs: tabs,
      controller: _modelTypeController,
    );
    _modelTypeController.index = currentModelIndex;
    return segment;
  }

  Widget _createPromptTypeSegment() {
    final tabs = ChatType.values
        .map((value) => MacosTab(label: value.displayName, active: false))
        .toList();

    return MacosSegmentedControl(
        tabs: tabs, controller: _chatTypeTabController);
  }

  Widget _chatInputWidget(bool sendEnable, int currentModelIndex) {
    return Column(children: [
      Container(
        height: 30,
        color: GptColors.mainBlack,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                _createModelTypeSegment(currentModelIndex),
                const Spacer(),
                _createPromptTypeSegment(),
              ],
            )),
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
            // debugPrint('onTextChanged -> $text');
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

  void _onKeyEvent(RawKeyEvent event) {
    if (event.runtimeType == RawKeyDownEvent) {
      if (event.isMetaPressed) {
        setState(() {
          if (event.physicalKey == PhysicalKeyboardKey.digit1) {
            _chatTypeTabController.index = 0;
          } else if (event.physicalKey == PhysicalKeyboardKey.digit2) {
            _chatTypeTabController.index = 1;
          } else if (event.physicalKey == PhysicalKeyboardKey.digit3) {
            _chatTypeTabController.index = 2;
          } else if (event.physicalKey == PhysicalKeyboardKey.digit4) {
            _chatTypeTabController.index = 3;
          } else if (event.physicalKey == PhysicalKeyboardKey.digit5) {
            _chatTypeTabController.index = 4;
          }
        });
      }
      debugPrint('${event.physicalKey}, ${event.isMetaPressed}');
    }
  }
}
