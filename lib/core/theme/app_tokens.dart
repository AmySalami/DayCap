import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Token เฉพาะแอป day_cap — ของที่ DS กลางไม่มี (เพราะเป็น context วิดีโอเต็มจอ)
/// ยังคงเป็น "token เท่านั้น" อ้างอิง [DsColor] ที่ทำได้ ห้าม hardcode ในวิดเจ็ต
class AppToken {
  const AppToken._();

  // การ์ดกระจกฝ้าบนวิดีโอ (Adjust zone)
  static const glassFill = Color.fromRGBO(255, 255, 255, .14);
  static const glassBorder = Color.fromRGBO(255, 255, 255, .28);

  // ฉากมืดไล่เฉดบนวิดีโอ ให้อ่าน UI ออก
  static const scrimTop = Color.fromRGBO(0, 0, 0, .45);
  static const scrimBottom = Color.fromRGBO(0, 0, 0, .66);

  // progress bar (IG story) บนวิดีโอ
  static const progressTrack = DsColor.whiteFaint;
  static const progressFill = DsColor.white;

  // สีเตือน countdown — ใช้ accent (amber) ตามกติกา DS (พื้น accent + ตัวอักษร secondary)
  static const alertFill = DsColor.accent;
  static const alertText = DsColor.secondary;

  // gradient หน้า empty (พื้นจอวันที่ไม่มีคลิป) — ใช้โทน DS
  static const emptyGradient = [DsColor.secondary, DsColor.ink];

  // พื้นหลังดำสนิทสำหรับวิดีโอ (letterbox/ช่วงสลับคลิป) — เฉพาะแอปวิดีโอ
  static const videoBackdrop = Color(0xFF000000);

  // ที่จับลาก (drag handle) บน Adjust zone
  static const dragHandle = DsColor.whiteSoft;

  // พื้นป้ายเวลาที่ทับบนวิดีโอ (ให้อ่านออกทุกพื้นหลัง)
  static const badgeBg = Color.fromRGBO(0, 0, 0, .35);
  static const badgeText = DsColor.white;
}
