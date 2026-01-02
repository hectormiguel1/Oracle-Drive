import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:oracle_drive/src/isar/settings/settings_models.dart';
import 'package:oracle_drive/src/isar/settings/settings_repository.dart';
import 'package:oracle_drive/src/services/app_database.dart';

/// Provider for the settings repository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return AppDatabase.instance.settingsRepository;
});

/// Provider for whether journaling is enabled.
final journalEnabledProvider = StateProvider<bool>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return settings.isJournalEnabled();
});

/// Provider for the journal retention mode.
final journalRetentionModeProvider = StateProvider<JournalRetentionMode>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return settings.getJournalRetentionMode();
});

/// Provider for the journal retention days.
final journalRetentionDaysProvider = StateProvider<int>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return settings.getJournalRetentionDays();
});

/// Provider for the journal retention count.
final journalRetentionCountProvider = StateProvider<int>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return settings.getJournalRetentionCount();
});

/// Provider for the default FF13 workspace path.
final defaultWorkspaceFf13Provider = StateProvider<String?>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return settings.getDefaultWorkspace(0);
});

/// Provider for the default FF13-2 workspace path.
final defaultWorkspaceFf132Provider = StateProvider<String?>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return settings.getDefaultWorkspace(1);
});

/// Provider for the default FF13-LR workspace path.
final defaultWorkspaceFf13LrProvider = StateProvider<String?>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return settings.getDefaultWorkspace(2);
});

/// Notifier for managing settings state.
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final Ref _ref;

  SettingsNotifier(this._repository, this._ref)
      : super(SettingsState.initial()) {
    // Load initial state from database
    reload();
  }

  /// Set whether journaling is enabled.
  void setJournalEnabled(bool enabled) {
    _repository.setJournalEnabled(enabled);
    _ref.read(journalEnabledProvider.notifier).state = enabled;
    state = state.copyWith(journalEnabled: enabled);
  }

  /// Set the journal retention mode.
  void setJournalRetentionMode(JournalRetentionMode mode) {
    _repository.setJournalRetentionMode(mode);
    _ref.read(journalRetentionModeProvider.notifier).state = mode;
    state = state.copyWith(retentionMode: mode);
  }

  /// Set the journal retention days.
  void setJournalRetentionDays(int days) {
    _repository.setJournalRetentionDays(days);
    _ref.read(journalRetentionDaysProvider.notifier).state = days;
    state = state.copyWith(retentionDays: days);
  }

  /// Set the journal retention count.
  void setJournalRetentionCount(int count) {
    _repository.setJournalRetentionCount(count);
    _ref.read(journalRetentionCountProvider.notifier).state = count;
    state = state.copyWith(retentionCount: count);
  }

  /// Set the default workspace for a game.
  void setDefaultWorkspace(int gameCode, String? path) {
    _repository.setDefaultWorkspace(gameCode, path);
    switch (gameCode) {
      case 0:
        _ref.read(defaultWorkspaceFf13Provider.notifier).state = path;
        state = state._copyWithWorkspace(
          defaultWorkspaceFf13: path,
          clearFf13: path == null,
        );
        break;
      case 1:
        _ref.read(defaultWorkspaceFf132Provider.notifier).state = path;
        state = state._copyWithWorkspace(
          defaultWorkspaceFf132: path,
          clearFf132: path == null,
        );
        break;
      case 2:
        _ref.read(defaultWorkspaceFf13LrProvider.notifier).state = path;
        state = state._copyWithWorkspace(
          defaultWorkspaceFf13Lr: path,
          clearFf13Lr: path == null,
        );
        break;
    }
  }

  /// Reload settings from the database.
  void reload() {
    state = SettingsState(
      journalEnabled: _repository.isJournalEnabled(),
      retentionMode: _repository.getJournalRetentionMode(),
      retentionDays: _repository.getJournalRetentionDays(),
      retentionCount: _repository.getJournalRetentionCount(),
      defaultWorkspaceFf13: _repository.getDefaultWorkspace(0),
      defaultWorkspaceFf132: _repository.getDefaultWorkspace(1),
      defaultWorkspaceFf13Lr: _repository.getDefaultWorkspace(2),
    );
  }
}

/// State class for settings.
class SettingsState {
  final bool journalEnabled;
  final JournalRetentionMode retentionMode;
  final int retentionDays;
  final int retentionCount;
  final String? defaultWorkspaceFf13;
  final String? defaultWorkspaceFf132;
  final String? defaultWorkspaceFf13Lr;

  const SettingsState({
    required this.journalEnabled,
    required this.retentionMode,
    required this.retentionDays,
    required this.retentionCount,
    this.defaultWorkspaceFf13,
    this.defaultWorkspaceFf132,
    this.defaultWorkspaceFf13Lr,
  });

  factory SettingsState.initial() => const SettingsState(
        journalEnabled: true,
        retentionMode: JournalRetentionMode.unlimited,
        retentionDays: 30,
        retentionCount: 1000,
      );

  SettingsState copyWith({
    bool? journalEnabled,
    JournalRetentionMode? retentionMode,
    int? retentionDays,
    int? retentionCount,
    String? defaultWorkspaceFf13,
    String? defaultWorkspaceFf132,
    String? defaultWorkspaceFf13Lr,
  }) {
    return SettingsState(
      journalEnabled: journalEnabled ?? this.journalEnabled,
      retentionMode: retentionMode ?? this.retentionMode,
      retentionDays: retentionDays ?? this.retentionDays,
      retentionCount: retentionCount ?? this.retentionCount,
      defaultWorkspaceFf13: defaultWorkspaceFf13 ?? this.defaultWorkspaceFf13,
      defaultWorkspaceFf132: defaultWorkspaceFf132 ?? this.defaultWorkspaceFf132,
      defaultWorkspaceFf13Lr: defaultWorkspaceFf13Lr ?? this.defaultWorkspaceFf13Lr,
    );
  }

  /// Copy with workspace that allows setting null values explicitly.
  SettingsState _copyWithWorkspace({
    String? defaultWorkspaceFf13,
    String? defaultWorkspaceFf132,
    String? defaultWorkspaceFf13Lr,
    bool clearFf13 = false,
    bool clearFf132 = false,
    bool clearFf13Lr = false,
  }) {
    return SettingsState(
      journalEnabled: journalEnabled,
      retentionMode: retentionMode,
      retentionDays: retentionDays,
      retentionCount: retentionCount,
      defaultWorkspaceFf13: clearFf13 ? null : (defaultWorkspaceFf13 ?? this.defaultWorkspaceFf13),
      defaultWorkspaceFf132: clearFf132 ? null : (defaultWorkspaceFf132 ?? this.defaultWorkspaceFf132),
      defaultWorkspaceFf13Lr: clearFf13Lr ? null : (defaultWorkspaceFf13Lr ?? this.defaultWorkspaceFf13Lr),
    );
  }
}

/// Provider for the settings notifier.
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repository = ref.read(settingsRepositoryProvider);
  return SettingsNotifier(repository, ref);
});
