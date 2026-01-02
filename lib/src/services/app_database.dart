import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/src/isar/generic_repository.dart';
import 'package:oracle_drive/src/isar/common/common_repository.dart';
import 'package:oracle_drive/src/isar/common/schemas.dart' as common_schemas;
import 'package:oracle_drive/src/isar/journal/journal_models.dart';
import 'package:oracle_drive/src/isar/journal/journal_repository.dart';
import 'package:oracle_drive/src/isar/settings/settings_models.dart';
import 'package:oracle_drive/src/isar/settings/settings_repository.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:logging/logging.dart';

class AppDatabase {
  late final GameRepository _ff13Repository;
  late final GameRepository _ff132Repository;
  late final GameRepository _ff13LRRepository;

  // Central database for journal and settings
  late final Isar _centralDb;
  late final JournalRepository _journalRepository;
  late final SettingsRepository _settingsRepository;

  final Logger _logger = Logger('AppDatabase');
  bool _initialized = false;
  static AppDatabase? _instance;

  static AppDatabase get instance {
    if (_instance == null || !_instance!.isInitialized) {
      _instance = AppDatabase._internal();
      _instance!._init();
    }
    return _instance!;
  }

  AppDatabase._internal();

  static Future<void> ensureInitialized() async {
    if (_instance == null || !_instance!.isInitialized) {
      _instance = AppDatabase._internal();
      _instance!._init();
    }
  }

  bool get isInitialized => _initialized;

  void _init() {
    _logger.info('Initializing databases...');
    final dir = './';

    // All games use the same schema (Strings + EntityLookup)
    final schemas = common_schemas.schemas;

    // XIII
    final ff13Db = Isar.open(
      schemas: schemas,
      directory: dir,
      inspector: false,
      name: 'ff13',
    );
    _ff13Repository = CommonGameRepository(ff13Db, 'FF13');

    // XIII-LR
    final ff13LrDb = Isar.open(
      schemas: schemas,
      directory: dir,
      inspector: false,
      name: 'ff13_lr',
    );
    _ff13LRRepository = CommonGameRepository(ff13LrDb, 'FF13LR');

    // XIII-2
    final ff132Db = Isar.open(
      schemas: schemas,
      directory: dir,
      inspector: false,
      name: 'ff13_2',
    );
    _ff132Repository = CommonGameRepository(ff132Db, 'FF132');

    // Central database for journal and settings
    final centralSchemas = [
      JournalEntrySchema,
      AppSettingsSchema,
    ];
    _centralDb = Isar.open(
      schemas: centralSchemas,
      directory: dir,
      inspector: false,
      name: 'oracle_drive_central',
    );
    _journalRepository = JournalRepository(_centralDb);
    _settingsRepository = SettingsRepository(_centralDb);

    // Initialize default settings if first run
    _settingsRepository.initializeDefaults();

    _initialized = true;
    _logger.info('Databases initialized.');
  }

  void close() {
    _ff13Repository.close();
    _ff13LRRepository.close();
    _ff132Repository.close();
    _centralDb.close();
  }

  GameRepository getRepositoryForGame(AppGameCode gameCode) {
    switch (gameCode) {
      case AppGameCode.ff13_1:
        return _ff13Repository;
      case AppGameCode.ff13_lr:
        return _ff13LRRepository;
      case AppGameCode.ff13_2:
        return _ff132Repository;
    }
  }

  /// Get the journal repository for recording and querying changes.
  JournalRepository get journalRepository => _journalRepository;

  /// Get the settings repository for app-wide configuration.
  SettingsRepository get settingsRepository => _settingsRepository;

  /// Get the central Isar database instance (for advanced queries).
  Isar get centralDb => _centralDb;
}
