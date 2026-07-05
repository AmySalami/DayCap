# day_cap — Project Charter

> **เอกสารนี้คืออะไร:** Living document สำหรับให้ AI/คนใหม่อ่านแล้วเข้าใจโปรเจกต์นี้ทั้งหมด
> และ **continue งานต่อได้ทันที** — บริบทธุรกิจ, ประสบการณ์ผู้ใช้, และเทคนิค
>
> **Status:** อยู่ระหว่างพัฒนา (เฟส UI redesign)
> **Last updated:** 2026-07-05
> **รายละเอียดเชิงลึก/ประวัติการตัดสินใจ:** ดู [PLAN.md](PLAN.md)

---

## 📌 วิธีดูแลเอกสารนี้ (อ่านก่อนแก้)

1. เอกสารนี้เป็น **living document** — อัปเดต **เฉพาะเมื่อมีการเปลี่ยนแปลงที่กระทบข้อมูลในนี้จริงๆ** (เปลี่ยน roadmap, เพิ่ม/ตัดฟีเจอร์, เปลี่ยนโครงสร้าง/สแตก/ดีไซน์) — ไม่ต้องอัปเดตทุก commit
2. **แก้เฉพาะส่วนที่เกี่ยวข้อง** ไม่ต้องเขียนใหม่ทั้ง doc เช่น เปลี่ยนเรื่อง tech ก็แก้แค่ส่วน Technical
3. อัปเดต `Last updated` และเพิ่มบรรทัดใน **Change Log** ท้ายเอกสารทุกครั้งที่แก้
4. 3 ส่วนหลัก = **Business / Experience / Technical** — วางข้อมูลให้ถูกส่วน

---

## 1. Business

### 1.1 มันคืออะไร
แอปมือถือบันทึกวิดีโอสั้นๆ ต่อกันเป็น "หนังประจำวัน" แล้ว **ล้างทิ้งอัตโนมัติทุกสัปดาห์**
เปรียบเป็น **ไดอารี่วิดีโอรายสัปดาห์ที่หายไปเอง** (คอนเซ็ปต์ใกล้เคียง Setlog / 1 Second Everyday แต่เพิ่มมิติ "ของหายรายสัปดาห์")

### 1.2 คุณค่า / จุดต่าง
- **ความ ephemeral + ความกดดันเชิงบวก:** ทุกอย่างถูกล้างเที่ยงคืนวันอาทิตย์ → อยากเก็บต้อง Save ก่อน
  → มี **นาฬิกานับถอยหลัง** ตั้งแต่เย็นวันเสาร์ เป็นตัวชูโรงกระตุ้นให้ใช้/เซฟ
- **แรงเสียดทานต่ำ:** เปิดแอปแล้วกดถ่ายค้างได้เลยแบบ IG Story ไม่ต้องคิดมาก
- บันทึก "ชีวิตแต่ละชั่วโมงของวัน" แบบเบาๆ (ป้ายเวลาปัดเป็นชั่วโมง)

### 1.3 กลุ่มผู้ใช้ / การใช้งาน
ผู้ใช้ทั่วไปที่อยากบันทึกความทรงจำรายวัน/สัปดาห์แบบสนุก ไม่เป็นภาระ แล้วเลือกเก็บ/แชร์เฉพาะที่ชอบ

### 1.4 เป้าหมายความสำเร็จ
- ผู้ใช้ถ่าย + เล่นดู + Save/แชร์ได้ครบวงจรบนเครื่องจริง — **บรรลุแล้ว** (เทสผ่าน iPhone)
- [TBD] ตัวชี้วัดเชิงธุรกิจ (retention/DAU) — ยังไม่กำหนด (ยังเป็น personal project)

### 1.5 ขอบเขต
- **In:** ถ่าย, เก็บในแอป, เล่นต่อเนื่อง, ปฏิทินสัปดาห์, ตัดคลิป, export รวมวัน, save/แชร์, wipe รายสัปดาห์
- **Out (ตอนนี้):** บัญชีผู้ใช้/คลาวด์/ซิงก์หลายเครื่อง, ฟิลเตอร์/สติกเกอร์, หลายรีลต่อวัน, เสียงเพลงประกอบ

---

## 2. Experience

### 2.1 คอนเซ็ปต์ UI ใหม่ (กำลังทำ) — "Home เดียว + สลับโหมดด้วย gesture"
```
  ● ● ● ○   ← progress dots แบบ IG (1 ช่อง/คลิป)
  วิดีโอเต็มจอ autoplay ต่อเนื่องทั้งวัน   ← swipe ซ้าย/ขวา = เปลี่ยนวัน
  ╭──── Adjust zone (การ์ด glass) ────╮
  │  ปฏิทิน 7 วัน (อา.→ส.)            │  ← swipe ลง = Edit mode
  ╰────────────────────────────────╯  ← swipe ขวา = โหมดถ่าย
```

### 2.2 Flow หลัก
เปิดแอป → Home เล่นวิดีโอวันนี้ → กดปุ่มถ่ายค้าง (ปล่อย=หยุด) แบบ IG Story → คลิปต่อท้ายวันนั้น
→ เลือกวันจากปฏิทิน/ปัดเปลี่ยนวัน → ตัดคลิป (ลากหัว-ท้ายแบบ IG) → Save รวมทั้งวันเป็นไฟล์เดียว → แชร์/ลงอัลบั้ม

### 2.3 กติกา UX ที่ตกลงแล้ว (สำคัญ — อย่าเปลี่ยนโดยไม่ถาม)
- **ป้ายเวลา** = **เวลาจริงที่เริ่มถ่าย HH:MM** (10:01 → "10:01", ไม่ปัด), โชว์แค่เวลา ไม่มีวันที่ — **แสดงทับบนวิดีโอเสมอ** (ทั้งบน Home และเผาลงไฟล์ตอน export)
- **1 วัน = 1 รีล/หนัง**, ตัดวันที่ **เที่ยงคืน 00:00**
- **สัปดาห์ = อาทิตย์→เสาร์**, ปฏิทินเรียง อา.→ส. — ปัดเปลี่ยนวันแบบ **clamp** (หยุดที่ขอบ ไม่วน)
- **Wipe:** ล้างทุกอาทิตย์ 00:00 (การันตีตอนเปิดแอป + สดถ้าเปิดค้าง), countdown เริ่มเสาร์ 20:00 แสดง **HH:MM:SS**
- **Aspect ratio:** ยึดตามคลิปแรกของวัน, คลิปอื่นที่ต่าง → **pad ขอบดำ** (ไม่ครอป)
- **Trim:** ลากหัว-ท้ายเท่านั้น (ตัดกลางไม่ได้), **non-destructive** (ไฟล์ไม่ถูกตัดจริง ยืดกลับได้)
- **ปุ่มถ่าย (Setlog style):** กดค้าง = อัดตามที่ค้าง · **แตะทีเดียว = อัด 3 วิ อัตโนมัติ** (ขั้นต่ำ 3 วิเสมอ) · ตอนอัดมีวงเส้น accent วิ่งรอบปุ่มเป็น indicator
- **Save:** รวมทั้งวันเป็นไฟล์เดียว, เผาป้ายเวลาลงวิดีโอตอน export

### 2.4 Design System
- ใช้ **Amie's Design System**: https://github.com/AmySalami/amies_design_system (source of truth)
- แบรนด์ 2 สี: **accent `#FFC400` (amber)** ใช้กับพื้น+ไอคอนเท่านั้น, **secondary `#1E3258` (navy)** ใช้กับตัวอักษร/ตัวอักษรบนพื้น amber
- โทนอื่น: paper/ink/line/sage, ฟอนต์ **Fraunces** (display) + **Hanken Grotesk** (body)
- สไตล์รวม: **สดใส เล่นสนุก**
- **กฎเหล็ก:** ใช้ **token เท่านั้น ห้าม hardcode สี/ขนาด** ในวิดเจ็ต (ดูส่วน Technical)

### 2.5 หน้าจอ/สถานะ
- **Home:** วิดีโอเต็มจอ autoplay + progress dots + ป้ายเวลา + ปุ่ม Share (ขวาบน) + Adjust zone (glass: ที่จับ + ปฏิทิน)
  - gesture: ปัดซ้าย/ขวา = เปลี่ยนวัน (clamp), ปัดซ้ายบนการ์ด = ถ่าย, ปัดลงบนการ์ด = **Edit mode (morph inline)**
  - Edit mode: **Timeline แถบเดียวรวมทุกคลิป** (filmstrip) — แตะเลือกคลิป, คลิปที่เลือกมีที่จับเหลือง trim + playhead, ลากที่จับซ้าย=ขอบซ้าย(ขอบขวานิ่ง แถบเลื่อนชดเชย)/ขวา=ขอบขวา, ลากพื้นที่ว่าง=เลื่อนแถบ, กดค้างลากลง=ลบ
- **Record:** กล้อง + กดค้าง/แตะถ่าย + back (เข้าจากปัดซ้าย) — เอาปุ่มปฏิทิน/เล่นออกแล้ว
- **หน้าจอเก่าถูกลบแล้ว:** Player / Calendar / Timeline / Trim (ยุบรวมเข้า Home หมด)

---

## 3. Technical

### 3.1 Stack
Flutter (stable) · **Riverpod 3** (state) · **camera** · **video_player** · **ffmpeg_kit_flutter_new** (export) ·
**gal** (save อัลบั้ม) · **share_plus** · **path_provider** · **google_fonts** (Fraunces/Hanken) · **uuid**
เก็บ metadata เป็น **ไฟล์ JSON** (ไม่ใช้ Hive — ลด codegen, เข้ากับโมเดล wipe = ลบไฟล์)

### 3.2 Data model (นิ่งแล้ว — มี unit test คุม)
- `Clip` (id, fileName, recordedAt, durationMs, orderIndex, trimStartMs/trimEndMs; `label` = ปัดชั่วโมง)
- `DayLog` (day, canvasWidth/Height = จากคลิปแรก, clips[])
- `WeekLog` (weekStartDate, days{}) ← ก้อนที่เก็บลง storage และถูก wipe รายสัปดาห์
- ตรรกะเวลา/wipe อยู่ที่ `lib/core/utils/time_utils.dart` (unit test: `test/time_utils_test.dart`, `test/models_test.dart`)

### 3.3 Design token system (สำคัญ — ห้าม hardcode)
- `lib/core/theme/design_tokens.dart` — **mirror ของ amies_design_system.css** (DsColor/DsRadius/DsSpace/DsElevation/DsType)
- `lib/core/theme/app_tokens.dart` — token เฉพาะแอปที่ DS ไม่มี (glass, scrim, video backdrop) — ยังเป็น token, อ้าง DS เมื่อทำได้
- `lib/core/theme/text_styles.dart` — `DsText` (Fraunces/Hanken)
- `lib/core/theme/app_theme.dart` — สร้าง ThemeData จาก token
- **เพิ่มค่าใหม่ต้องเป็น token เสมอ** ถ้า DS ไม่มีให้เพิ่มใน `app_tokens.dart`

### 3.4 โครงสร้างโฟลเดอร์
```
lib/
├── core/theme/     # design_tokens, app_tokens, text_styles, app_theme
├── core/utils/     # time_utils (+ tests)
├── models/         # clip, day_log, week_log
├── services/       # storage, clip_repository, export(ffmpeg), gallery, share, text_overlay
├── providers/      # reel_provider (Riverpod: reel/export/gallery/share)
└── features/
    ├── home/       # home_screen (รวม view + edit mode inline) + widgets (glass_card, story_progress_bar, week_calendar_strip)
    ├── edit/       # edit_widgets (Timeline แบบ IG + TrashDropZone)
    ├── record/     # record_screen + hold_button
    └── wipe/       # countdown_banner
    # core/widgets/time_badge.dart = ป้ายเวลา reusable
```

### 3.5 การตัดสินใจ/ข้อจำกัดเชิงเทคนิค (อย่าพลาดซ้ำ)
- **Export เผาข้อความด้วย overlay PNG (ไม่ใช้ ffmpeg drawtext)** — เรนเดอร์ป้ายเวลาเป็น PNG จาก Flutter แล้ว overlay (เลี่ยง freetype). Pipeline: trim → scale+pad → overlay → concat
- **ffmpeg:** ตัวเดิม retire แล้ว ใช้ fork `ffmpeg_kit_flutter_new` (resolve/build/link ผ่าน iOS)
- **Deploy iPhone ต้องใช้ `flutter run --release`** (debug เด้งเมื่อแตะไอคอนเอง). Team `SK38FYHUBN`, Apple ID ฟรี = ลิมิต 3 แอป/หมดอายุ 7 วัน. ดู memory `deploy-to-iphone`
- **Git:** ห้าม push เอง ต้องให้ผู้ใช้เทสก่อนเสมอ (memory `git-push-rule`). Remote: https://github.com/AmySalami/DayCap.git
- **iOS permission:** camera, microphone, photo-library-add, **photo-library (full)** — ขาด full แล้ว gal `toAlbum:true` จะทำแอปเด้ง
- **ภาพนิ่ง (กันสั่น):** เปิด video stabilization ของ iOS ผ่าน `camera` ≥0.12 (`getSupportedVideoStabilizationModes` + `setVideoStabilizationMode`) — เลือก **level1(standard, latency น้อยสุด)**→level2→level3 ที่รองรับ, try/catch กันเครื่องไม่รองรับ. **ใช้ OIS+EIS ของ Apple ไม่ได้เขียน algorithm เอง**. ⚠️ level2/level3 กันสั่นเยอะกว่าแต่ preview หน่วง (delay) — จึงใช้ level1
- **เสียง (ลด noise/ลม):** ใส่ ffmpeg audio filter `highpass=f=100,afftdn=nr=12` ตอน `trimGuardInPlace` (re-encode ทุกคลิปตอนอัดเสร็จ) → คลิปในแอป+ไฟล์ export สะอาดทั้งคู่. อยากแรงขึ้นค่อยขยับเป็น `arnndn`+โมเดล .rnnn

### 3.6 Roadmap / สถานะปัจจุบัน
| ส่วน | สถานะ |
|---|---|
| Data/logic + persist + wipe | ✅ (unit test ผ่าน) |
| Record · Player · Calendar · Trim · Export · Save · Share | ✅ เทสผ่านเครื่อง |
| Notification เตือนก่อน wipe | ⬜ ค้าง |
| **UI redesign เฟส A (design system/tokens)** | ✅ |
| **เฟส B (Home ใหม่: วิดีโอเต็มจอ + Adjust zone + calendar)** | ✅ |
| **เฟส C (gestures: เปลี่ยนวัน/ถ่าย/แก้ไข)** | ✅ |
| **เฟส D (Edit mode: Timeline IG + trim ที่จับเหลือง + drag-to-delete)** | ✅ |
| **เฟส E (Share บน Home + รื้อหน้าเก่า)** | 🔄 กำลังทำ (ยัง: countdown เข้าดีไซน์) |

### 3.7 วิธีรัน/เทส
```bash
flutter pub get
flutter test                                    # unit tests
flutter run --release -d <iphone-device-id>     # ลงเครื่องจริง (ต้อง release)
flutter analyze                                 # ต้องสะอาดก่อน deploy
```

---

## Change Log
| วันที่ | ส่วนที่แก้ | สรุปการเปลี่ยนแปลง |
|---|---|---|
| 2026-07-04 | (สร้างเอกสาร) | ตั้ง Project Charter ครั้งแรก — Business/Experience/Technical |
| 2026-07-04 | Experience | เปลี่ยนป้ายเวลาเป็นเวลาจริง HH:MM (เลิกปัดชั่วโมง) + แสดงทับบน Home เสมอ |
| 2026-07-04 | Experience | ปัดเปลี่ยนวัน = clamp (ไม่วน), countdown เพิ่มวินาที HH:MM:SS |
| 2026-07-04 | Exp/Tech | Edit mode inline (morph), Timeline IG + trim ที่จับเหลือง + drag-to-delete; ตัด guard เสียงหัว-ท้าย 0.15s ตอนอัด |
| 2026-07-04 | Exp/Tech | ลบหน้า Player/Calendar/Timeline/Trim, ย้าย Share มา Home ขวาบน, เอาปุ่มออกจาก Record/Adjust zone |
| 2026-07-05 | Exp/Tech | Timeline แถบเดียวรวมทุกคลิป (filmstrip) — GestureDetector เดียวคุม pan/trim/select ตามโซน (แก้ scroll ชนที่จับ) |
| 2026-07-05 | Experience | ปุ่มถ่าย: แตะ=อัด 3 วิ auto / กดค้าง=ตามที่ค้าง (ขั้นต่ำ 3 วิ) + วงเส้น accent วิ่งรอบปุ่มตอนอัด |
| 2026-07-05 | Technical | เปิด video stabilization (Apple OIS+EIS) ผ่าน camera plugin + ลด noise เสียงด้วย ffmpeg afftdn ตอน re-encode |
