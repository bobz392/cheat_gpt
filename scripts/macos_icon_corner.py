import os
from PIL import Image, ImageDraw


def make_corner():
    folder_path = os.path.abspath(os.path.join(
        os.getcwd())) + '/macos/Runner/Assets.xcassets/AppIcon.appiconset'
    print(folder_path)
    for filename in os.listdir(folder_path):
        filepath = os.path.join(folder_path, filename)
        # savepath = os.path.join(folder_path, 'c' + filename)
        # 判断文件是否为图片
        if os.path.isfile(filepath) and filename.lower()\
                .endswith(('.png', '.jpg', '.jpeg', '.bmp', '.gif', '.webp')):
            # 打开图片
            with Image.open(filepath) as im:
                # 获取图片宽高
                width, height = im.size
                # 计算圆角半径（取宽高中较小值的1/10）
                radius = min(width, height) // 10
                # 创建一个完全透明的图像
                mask = Image.new('L', (width, height), 0)
                # 绘制一个圆角矩形，将其作为mask
                draw = ImageDraw.Draw(mask)
                draw.rounded_rectangle(
                    (0, 0, width, height), radius, fill=255)
                # 对原图像进行剪裁，并将mask应用于剪裁出来的图像
                im = im.crop((0, 0, width, height)).convert('L')
                im.putalpha(mask)
                # 保存处理后的图像
                im.save(filepath)


make_corner()
