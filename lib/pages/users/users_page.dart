import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_chat_gpt/pages/users/user_type.dart';
import 'package:my_chat_gpt/utils/gpt_colors.dart';

import '../../provider/user_provider.dart';
import '../../widgets/corner_image.dart';

class UsersWidget extends ConsumerWidget {
  const UsersWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTypes = ref.watch(userTypeProvider);

    return ListView.separated(
      itemBuilder: (context, index) {
        var userType = userTypes[index];
        return InkWell(
          child: UserWidget(
              name: userType.name, info: '', imageURL: userType.avatar),
          onTap: () {},
        );
      },
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: userTypes.length,
      separatorBuilder: (context, index) => const Divider(height: .5),
    );
  }
}

/// just simple user info, avatar name and info text.
class UserWidget extends ConsumerWidget {
  final String? imageURL;
  final String name;
  final String info;

  const UserWidget({
    Key? key,
    required this.name,
    required this.info,
    this.imageURL,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CornerImageWidget(
            size: 46,
            imageName: imageURL!,
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  info,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    color: GptColors.subTitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
