import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:my_chat_gpt/provider/user_token_provider.dart';
import 'package:my_chat_gpt/utils/gpt_colors.dart';
import 'package:uuid/uuid.dart';

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
      id: '82091008-a484-4a89-ae75-a22bf8d6f3ac', firstName: 'Xi');
  final _gpt = const types.User(
      id: '82091008-a484-4a29-ae75-a22bf8d6f3ac',
      firstName: 'Chat-GPT(tap to speak)');
  final _uuid = const Uuid();
  final flutterTts = FlutterTts();
  int _currentSelection = 0;

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
      backgroundColor: ChatGptColors.mainBlack,
      inputBackgroundColor: ChatGptColors.secondaryBlack,
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
        customBottomWidget: Column(children: [
          Container(
            color: ChatGptColors.menu,
            height: 46,
            child: Row(
              children: [const Spacer(), _createSegment()],
            ),
          ),
          Container(
            height: 0.5,
            color: ChatGptColors.middleMenu,
          ),
          Input(
            // isAttachmentUploading: widget.isAttachmentUploading,
            // onAttachmentPressed: widget.onAttachmentPressed,
            onSendPressed: _handleSendPressed,
            options: const InputOptions(),
          ),
        ]),
        onMessageDoubleTap: (context, message) {
          if (message is types.TextMessage) {
            if (message.author.id != _user.id) {
              var data = ClipboardData(text: message.text);
              Clipboard.setData(data);
            } else {}
          }
        },
        onMessageTap: (context, message) async {
          debugPrint(message.type.toString());
          if (message is types.TextMessage) {
            debugPrint('start speak');
            await flutterTts.stop();
            if (_currentSelection == 0) {
              await flutterTts.setLanguage('zh-CN');
            } else if (_currentSelection == 1) {
              await flutterTts.setLanguage('ja-JP');
            } else if (_currentSelection == 2) {
              await flutterTts.setLanguage('en-US');
            }
            var result = await flutterTts.speak(message.text);
            debugPrint('speak result = $result');
            if (message.author.id != _user.id) {
            } else {
              var data = ClipboardData(text: message.text);
              Clipboard.setData(data);
            }
          }
        },
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

    if (_currentSelection == 0) {
      _sendAI('翻译成中文: ${message.text}');
    } else if (_currentSelection == 1) {
      _sendAI('翻译成日语: ${message.text}');
    } else if (_currentSelection == 2) {
      _sendAI('翻译成英语: ${message.text}');
    } else if (_currentSelection == 4) {
      _sendImage(message.text);
    } else {
      _sendAI(message.text);
    }
  }

  Widget _createSegment() {
    const Map<int, Widget> children = {
      0: Text(' Cn '),
      1: Text(' Jap '),
      2: Text(' English '),
      3: Text(' Chat '),
      4: Text(' Image '),
    };
    return MaterialSegmentedControl(
      children: children,
      selectionIndex: _currentSelection,
      selectedColor: ChatGptColors.menu,
      unselectedColor: ChatGptColors.middleMenu,
      selectedTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      unselectedTextStyle: const TextStyle(
        color: ChatGptColors.mainPurple,
        fontSize: 14,
      ),
      onSegmentTapped: (index) {
        setState(() {
          _currentSelection = index;
        });
      },
    );
  }

  void _sendImage(String prompt) async {
    try {
      OpenAIImageModel image = await OpenAI.instance.image.create(
        prompt: prompt,
        n: 1,
        size: OpenAIImageSize.size1024,
        responseFormat: OpenAIResponseFormat.url,
      );

      final imageMessage = types.ImageMessage(
          author: _gpt,
          id: _uuid.v4(),
          name: prompt,
          size: 1024 * 1024,
          uri: image.data.first.url);
      _addMessage(imageMessage);
    } catch (error) {
      _addErrorMessage(error);
    }
  }

  void _sendAI(String prompt) async {
    try {
      OpenAIChatCompletionModel chatCompletion =
          await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(content: prompt, role: 'user'),
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
}
