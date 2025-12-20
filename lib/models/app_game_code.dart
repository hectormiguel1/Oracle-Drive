import 'package:oracle_drive/src/third_party/wbtlib/wbt.g.dart' as wbt_native;
import 'package:oracle_drive/src/third_party/ztrlib/ztr.g.dart' as ztr_native;

enum AppGameCode {
  ff13_1(0, 'FINAL FANTASY XIII'),
  ff13_2(1, 'FINAL FANTASY XIII-2'),
  // ignore: constant_identifier_names
  ff13_lr(2, 'LIGHTNING RETURNS FFXIII');

  final int idx;
  final String displayName;

  const AppGameCode(this.idx, this.displayName);

  // Convert to wbt_native.GameCode
  wbt_native.GameCode? toWbtGameCode() {
    switch (this) {
      case AppGameCode.ff13_1:
        return wbt_native.GameCode.FF131;
      case AppGameCode.ff13_2:
      case AppGameCode
          .ff13_lr: // Assuming WBT treats LR as FF13-2, or doesn't support LR specifically
        return wbt_native.GameCode.FF132;
    }
  }

  // Convert to ztr_native.ZTRGameCode
  ztr_native.ZTRGameCode toZtrGameCode() {
    switch (this) {
      case AppGameCode.ff13_1:
        return ztr_native.ZTRGameCode.ZTR_GAME_FF13_1;
      case AppGameCode.ff13_2:
        return ztr_native.ZTRGameCode.ZTR_GAME_FF13_2;
      case AppGameCode.ff13_lr:
        return ztr_native.ZTRGameCode.ZTR_GAME_FF13_3;
    }
  }

  // Convert to database game index (assuming 0, 1, 2)
  int toDbGameIndex() {
    return index;
  }
}
