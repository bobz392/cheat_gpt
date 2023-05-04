import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/prompt_provider.dart';
import '../utils/gpt_colors.dart';
import 'loading_widget.dart';

class PromptListWidget extends ConsumerWidget {
  const PromptListWidget({super.key});

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
            itemCount: prompts.length),
      );
    });
  }
}
