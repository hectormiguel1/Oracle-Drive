enum AppGameCode {
  ff13_1(0, 'FINAL FANTASY XIII'),
  ff13_2(1, 'FINAL FANTASY XIII-2'),
  // ignore: constant_identifier_names
  ff13_lr(2, 'LIGHTNING RETURNS FFXIII');

  final int idx;
  final String displayName;

  const AppGameCode(this.idx, this.displayName);

  // Convert to database game index (assuming 0, 1, 2)
  int toDbGameIndex() {
    return index;
  }
}
