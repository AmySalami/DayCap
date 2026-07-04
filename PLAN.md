# day_cap — แผนงาน & โครงสร้างแอป

> แอปบันทึกวิดีโอสั้นๆ ต่อกันเป็นคลิปยาว รายวัน — และ **ล้างทิ้งอัตโนมัติทุกสัปดาห์**
> "Day Capture" — เก็บภาพแต่ละวันเป็นคลิปสั้นๆ ต่อเนื่อง ติดป้ายเวลา (ปัดลงเป็นชั่วโมง)
> คอนเซ็ปต์: บันทึกความทรงจำรายสัปดาห์ที่ **หายไปเองเมื่อขึ้นสัปดาห์ใหม่** — อยากเก็บต้อง Save ก่อนโดนล้าง

---

## 1. คอนเซ็ปต์ & Flow

```
เปิดแอป (หน้ากล้อง)
  → กดปุ่มถ่ายค้าง (ปล่อย = หยุด)  แบบ IG Story  [ไม่จำกัดความยาวคลิป]
  → คลิปเก็บ "ในแอป" (ไม่ลงอัลบั้ม) + ติดป้ายเวลา (HH:00)
  → คลิปใหม่ต่อท้ายคลิปเดิม "ของวันนั้น"
  → ข้ามเที่ยงคืน (00:00) = ขึ้นวันใหม่ คลิปใหม่ไปอยู่ Log ของวันถัดไป
  → กด Play  = เล่นคลิปของวันนั้นต่อเนื่อง พร้อมป้ายเวลา
  → Calendar (1 สัปดาห์ อา.→ส.) กดวันย้อนหลัง = เล่นวิดีโอวันนั้น
  → ตัดคลิปได้ (ลากหัว-ท้าย แบบ IG ตัดกลางไม่ได้)
  → กด Save = รวมคลิปวันนั้นเป็นไฟล์เดียว → ลงอัลบั้ม / แชร์ IG
  → *** ทุกต้นสัปดาห์ใหม่ (อา. 00:00) ล้าง Log ทั้งหมดทิ้ง ***
     ส. 20:00 เป็นต้นไป โชว์นาฬิกานับถอยหลังแบบ realtime จนถึงเวลาล้าง
```

### โครงสร้างเวลา
- **สัปดาห์** = อาทิตย์ → เสาร์ (Sun–Sat)
- **วัน** = 1 Log / 1 รีล (คลิปหลายอันต่อกัน)
- **คลิป** = 1 ครั้งที่กดถ่าย
- ขอบเขตวันตัดที่ **00:00** — ถ่ายคร่อมเที่ยงคืน คลิปใหม่นับเป็นวันถัดไป

### กฎป้ายเวลา (Text overlay)
- ป้าย = เวลาเริ่มถ่าย **ปัดลงเป็นชั่วโมง**: `10:01 → 10:00`, `12:58 → 12:00`
- **โชว์แค่เวลา** (ไม่มีวันที่)
- เก็บเป็น metadata → โชว์ตอนเล่นด้วย widget, **เผาลงไฟล์จริงตอน Export เท่านั้น**

### อัตราส่วนวิดีโอ (Aspect ratio)
- รับได้ทั้ง **แนวตั้ง & แนวนอน**
- **ยึด ratio ตามคลิปแรกของวันนั้น** → คลิปถัดไปที่ ratio ต่างจะถูก fit ให้พอดี (ค่าเริ่มต้น: pad/letterbox กันเนื้อหาหาย)

### การตัดคลิป (Trim — แบบ IG)
- ลาก **หัว/ท้าย** เข้า-ออกเพื่อย่อ/ขยายช่วงที่เล่น
- **ตัดกลางไม่ได้** — ทำได้แค่ trim ปลายทั้งสองด้าน
- ลบทั้งคลิปได้

---

## 2. ⭐ ระบบล้างรายสัปดาห์ (Weekly Auto-Wipe) — หัวใจของแอป

| เวลา | เหตุการณ์ |
|---|---|
| ส. ก่อน 20:00 | ใช้งานปกติ |
| **ส. 20:00 → อา. 00:00** | โชว์นาฬิกานับถอยหลัง realtime "Log จะถูกล้างใน XX นาที" (4 ชม. = 240 นาที) |
| **อา. 00:00** | ล้าง Log ทั้งหมดของสัปดาห์ที่ผ่านมา (ไฟล์คลิป + metadata) เริ่มสัปดาห์ใหม่ว่างเปล่า |

- ล้างเฉพาะ **คลิปในแอป** — วิดีโอที่ **Save ลงอัลบั้มไปแล้วปลอดภัย** (อยู่ในเครื่องแล้ว)
- **ข้อควรระวังทางเทคนิค:** iOS/Android จำกัดการรันเบื้องหลัง การล้างตรงเป๊ะตอน อา. 00:00 ทำได้แบบ *best-effort* (BGTaskScheduler / WorkManager + local notification)
  - **การันตี:** เช็ก + ล้างทุกครั้งที่ "เปิดแอป" — ถ้าเปิดมาแล้วอยู่คนละสัปดาห์กับข้อมูลที่เก็บไว้ → ล้างทันที
  - นาฬิกานับถอยหลังทำงาน realtime "ระหว่างเปิดแอป"

---

## 3. เทคโนโลยี (Flutter)

| ความสามารถ | Package / วิธี | หมายเหตุ |
|---|---|---|
| ถ่ายวิดีโอ (กดค้าง) | `camera` | บันทึกลงโฟลเดอร์ในแอป |
| ที่เก็บไฟล์ในแอป | `path_provider` | App Documents Dir (ไม่โผล่ในอัลบั้ม) |
| เก็บ metadata | `hive` | โครงสร้าง Week → Day → Clip |
| เล่นวิดีโอ | `video_player` | เล่นต่อเนื่องเป็น playlist |
| รวม+เผาข้อความ+fit ratio+Export | `ffmpeg_kit_flutter_new`* | concat + **overlay PNG** + scale/pad → mp4 |
| Save ลงอัลบั้ม | `gal` | |
| แชร์ IG | `share_plus` | share sheet → Instagram |
| Trim หัว-ท้าย | `ffmpeg` trim หรือ `video_trimmer` | |
| นับถอยหลัง / เตือนล้าง | `flutter_local_notifications` + timer | |
| งานเบื้องหลัง (best-effort wipe) | `workmanager` | |
| State | `flutter_riverpod` | |

> **\* ความเสี่ยงสูงสุด:** `ffmpeg_kit_flutter` เดิมถูก retire (ม.ค. 2025) ถอน binary ออกแล้ว → ใช้ fork `ffmpeg_kit_flutter_new` (resolve ผ่านแล้ว ✅)
>
> **การตัดสินใจ — เผาข้อความด้วย overlay PNG (ไม่ใช้ drawtext):** เรนเดอร์ข้อความ `HH:00` จาก Flutter เป็น PNG โปร่งใส แล้วให้ ffmpeg ใช้ฟิลเตอร์ `overlay` ซ้อนทับ — เพราะ `drawtext` ต้องการ ffmpeg build ที่มี freetype/fontconfig (ไม่มีในทุก build) แต่ `overlay` มีในทุก build → robust กว่า + คุมฟอนต์/ภาษาไทย/สไตล์ได้เต็มที่จากฝั่ง Flutter

---

## 4. Data Model

```dart
class Clip {
  String id;             // uuid
  String fileName;       // path แบบ relative
  DateTime recordedAt;   // เวลาเริ่มถ่ายจริง
  String hourLabel;      // "10:00" (ปัดลงชั่วโมง)
  int durationMs;
  int orderIndex;        // ลำดับต่อคลิปในวัน
  int trimStartMs;       // จุดตัดหัว (default 0)
  int trimEndMs;         // จุดตัดท้าย (default = durationMs)
}

class DayLog {
  DateTime day;          // 00:00 ของวันนั้น
  String? aspectRatio;   // ratio ที่ล็อกจากคลิปแรก เช่น "9:16"
  List<Clip> clips;      // เรียงตาม orderIndex
}

class WeekLog {
  DateTime weekStart;    // อาทิตย์ 00:00 — ใช้เช็คว่าถึงเวลาล้างหรือยัง
  List<DayLog> days;     // สูงสุด 7 วัน (อา.→ส.)
}
```

**ฟังก์ชันเวลา:**
```dart
String hourLabel(DateTime dt) => '${dt.hour.toString().padLeft(2, "0")}:00';
DateTime weekStart(DateTime dt) => /* ย้อนไปวันอาทิตย์ 00:00 */;
bool shouldWipe(DateTime now, DateTime storedWeekStart) =>
    weekStart(now).isAfter(storedWeekStart);
```

**การเก็บไฟล์:** `<AppDocuments>/clips/<uuid>.mp4` — ไม่เรียก gallery API ตอนถ่าย → ไม่โผล่ในอัลบั้ม

---

## 5. โครงสร้างโฟลเดอร์ (lib/)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/app_theme.dart
│   └── utils/time_utils.dart        # hourLabel(), weekStart(), shouldWipe()
├── models/
│   ├── clip.dart
│   ├── day_log.dart
│   └── week_log.dart
├── services/
│   ├── storage_service.dart         # path_provider, จัดการไฟล์
│   ├── clip_repository.dart         # Hive: บันทึก/อ่าน/ลบ
│   ├── wipe_service.dart            # เช็ค+ล้างรายสัปดาห์, countdown
│   ├── export_service.dart          # ffmpeg: concat+drawtext+pad → mp4
│   ├── gallery_service.dart         # gal: save
│   └── share_service.dart           # share_plus
├── features/
│   ├── record/
│   │   ├── record_screen.dart       # กล้อง + ปุ่มกดค้าง + countdown banner
│   │   └── widgets/hold_button.dart
│   ├── calendar/
│   │   └── week_calendar_screen.dart # 1 สัปดาห์ อา.→ส. กดวัน→เล่น
│   ├── player/
│   │   └── player_screen.dart       # เล่นต่อเนื่อง + ป้ายเวลา + Save/Share
│   └── edit/
│       ├── timeline_screen.dart     # ลิสต์คลิปในวัน (ลบ/จัดลำดับ)
│       └── trim_screen.dart         # ลากหัว-ท้าย
└── providers/
    ├── reel_provider.dart
    └── wipe_provider.dart           # countdown state
```

---

## 6. หน้าจอหลัก

1. **Record** (หน้าแรก) — กล้องเต็มจอ + ปุ่มกดค้าง + ป้ายเวลาปัจจุบัน + แบนเนอร์นับถอยหลัง (เสาร์เย็น)
2. **Week Calendar** — แถบ 1 สัปดาห์ (อา.→ส.) วันที่มีคลิปกดดูได้ → เข้า Player
3. **Player** — เล่นคลิปของวันนั้นต่อเนื่อง + ป้ายเวลาทับ + ปุ่ม Save / Share
4. **Timeline** — ลิสต์คลิปในวัน: ลบ, จัดลำดับ, เข้าหน้า Trim
5. **Trim** — ลากหัว-ท้ายย่อ/ขยาย (ตัดกลางไม่ได้)

---

## 7. แผนการลงมือ (Milestones)

| # | งาน | สถานะ |
|---|---|---|
| **0. Spike** | ffmpeg บิลด์+ลิงก์บน iOS ผ่าน (fork ใหม่) | ✅ |
| **1. Setup** | โปรเจกต์ + packages + permission (กล้อง/ไมค์/อัลบั้ม) | ✅ |
| **2. Record** | กล้อง + ปุ่มกดค้าง → ไฟล์ + metadata + ล็อก ratio จากคลิปแรก | ✅ |
| **3. Persist** | JSON Week→Day→Clip, รอดหลังปิดแอป, แยกวันที่ 00:00 | ✅ |
| **4. Player** | เล่นต่อเนื่อง + ป้ายเวลา (เคารพ trim) | ✅ |
| **5. Calendar** | แถบสัปดาห์ อา.→ส. กดวันย้อนหลังเล่นได้ | ✅ |
| **6. Wipe** | ✅ ล้างตอนเปิดแอป · ⬜ countdown UI + notification | กำลังทำ |
| **7. Export/Save** | รวม + overlay ป้ายเวลา + pad ratio → save อัลบั้ม | ✅ เทสผ่านบนเครื่อง |
| **8. Share** | share_plus → IG/แอปอื่น | ✅ |
| **9. Trim** | หน้า UI ลากหัว-ท้าย + จัดการ/ลบ/จัดลำดับ | ✅ เทสผ่านบนเครื่อง |

> หมายเหตุ: เก็บ metadata เป็น **JSON file** (ไม่ใช้ Hive) เพื่อลด codegen — เข้ากับโมเดล wipe (ลบไฟล์) ได้ดี
> ป้ายเวลา trim: `Clip.trimStartMs/trimEndMs` + `ReelController.updateTrim()` พร้อมใช้แล้ว เหลือแค่หน้า UI

---

## 8. ข้อสรุปที่ล็อกแล้ว ✅

- [x] เวลาล้าง = **อาทิตย์ 00:00** (countdown ส. 20:00 → อา. 00:00 = 240 นาที)
- [x] Countdown แสดงเป็น **HH:MM realtime** สไตล์ Duolingo (เช่น `03:59`)
- [x] คลิป ratio ต่างจากคลิปแรก → **pad ขอบดำ** (letterbox/pillarbox)
- [x] Save = **รวมทั้งวันเป็นไฟล์เดียว** เท่านั้น
- [x] ป้ายเวลา: โชว์แค่เวลา `HH:00`
- [x] Platform: Flutter (เริ่ม iOS ก่อน — เครื่องพร้อม)
```

