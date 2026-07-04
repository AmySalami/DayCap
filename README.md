# day_cap 🎬

แอปบันทึกวิดีโอสั้นๆ ต่อกันเป็นคลิปยาวรายวัน — และ **ล้างทิ้งอัตโนมัติทุกสัปดาห์**
คอนเซ็ปต์: ไดอารี่วิดีโอรายสัปดาห์ที่หายไปเองเมื่อขึ้นสัปดาห์ใหม่ (คล้าย Setlog / 1 Second Everyday)

## ฟีเจอร์

- 📹 **กดปุ่มค้างเพื่อถ่าย** (ปล่อย = หยุด) แบบ IG Story ไม่จำกัดความยาว
- 🕐 ทุกคลิปติด **ป้ายเวลา** (ปัดลงเป็นชั่วโมง เช่น `10:00`)
- 🗂️ เก็บคลิป **ในแอป** (ไม่ลงอัลบั้มเครื่อง) แยกตามวัน (1 วัน = 1 รีล) ตัดวันที่เที่ยงคืน
- ▶️ **เล่นต่อเนื่อง** เป็นหนังเรื่องเดียว + ป้ายเวลาโชว์ทับ
- 📅 **ปฏิทิน 1 สัปดาห์** (อา.→ส.) กดดูย้อนหลังได้
- ✂️ **ตัดคลิป** ลากหัว-ท้ายแบบ IG (ตัดกลางไม่ได้) + จัดลำดับ + ลบ
- 💾 **Export** รวมคลิปทั้งวัน (เผาป้ายเวลา + pad ขอบดำตาม ratio คลิปแรก) → Save อัลบั้ม / แชร์ IG
- 🔥 **ล้างอัตโนมัติทุกอาทิตย์ 00:00** + นาฬิกานับถอยหลังตั้งแต่เสาร์ 20:00

> รายละเอียดการออกแบบทั้งหมดอยู่ใน [PLAN.md](PLAN.md)

## เทคโนโลยี

Flutter · Riverpod · camera · video_player · ffmpeg_kit_flutter_new (export) · gal (save) · share_plus

## โครงสร้าง

```
lib/
├── core/utils/time_utils.dart   # ตรรกะเวลา/สัปดาห์/countdown/wipe (มี unit test)
├── models/                      # Clip / DayLog / WeekLog (+ JSON)
├── services/                    # storage, repository, export(ffmpeg), gallery, share, text-overlay
├── providers/reel_provider.dart # Riverpod state
└── features/                    # record / player / calendar / edit(trim+timeline) / wipe
```

## การรัน

ต้องมี Flutter (stable) + สำหรับ iOS ต้องมี Xcode

```bash
flutter pub get
flutter run --release          # แนะนำ release สำหรับลง iPhone จริง (debug เปิดเองไม่ได้)
flutter test                   # รัน unit tests
```

> **iOS บนเครื่องจริง:** debug build ต้องเปิดผ่าน debugger เท่านั้น — ใช้ `--release` เพื่อให้แตะไอคอนเปิดเองได้

## สถานะ

ฟีเจอร์หลักครบ (record · persist · player · calendar · export/share · trim · weekly wipe)
เหลือ: local notification เตือนก่อนล้าง + เฟส UX/polish
