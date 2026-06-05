# 黄金冲刺 - Godot 4.x 2D 原型

🎮 **在线游戏体验地址**: [https://goldrush-dg0.pages.dev/](https://goldrush-dg0.pages.dev/)

这是一个俯视角躲避收集小游戏原型：玩家移动收集金币，敌人追踪玩家，碰到敌人后游戏结束，按 R 重新开始。

## 文件结构

```text
黄金冲刺/
  project.godot
  assets/
    background.svg
    coin.svg
    enemy.svg
    generated_background.svg
    generated_hero.svg
    magic_bolt.svg
    monster_brute.svg
    monster_slime.svg
    monster_wisp.svg
    player.svg
  scenes/
    Main.tscn
    Player.tscn
    Coin.tscn
    Enemy.tscn
    Projectile.tscn
    UI.tscn
  scripts/
    Main.gd
    Player.gd
    Coin.gd
    Enemy.gd
    Projectile.gd
    WeaponController.gd
    UI.gd
```

## 实现步骤

1. `assets/` 里先准备了简单 SVG 美术资源：背景、玩家、金币、敌人。
2. `Player.tscn` 使用 `CharacterBody2D`，`Player.gd` 读取 WASD 和方向键移动，并限制在 1280x720 区域内。
3. `Coin.tscn` 使用 `Area2D`，玩家碰到后由 `Coin.gd` 发出 `collected` 信号。
4. `Enemy.tscn` 使用 `Area2D`，`Enemy.gd` 每帧朝玩家移动，碰到玩家后发出 `hit_player` 信号。
5. `Projectile.tscn` 使用 `Area2D`，`Projectile.gd` 负责飞行、命中和穿透。
6. `WeaponController.gd` 自动寻找最近敌人并发射魔法弹，升级会修改射速、伤害、数量、穿透、速度和尺寸。
7. `UI.tscn` 使用 `CanvasLayer` 显示分数、等级、武器属性、升级选择和游戏结束覆盖层。
8. `Main.tscn` 是主场景，`Main.gd` 负责随机生成金币和敌人、计分、升级选择、游戏结束和重开。

## 新增玩法

- 玩家会自动朝最近的敌人发射魔法弹。
- 升级选择采用阶梯式阈值：默认第 6 分触发，之后每次需要的新增分数都会提高。
- 选择升级后游戏继续。
- 敌人现在有 3 种随机类型：轻型、普通、重型。重型妖怪会在等级 3 后加入随机池。
- 敌人不会一击就死，基础生命值更高，并且生命、速度、刷怪频率、场上敌人数上限都会随等级阶梯成长。
- 妖怪头顶有简单血条，方便确认命中反馈和剩余生命。
- 敌人被击败后有 `coin_drop_chance` 概率补充一个金币。

## 可调变量

打开 `scenes/Main.tscn`，选中根节点 `Main`，在 Inspector 里可以调：

- `player_speed`：玩家速度
- `enemy_speed`：敌人速度
- `coin_spawn_interval`：金币生成间隔
- `enemy_spawn_interval`：敌人生成间隔
- `max_coins`：场上最多金币数
- `initial_enemy_count`：开局敌人数
- `spawn_margin`：生成点距离边缘的距离
- `first_upgrade_score`：第一次武器选择需要的分数
- `upgrade_score_step_growth`：每次升级后，下一次选择需求额外增加多少分
- `max_coins_growth_per_level`：每级提高的金币上限
- `base_max_enemies`：基础场上敌人上限
- `max_enemies_growth_per_level`：每级提高的敌人上限
- `min_enemy_spawn_interval`：敌人生成间隔的最低值
- `enemy_spawn_interval_decrease_per_level`：每级减少的敌人生成间隔
- `min_coin_spawn_interval`：金币生成间隔的最低值
- `coin_spawn_interval_decrease_per_level`：每级减少的金币生成间隔
- `enemy_speed_growth_per_level`：每次升级后敌人的速度成长
- `enemy_health_growth_per_level`：每次升级后敌人的生命成长
- `enemy_flat_health_every_levels`：每隔多少级给敌人额外加一次固定生命
- `coin_drop_chance`：击败敌人后补金币概率

也可以直接在 `scripts/Main.gd` 顶部修改这些 `@export` 变量默认值。

打开 `scenes/Main.tscn`，选中 `WeaponController` 节点，可以调：

- `base_fire_interval`：基础射击间隔
- `base_projectile_speed`：基础子弹速度
- `base_damage`：基础伤害
- `base_pierce`：基础穿透
- `base_projectile_count`：基础子弹数量
- `base_projectile_scale`：基础子弹大小
- `quick_cast_reduce_percent`：疾速施法减少的射击间隔百分比
- `heavy_bolt_damage_bonus`：重击魔弹增加的伤害
- `split_bolt_count_bonus`：分裂魔弹增加的弹数
- `piercing_bolt_bonus`：穿透魔弹增加的穿透数
- `swift_bolt_speed_bonus`：迅捷魔弹增加的弹速
- `large_bolt_scale_bonus_percent`：巨型魔弹增加的尺寸百分比

## 运行

1. 用 Godot 4.x 打开 `E:\Privy\Gold Rush`。
2. 确认主场景是 `res://scenes/Main.tscn`。
3. 点击右上角运行按钮，或按 F5。
4. WASD / 方向键移动，碰金币加分，碰敌人结束，按 R 重新开始。
5. 分数达到升级阈值后，用鼠标点击 3 个武器升级中的 1 个。

## 调试

- 想看碰撞范围：运行时打开 Debug 菜单里的 Visible Collision Shapes。
- 想降低难度：降低 `enemy_speed` 或调大 `enemy_spawn_interval`。
- 想提高金币密度：调小 `coin_spawn_interval` 或调大 `max_coins`。
- 想更快触发 Roguelike 选择：调小 `first_upgrade_score` 或 `upgrade_score_step_growth`。
- 想看武器是否命中：打开 Debug 菜单里的 Visible Collision Shapes。
- 想检查信号：在 `Main.gd` 的 `_on_coin_collected()` 和 `_on_player_hit()` 中加 `print()`。

## 扩展方向

- 增加生命值：把一次碰撞游戏结束改成扣血，UI 显示生命值。
- 增加道具：新增 `PowerUp.tscn`，碰到后临时加速或清屏。
- 增加关卡节奏：根据 `score` 提高 `enemy_speed` 或缩短 `enemy_spawn_interval`。
- 增加音效：在金币和敌人碰撞时播放 `AudioStreamPlayer2D`。
- 增加菜单：做 `StartMenu.tscn`，点击开始后切换到 `Main.tscn`。
- 增加新武器：复制 `WeaponController.gd` 里的升级写法，添加新的 `upgrade_id` 和 `match` 分支。
- 增加新敌人：添加新的 SVG，并在 `Main.gd` 的 `_pick_enemy_data()` 里加入新的类型配置。
