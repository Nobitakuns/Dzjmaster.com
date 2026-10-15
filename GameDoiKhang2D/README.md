# QUEENS OF BATTLE — 8 Nữ Võ Sĩ

Prototype game đối kháng 2D bằng **Godot 4.6.3 stable và GDScript**. Mở dự án này bằng Godot để chơi, không chạy qua trình duyệt. `project.godot` dùng Compatibility renderer, khung thiết kế 1920 × 1080, cửa sổ mặc định 1280 × 720 và physics 60 Hz. Mục tiêu là 60 FPS; hiệu năng trên MacBook M1 cần được đo trên máy thật.

Đây là thư mục dự án Godot độc lập. Trang web tĩnh ở thư mục gốc `Dzjmaster.com/` không bị thay đổi.

## APK Android

[Tải APK v0.3.0 trực tiếp từ GitHub](https://raw.githubusercontent.com/Nobitakuns/Dzjmaster.com/game-v0.3.0/downloads/Queens-of-Battle-Android-v0.3.0.apk). SHA-256: `c2d7fa7c0c995dde22d2c019c11779619636c0b0e016e0df0809565835acb23b`.

APK cài thử bản 0.3.0 nằm tại `build/queens-of-battle-v0.3.0-debug.apk` sau khi export. Đây là **bản debug có chữ ký debug**, dành cho cài trực tiếp và kiểm thử, chưa phải bản phát hành Google Play. APK dùng màn hình ngang, hỗ trợ thiết bị ARM 32/64-bit từ Android 7.0 (API 24). Trên điện thoại, chế độ **VS AI** dùng nút cảm ứng nhiều ngón: cụm di chuyển ở trái, đòn đánh/kỹ năng/đỡ ở phải, nút tạm dừng ở giữa phía dưới. Chế độ **LOCAL VS** trên Android cần bàn phím ngoài cho P2.

Để xuất lại từ máy đã cài Godot 4.6.3, Android SDK Platform 36, Build Tools 36.0.0 và OpenJDK 21, cấu hình đường dẫn Android SDK/Java trong Godot Editor Settings → Export → Android, cài export templates 4.6.3, rồi chạy trong thư mục dự án:

```bash
mkdir -p build
godot --headless --path . --editor --quit
godot --headless --path . --export-debug "Android Debug" build/queens-of-battle-v0.3.0-debug.apk
```

Chép APK sang điện thoại rồi mở tệp để cài, hoặc dùng Android Debug Bridge:

```bash
adb install -r build/queens-of-battle-v0.3.0-debug.apk
```

Nếu Android hỏi quyền cài từ nguồn này, hãy cấp quyền cho ứng dụng quản lý tệp đang mở APK. Icon launcher dùng ảnh `assets/icons/queen_arena_user.jpg` do người dùng cung cấp. Chưa kiểm thử trực tiếp trên thiết bị Android thật; kiểm thử cảm ứng hiện chạy bằng sự kiện mô phỏng trong Godot headless.

## Chạy trên macOS Apple Silicon

1. Cài **Godot 4.6.3 stable cho macOS** từ nguồn chính thức và giải nén `Godot.app` vào `/Applications` (hoặc mở app ở nơi bạn đã lưu).
2. Trong Godot Project Manager, chọn **Import**, trỏ đến `GameDoiKhang2D/project.godot`, rồi chọn **Edit**.
3. Nhấn **F6** để chạy scene đang mở hoặc **F5** để chạy game từ menu chính. Nếu được hỏi chọn main scene, chọn `scenes/core/game.tscn`.

Cách mở từ Terminal, khi `Godot.app` ở `/Applications`:

```bash
cd /duong/dan/den/Dzjmaster.com/GameDoiKhang2D
/Applications/Godot.app/Contents/MacOS/Godot --editor --path .
# Hoặc chạy game trực tiếp:
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Chọn **LOCAL VS** để hai người chơi chung bàn phím, hoặc **VS AI** để P1 đấu máy. Màn chọn nhân vật có tám thẻ; bấm chọn **P1** hoặc **P2** rồi bấm thẻ võ sĩ, sau đó chọn **BẮT ĐẦU TRẬN**. `Tab` đổi bên đang chọn; các phím mũi tên cũng duyệt thẻ. Mặc định P1 là Thanh Vân, P2 là Ngọc Vy.

## Điều khiển mặc định

| Hành động | P1 | P2 |
| --- | --- | --- |
| Di chuyển trái / phải | A / D | ← / → |
| Nhảy / ngồi | W / S | ↑ / ↓ |
| Đấm | J | 1 |
| Đá | K | 2 |
| Kỹ năng | L | 3 |
| Tuyệt kỹ | U | 4 |
| Đỡ đòn | I | 5 |
| Tạm dừng / tiếp tục | Esc | Esc |

P2 dùng **hàng số phía trên chữ cái**, không cần bàn phím số rời. Combo ba đòn là **J → K → J** cho P1, **1 → 2 → 1** cho P2: bấm đòn tiếp theo trong lúc đòn trước đang diễn ra; cancel chỉ xảy ra sau khi đòn trước trúng và tới cửa sổ cho phép. Đòn hụt không nối combo. Có thể đánh khi đang nhảy, nhưng hoạt ảnh tấn công trên không vẫn là hình tạm.

Menu **CÀI ĐẶT** cho phép đổi phím P1/P2 và đặt lại phím mặc định. Phím mới không được trùng với hành động khác. Binding được lưu ở `user://keybindings.json`. Menu này cũng chọn AI **Dễ / Thường / Khó**, bật **Giảm hiệu ứng** và chuyển **Toàn màn hình**; mức AI và Giảm hiệu ứng được lưu ở `user://game_settings.json`. `Esc` trong trận mở menu tạm dừng với Tiếp tục, Chơi lại round, Cài đặt, Chọn nhân vật và Menu chính.

## Luật trận và phần đã triển khai

- Mỗi võ sĩ có 2.000 HP và tối đa 100 năng lượng. Đòn đánh, đỡ đòn và sát thương dùng cùng logic cho người chơi và AI.
- Mỗi round kéo dài 99 giây. Hết HP là KO; hết giờ thì người còn nhiều HP hơn thắng. Nếu HP bằng nhau khi hết giờ, round hòa và được đánh lại, không cộng điểm. Ai thắng **hai round trước** thắng trận.
- Đấm, đá, đòn thứ ba trong combo, kỹ năng và tuyệt kỹ có dữ liệu startup / active / recovery, sát thương, tầm đánh, hit stun, block stun, knockback và cooldown trong `MoveData` / `MoveCatalog`.
- Kỹ năng cần **25 năng lượng** và có cooldown **210 physics frame**; tuyệt kỹ cần **100 năng lượng** và có cooldown **540 physics frame**. Năng lượng được giới hạn trong khoảng 0–100, nên không thể tung tuyệt kỹ liên tục.
- Fighter dùng `CharacterBody2D` và `CollisionShape2D` để va chạm thân; `Area2D` riêng cho hitbox và hurtbox. Có đỡ đòn giảm sát thương, counter hit, knockdown, get up, combo scaling, hit stop, hiệu ứng va chạm, rung camera và phần mở đầu ngắn khi kích hoạt tuyệt kỹ.
- Hiện có **một đấu trường** Neon Underground dùng tranh nền gốc cùng hiệu ứng nhẹ bằng Godot, sàn và biên va chạm. HUD có thanh máu đối xứng, chân dung, timer, điểm round và khung combo theo từng võ sĩ. Điều khiển Android dùng cụm hướng và nút tròn nhiều ngón. Âm thanh hit / block / skill / ultimate / KO là WAV tạo cho prototype.
- Tám võ sĩ đều có `FighterData` riêng, tên chiêu riêng và có thể chọn để đấu: Ngọc Vy, Mai Anh, Huyền Chi, Hồng Nhi, Bảo Châu, Tử Anh, Thanh Vân, Ánh Dương. Kỹ năng đặc biệt dùng các cơ chế như sóng bay, lao tới, vùng sát thương, dịch chuyển, sét, hồi máu hoặc ánh sáng; tuyệt kỹ dùng vùng/đường tấn công nhiều hit tùy nhân vật. Hai nhân vật mặc định Thanh Vân và Ngọc Vy là trọng tâm kiểm thử trận cơ bản.
- AI Dễ / Thường / Khó khác nhau về thời gian phản ứng, di chuyển, xác suất đỡ đòn, combo và quyết định dùng kỹ năng/tuyệt kỹ. AI phát ý định điều khiển vào cùng `Fighter` và vẫn chịu luật năng lượng, cooldown, hitbox và sát thương.

## Cấu trúc dự án

| Đường dẫn | Vai trò |
| --- | --- |
| `project.godot`, `scenes/core/` | Cấu hình engine và scene chính chuyển giữa menu, chọn võ sĩ, trận đấu |
| `scenes/main_menu/`, `scenes/character_select/`, `scenes/battle/` | Các scene giao diện và trận |
| `scripts/core/` | Điều phối game, round, camera, pause và InputMap |
| `scripts/fighters/`, `resources/fighter_data/` | Điều khiển võ sĩ, dữ liệu tám nhân vật, bộ hình tư thế chiến đấu |
| `scripts/combat/` | Dữ liệu đòn, hitbox của kỹ năng, VFX va chạm |
| `scripts/ai/`, `scripts/ui/`, `scripts/arena/` | AI, HUD / menu / settings, đấu trường |
| `assets/backgrounds/`, `assets/characters/` | Tranh nền menu/đấu trường, atlas chân dung và tám bộ hình tư thế |
| `assets/audio/`, `assets/fonts/` | SFX prototype và font Unicode tiếng Việt |
| `tests/` | Kiểm tra gameplay bằng Godot headless |

`FighterVisual` dùng atlas sáu tư thế có nền trong suốt cho từng võ sĩ: đứng, chạy, đấm, đá, đỡ, kỹ năng. Trạng thái combat chuyển hình đúng tư thế, có dao động nhẹ khi đứng/đi; các trạng thái khác hiện tái sử dụng tư thế gần nhất và biến đổi vị trí/góc. Đây **chưa phải animation nhiều frame cho mọi trạng thái**. Gốc hình vẫn ở chân nhân vật; hitbox và luật combat nằm riêng để có thể thay atlas bằng sprite/clip sản xuất hoàn chỉnh mà không đổi logic trận đấu.

## Kiểm tra bằng Godot headless

Chạy trong thư mục `GameDoiKhang2D`. Trên macOS, thay `godot` bằng `/Applications/Godot.app/Contents/MacOS/Godot` nếu chưa có lệnh trong `PATH`.

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_battle.gd
godot --headless --path . --script res://tests/test_roster.gd
godot --headless --path . --script res://tests/test_rules.gd
godot --headless --path . --script res://tests/test_navigation.gd
godot --headless --path . --script res://tests/test_touch_controls.gd
godot --headless --path . --script res://tests/test_android_battle.gd
```

`test_battle.gd` kiểm tra HP, mặt đất, di chuyển P1 độc lập, đòn hụt/trúng, block, năng lượng, kỹ năng Thanh Vân, điều kiện tuyệt kỹ, KO và kết thúc best of 3. `test_roster.gd` tạo trận cho từng võ sĩ và kiểm tra kỹ năng / tuyệt kỹ gây sát thương, năng lượng không vượt giới hạn và tuyệt kỹ tiêu năng lượng. `test_rules.gd` kiểm tra di chuyển P1/P2, va chạm thân, nhảy/tiếp đất, cancel combo, cooldown, round hòa, pause dừng timer và AI tiếp cận. `test_navigation.gd` kiểm tra luồng menu → chọn nhân vật → trận → pause / settings → menu. `test_touch_controls.gd` và `test_android_battle.gd` kiểm tra nhiều ngón cảm ứng và điều khiển nhân vật/nút pause trong trận. Các script trả mã lỗi khác 0 nếu có assertion thất bại. Cả sáu bài đã vượt qua trong môi trường Godot 4.6.3 headless; headless không thay thế việc kiểm tra hình ảnh, âm thanh và bàn phím trên macOS/Android.

### Checklist trên MacBook M1 thật

- [ ] Import project và F5 chạy không có lỗi parse trong Debugger.
- [ ] LOCAL VS: P1 và P2 di chuyển độc lập, nhảy, tiếp đất; hai thân không đi xuyên nhau.
- [ ] Đòn ở ngoài tầm không gây damage; đòn trong tầm trừ HP đúng một lần; block giảm damage.
- [ ] Thử J → K → J và 1 → 2 → 1; xem combo counter và damage tổng.
- [ ] Dùng kỹ năng của Thanh Vân và Ngọc Vy, kiểm tra hướng bay, cooldown và mức năng lượng; tuyệt kỹ chỉ chạy khi đủ 100.
- [ ] KO, hết giờ, hòa khi cùng HP, reset round và kết thúc trận sau hai round thắng.
- [ ] VS AI ở cả ba mức; AI không bị kẹt ở biên, có thể bị đánh và tiêu năng lượng theo luật.
- [ ] Esc tạm dừng thật; thử Tiếp tục, Chơi lại round, Chọn nhân vật, Menu chính.
- [ ] Đổi phím, khởi động lại game để kiểm tra binding được lưu; thử nhiều phím cùng lúc trên bàn phím MacBook.
- [ ] Kiểm tra giao diện tiếng Việt, SFX, fullscreen, giảm hiệu ứng, khung hình/độ trễ ở độ phân giải cửa sổ và Retina. Đo FPS trên M1; mục tiêu 60 FPS hiện chưa được xác nhận bằng máy thật.

## Ảnh tham chiếu và tài nguyên còn thiếu

Các JPG người dùng cung cấp là ảnh concept/giao diện tổng hợp, không có frame nhân vật độc lập đủ sạch để dùng trực tiếp làm sprite chiến đấu. Bản 0.3.0 tạo tranh mới theo phong cách tham chiếu: một atlas tám chân dung cho màn chọn/HUD, tám atlas sáu tư thế có alpha cho trận đấu, cùng tranh nền menu và đấu trường. Mỗi võ sĩ đổi tư thế theo trạng thái gameplay; phần mỹ thuật này **chưa tái tạo chính xác ảnh tham chiếu** và chưa có chuỗi frame đầy đủ cho từng animation. Ảnh concept gốc không được dùng làm sprite chuyển động.

Để đạt chất lượng hình ảnh như tham chiếu, cần cung cấp hoặc sản xuất:

1. **Frame animation bổ sung cho tám võ sĩ**: idle, đi tới/lùi, nhảy/rơi, ngồi, ba đòn đánh, skill, ultimate, nhận đòn, ngã/đứng dậy, thắng/thua. Atlas sáu tư thế hiện có là nền tảng mỹ thuật nhưng chưa cung cấp frame chuyển động đầy đủ. Mỗi bộ cần pivot ở chân và timing để căn hitbox.
2. **Icon chiêu thức riêng** cho từng võ sĩ và ảnh chân dung xuất riêng ở độ phân giải cao hơn nếu dùng cho màn hình Retina lớn.
3. **VFX riêng theo tám hệ**: bóng tối, lửa, huyết điệp không phản cảm, sakura, quang phổ, sấm sét, thánh quang, mặt trời; thêm hit sparks, projectile, hiệu ứng ultimate và các âm thanh tương ứng.
4. **Các arena còn lại** Sakura Temple, Thunder Palace và Solar Sanctuary; hiện chỉ một đấu trường chơi được với tranh nền và hạt cánh hoa nhẹ.

## Giới hạn và hướng phát triển

Đây vẫn là prototype gameplay với **một đấu trường chơi được**. Tranh nhân vật và giao diện đã được nâng cấp, nhưng animation đa frame, hit FX/ultimate điện ảnh và SFX chưa ở mức sản phẩm thương mại. Chưa có lựa chọn đấu trường, gamepad, bản build macOS phát hành, APK release ký bằng khóa phát hành hay bản iOS. **Chưa kiểm thử trực tiếp trên MacBook M1 hoặc điện thoại Android thật**, và chưa đo 60 FPS trên các thiết bị này. Bước tiếp theo là hoàn thiện frame animation, kiểm tra timing/hitbox theo hình mới, cân bằng combat và đo hiệu năng trên thiết bị thật.
