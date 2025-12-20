import 'package:ff13_mod_resource/models/app_game_code.dart';
import 'package:ff13_mod_resource/src/isar/generic_repository.dart';
import 'package:ff13_mod_resource/src/isar/common/schemas.dart'
    as common_schemas;
import 'package:isar_plus/isar_plus.dart';
import 'package:logging/logging.dart';
import 'package:ff13_mod_resource/src/isar/xiii/schemas.dart' as ff13_schemas;
import 'package:ff13_mod_resource/src/isar/xiii/repository.dart' as ff13_repo;
import 'package:ff13_mod_resource/src/isar/xiii-2/repository.dart'
    as ff13_2_repo;
import 'package:ff13_mod_resource/src/isar/xiii-lr/repository.dart'
    as ff13_lr_repo;

class AppDatabase {
  late final GameRepository _ff13Repository;
  late final GameRepository _ff132Repository;
  late final GameRepository _ff13LRRepository;
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

    // XIII
    final ff13Db = Isar.open(
      schemas: common_schemas.schemas + ff13_schemas.schemas,
      directory: dir,
      inspector: false,
      name: 'ff13',
    );
    _ff13Repository = ff13_repo.FF13Repository(ff13Db);

    // XIII-LR
    final ff13LrDb = Isar.open(
      schemas: common_schemas.schemas,
      directory: dir,
      inspector: false,
      name: 'ff13_lr',
    );
    _ff13LRRepository = ff13_lr_repo.FF13LRRepository(ff13LrDb);

    // XIII-2
    final ff132Db = Isar.open(
      schemas: common_schemas.schemas,
      directory: dir,
      inspector: false,
      name: 'ff13_2',
    );
    _ff132Repository = ff13_2_repo.FF132Repository(ff132Db);

    _initialized = true;
    _logger.info('Databases initialized.');
  }

  void close() {
    _ff13Repository.close();
    _ff13LRRepository.close();
    _ff132Repository.close();
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
}
