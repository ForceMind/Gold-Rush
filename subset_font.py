#!/usr/bin/env python3
# 精简字体文件，只保留需要的中文字符

from fontTools.ttLib import TTFont
from fontTools.subset import Subsetter, Options
import os

# 需要保留的中文字符
text = """
=== 技能说明 ===
=== 游戏说明 ===
=== 道具说明 ===
关闭
击杀怪物有概率掉落道具：
分数：0
分裂魔弹
基础升级：
开始游戏
按 R 或点击重新开始
操作方式：
收集金币，消灭怪物，升级武器！
最终分数：0
武器：魔弹  伤害 1  数量 1  穿透 0  间隔 0.65 秒
游戏结束
游戏说明
点击一个选项继续
疾速施法
等级：1  下次选择：6 分
选择一个武器升级
重击魔弹
黄金冲刺
鼠标控制: 关
鼠标控制: 开
v1.0
v1.1
v1.2
v1.3
v1.4
v1.5
v1.6
v1.7
v1.8
v1.9
v2.0
"""

# 提取唯一字符
chars = set(text)
# 添加ASCII字符
chars.update(chr(i) for i in range(32, 127))

print(f"需要保留的字符数: {len(chars)}")

# 加载字体
font_path = "assets/fonts/NotoSansCJKsc-Regular.otf"
output_path = "assets/fonts/NotoSansCJKsc-Regular-subset.otf"

print(f"加载字体: {font_path}")
font = TTFont(font_path)

# 精简字体
options = Options()
options.layout_features = ['*']  # 保留所有布局特性
options.layout_scripts = ['*']   # 保留所有脚本
options.layout_languages = ['*'] # 保留所有语言

subsetter = Subsetter(options=options)
subsetter.populate(text=''.join(chars))
subsetter.subset(font)

# 保存精简后的字体
print(f"保存精简字体: {output_path}")
font.save(output_path)

# 检查文件大小
original_size = os.path.getsize(font_path)
subset_size = os.path.getsize(output_path)
print(f"原始字体大小: {original_size / 1024:.1f} KB")
print(f"精简后大小: {subset_size / 1024:.1f} KB")
print(f"压缩比: {(1 - subset_size / original_size) * 100:.1f}%")
