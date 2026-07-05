# CLAUDE.md — day_cap

**อ่าน [PROJECT_CHARTER.md](PROJECT_CHARTER.md) ก่อนเริ่มงานเสมอ** — เป็น living document ที่อธิบายโปรเจกต์นี้ครบ
(Business / Experience / Technical) ให้ continue งานต่อได้ทันที. รายละเอียดเชิงลึก/ประวัติ: [PLAN.md](PLAN.md)

## กติกาสำคัญ (ห้ามพลาด)
- **อัปเดต PROJECT_CHARTER.md เมื่อมีการเปลี่ยนแปลงที่กระทบข้อมูลในนั้น** (roadmap, ฟีเจอร์, โครงสร้าง, สแตก, ดีไซน์)
  — แก้เฉพาะส่วนที่เกี่ยว + อัปเดต Last updated + Change Log. ไม่ต้องอัปเดตทุก commit
- **ห้าม `git push` เอง** ต้องให้ผู้ใช้เทสบนเครื่องก่อนเสมอ
- **ห้าม hardcode สี/ขนาด** ใช้ token จาก `lib/core/theme/` เท่านั้น (DS: amies_design_system)
- **Deploy iPhone ใช้ `flutter run --release`** (debug เด้ง). `flutter analyze` ต้องสะอาดก่อน deploy
