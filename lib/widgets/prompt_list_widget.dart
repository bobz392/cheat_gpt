import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../provider/prompt_provider.dart';
import '../utils/gpt_colors.dart';
import 'loading_widget.dart';

class PromptListWidget extends ConsumerStatefulWidget {
  const PromptListWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _PromptListState();
  }
}

class _PromptListState extends ConsumerState<PromptListWidget> {
  final _tabController = MacosTabController(length: 2);
  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _tabView();
  }

  Widget _tabView() {
    const tabs = [
      MacosTab(
        label: 'en',
        active: true,
      ),
      MacosTab(
        label: 'zh',
        active: false,
      )
    ];
    return MacosTabView(
        controller: _tabController,
        tabs: tabs,
        children: [_enPromptList, _zhPromptList]);
  }

  Widget get _enPromptList {
    final prompts = ref.watch(promptsProvider);
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: prompts.when(loading: () {
          debugPrint('loading awesome prompts');
          return const LoadingWidget();
        }, error: (err, stack) {
          return TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Error: $err'));
        }, data: (prompts) {
          debugPrint('${prompts.length}');
          return ListView.separated(
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: GptColors.secondaryBlack
                      .withOpacity(index % 2 == 0 ? 0.4 : 0.3),
                  child: TextButton(
                    child: Text(
                        '[${prompts[index].first}]\n${prompts[index].last}',
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
                return Divider(
                  color: GptColors.middleMenu.withOpacity(0.2),
                  height: 0.5,
                );
              },
              itemCount: prompts.length);
        }));
  }

  Widget get _zhPromptList {
    final prompts = ref.watch(zhPromptsProvider);
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: prompts.when(loading: () {
          debugPrint('loading awesome prompts');
          return const LoadingWidget();
        }, error: (err, stack) {
          return TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Error: $err'));
        }, data: (prompts) {
          debugPrint('${prompts.length}');
          return ListView.separated(
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: GptColors.secondaryBlack
                      .withOpacity(index % 2 == 0 ? 0.4 : 0.3),
                  child: TextButton(
                    child: Text(
                        '[${prompts[index]['act']}]\n${prompts[index]['prompt']}',
                        style: const TextStyle(color: Colors.white)),
                    onPressed: () {
                      if (index != 0) {
                        ref
                            .read(selectPromptProvider.notifier)
                            .update((prompt) => prompts[index]['prompt']);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return Divider(
                  color: GptColors.middleMenu.withOpacity(0.2),
                  height: 0.5,
                );
              },
              itemCount: prompts.length);
        }));
  }
}
