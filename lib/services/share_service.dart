import 'package:share_plus/share_plus.dart';

/// แชร์วิดีโอผ่าน share sheet (เลือก Instagram / แอปอื่นได้)
class ShareService {
  Future<void> shareVideo(String path) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'day_cap 🎬',
      ),
    );
  }
}
