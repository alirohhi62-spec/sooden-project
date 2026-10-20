// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  LocationDao? _locationDaoInstance;

  PlaceDao? _placeDaoInstance;

  DeviceDao? _deviceDaoInstance;

  ScenarioDao? _scenarioDaoInstance;

  ScenarioDetDao? _scenarioDetDaoInstance;

  LoggerDao? _loggerDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `locations` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT, `port` INTEGER, `panelWifiName` TEXT, `panelWifiPassword` TEXT, `mac` TEXT, `modemName` TEXT, `modemPassword` TEXT, `panelIpOnModem` TEXT, `staticIp` TEXT, `isSelected` INTEGER)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `places` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `locationId` INTEGER, `floor` TEXT, `code` TEXT, `name` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `devices` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `locationId` INTEGER, `floor` TEXT, `place` TEXT, `headline` TEXT, `code` TEXT, `name` TEXT, `value` TEXT, `secondValue` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `scenarios` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `locationId` INTEGER, `floor` TEXT, `place` TEXT, `name` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `scenario_det` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `scenarioId` INTEGER, `deviceId` INTEGER, `value` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `logger` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `time` TEXT, `className` TEXT, `methodName` TEXT, `value` TEXT)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  LocationDao get locationDao {
    return _locationDaoInstance ??= _$LocationDao(database, changeListener);
  }

  @override
  PlaceDao get placeDao {
    return _placeDaoInstance ??= _$PlaceDao(database, changeListener);
  }

  @override
  DeviceDao get deviceDao {
    return _deviceDaoInstance ??= _$DeviceDao(database, changeListener);
  }

  @override
  ScenarioDao get scenarioDao {
    return _scenarioDaoInstance ??= _$ScenarioDao(database, changeListener);
  }

  @override
  ScenarioDetDao get scenarioDetDao {
    return _scenarioDetDaoInstance ??=
        _$ScenarioDetDao(database, changeListener);
  }

  @override
  LoggerDao get loggerDao {
    return _loggerDaoInstance ??= _$LoggerDao(database, changeListener);
  }
}

class _$LocationDao extends LocationDao {
  _$LocationDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _locationInsertionAdapter = InsertionAdapter(
            database,
            'locations',
            (Location item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'port': item.port,
                  'panelWifiName': item.panelWifiName,
                  'panelWifiPassword': item.panelWifiPassword,
                  'mac': item.mac,
                  'modemName': item.modemName,
                  'modemPassword': item.modemPassword,
                  'panelIpOnModem': item.panelIpOnModem,
                  'staticIp': item.staticIp,
                  'isSelected': item.isSelected == null
                      ? null
                      : (item.isSelected! ? 1 : 0)
                }),
        _locationUpdateAdapter = UpdateAdapter(
            database,
            'locations',
            ['id'],
            (Location item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'port': item.port,
                  'panelWifiName': item.panelWifiName,
                  'panelWifiPassword': item.panelWifiPassword,
                  'mac': item.mac,
                  'modemName': item.modemName,
                  'modemPassword': item.modemPassword,
                  'panelIpOnModem': item.panelIpOnModem,
                  'staticIp': item.staticIp,
                  'isSelected': item.isSelected == null
                      ? null
                      : (item.isSelected! ? 1 : 0)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Location> _locationInsertionAdapter;

  final UpdateAdapter<Location> _locationUpdateAdapter;

  @override
  Future<void> updateSelectedLocation(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE locations SET isSelected = CASE WHEN id = ?1 THEN 1 ELSE 0 END',
        arguments: [id]);
  }

  @override
  Future<Location?> get(int id) async {
    return _queryAdapter.query('SELECT * FROM locations AS l WHERE l.id = ?1',
        mapper: (Map<String, Object?> row) => Location(
            id: row['id'] as int?,
            name: row['name'] as String?,
            port: row['port'] as int?,
            panelWifiName: row['panelWifiName'] as String?,
            panelWifiPassword: row['panelWifiPassword'] as String?,
            mac: row['mac'] as String?,
            modemName: row['modemName'] as String?,
            modemPassword: row['modemPassword'] as String?,
            panelIpOnModem: row['panelIpOnModem'] as String?,
            staticIp: row['staticIp'] as String?,
            isSelected: row['isSelected'] == null
                ? null
                : (row['isSelected'] as int) != 0),
        arguments: [id]);
  }

  @override
  Future<List<Location>> all() async {
    return _queryAdapter.queryList('SELECT * FROM locations',
        mapper: (Map<String, Object?> row) => Location(
            id: row['id'] as int?,
            name: row['name'] as String?,
            port: row['port'] as int?,
            panelWifiName: row['panelWifiName'] as String?,
            panelWifiPassword: row['panelWifiPassword'] as String?,
            mac: row['mac'] as String?,
            modemName: row['modemName'] as String?,
            modemPassword: row['modemPassword'] as String?,
            panelIpOnModem: row['panelIpOnModem'] as String?,
            staticIp: row['staticIp'] as String?,
            isSelected: row['isSelected'] == null
                ? null
                : (row['isSelected'] as int) != 0));
  }

  @override
  Future<Location?> getSelectedLocation() async {
    return _queryAdapter.query(
        'SELECT * FROM locations WHERE isSelected = 1 LIMIT 1',
        mapper: (Map<String, Object?> row) => Location(
            id: row['id'] as int?,
            name: row['name'] as String?,
            port: row['port'] as int?,
            panelWifiName: row['panelWifiName'] as String?,
            panelWifiPassword: row['panelWifiPassword'] as String?,
            mac: row['mac'] as String?,
            modemName: row['modemName'] as String?,
            modemPassword: row['modemPassword'] as String?,
            panelIpOnModem: row['panelIpOnModem'] as String?,
            staticIp: row['staticIp'] as String?,
            isSelected: row['isSelected'] == null
                ? null
                : (row['isSelected'] as int) != 0));
  }

  @override
  Future<Location?> getFirstLocation() async {
    return _queryAdapter.query('SELECT * FROM locations ORDER BY id LIMIT 1',
        mapper: (Map<String, Object?> row) => Location(
            id: row['id'] as int?,
            name: row['name'] as String?,
            port: row['port'] as int?,
            panelWifiName: row['panelWifiName'] as String?,
            panelWifiPassword: row['panelWifiPassword'] as String?,
            mac: row['mac'] as String?,
            modemName: row['modemName'] as String?,
            modemPassword: row['modemPassword'] as String?,
            panelIpOnModem: row['panelIpOnModem'] as String?,
            staticIp: row['staticIp'] as String?,
            isSelected: row['isSelected'] == null
                ? null
                : (row['isSelected'] as int) != 0));
  }

  @override
  Future<int> insert(Location t) {
    return _locationInsertionAdapter.insertAndReturnId(
        t, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertList(List<Location> t) async {
    await _locationInsertionAdapter.insertList(t, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(Location t) async {
    await _locationUpdateAdapter.update(t, OnConflictStrategy.replace);
  }
}

class _$PlaceDao extends PlaceDao {
  _$PlaceDao(
    this.database,
    this.changeListener,
  )   : _placeInsertionAdapter = InsertionAdapter(
            database,
            'places',
            (Place item) => <String, Object?>{
                  'id': item.id,
                  'locationId': item.locationId,
                  'floor': item.floor,
                  'code': item.code,
                  'name': item.name
                }),
        _placeUpdateAdapter = UpdateAdapter(
            database,
            'places',
            ['id'],
            (Place item) => <String, Object?>{
                  'id': item.id,
                  'locationId': item.locationId,
                  'floor': item.floor,
                  'code': item.code,
                  'name': item.name
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final InsertionAdapter<Place> _placeInsertionAdapter;

  final UpdateAdapter<Place> _placeUpdateAdapter;

  @override
  Future<int> insert(Place t) {
    return _placeInsertionAdapter.insertAndReturnId(
        t, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertList(List<Place> t) async {
    await _placeInsertionAdapter.insertList(t, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(Place t) async {
    await _placeUpdateAdapter.update(t, OnConflictStrategy.replace);
  }
}

class _$DeviceDao extends DeviceDao {
  _$DeviceDao(
    this.database,
    this.changeListener,
  )   : _deviceInsertionAdapter = InsertionAdapter(
            database,
            'devices',
            (Device item) => <String, Object?>{
                  'id': item.id,
                  'locationId': item.locationId,
                  'floor': item.floor,
                  'place': item.place,
                  'headline': item.headline,
                  'code': item.code,
                  'name': item.name,
                  'value': item.value,
                  'secondValue': item.secondValue
                }),
        _deviceUpdateAdapter = UpdateAdapter(
            database,
            'devices',
            ['id'],
            (Device item) => <String, Object?>{
                  'id': item.id,
                  'locationId': item.locationId,
                  'floor': item.floor,
                  'place': item.place,
                  'headline': item.headline,
                  'code': item.code,
                  'name': item.name,
                  'value': item.value,
                  'secondValue': item.secondValue
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final InsertionAdapter<Device> _deviceInsertionAdapter;

  final UpdateAdapter<Device> _deviceUpdateAdapter;

  @override
  Future<int> insert(Device t) {
    return _deviceInsertionAdapter.insertAndReturnId(
        t, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertList(List<Device> t) async {
    await _deviceInsertionAdapter.insertList(t, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(Device t) async {
    await _deviceUpdateAdapter.update(t, OnConflictStrategy.replace);
  }
}

class _$ScenarioDao extends ScenarioDao {
  _$ScenarioDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _scenarioInsertionAdapter = InsertionAdapter(
            database,
            'scenarios',
            (Scenario item) => <String, Object?>{
                  'id': item.id,
                  'locationId': item.locationId,
                  'floor': item.floor,
                  'place': item.place,
                  'name': item.name
                }),
        _scenarioUpdateAdapter = UpdateAdapter(
            database,
            'scenarios',
            ['id'],
            (Scenario item) => <String, Object?>{
                  'id': item.id,
                  'locationId': item.locationId,
                  'floor': item.floor,
                  'place': item.place,
                  'name': item.name
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Scenario> _scenarioInsertionAdapter;

  final UpdateAdapter<Scenario> _scenarioUpdateAdapter;

  @override
  Future<List<Scenario>> getAllScenarios(int locationId) async {
    return _queryAdapter.queryList(
        'select * from scenarios where locationId = ?1',
        mapper: (Map<String, Object?> row) => Scenario(
            id: row['id'] as int?,
            locationId: row['locationId'] as int?,
            name: row['name'] as String?,
            floor: row['floor'] as String?,
            place: row['place'] as String?),
        arguments: [locationId]);
  }

  @override
  Future<List<Scenario>> getGeneralScenarios(int locationId) async {
    return _queryAdapter.queryList(
        'select * from scenarios as s where s.floor isNull and s.place isNull and s.locationId = ?1 ORDER BY id DESC;',
        mapper: (Map<String, Object?> row) => Scenario(id: row['id'] as int?, locationId: row['locationId'] as int?, name: row['name'] as String?, floor: row['floor'] as String?, place: row['place'] as String?),
        arguments: [locationId]);
  }

  @override
  Future<int> insert(Scenario t) {
    return _scenarioInsertionAdapter.insertAndReturnId(
        t, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertList(List<Scenario> t) async {
    await _scenarioInsertionAdapter.insertList(t, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(Scenario t) async {
    await _scenarioUpdateAdapter.update(t, OnConflictStrategy.replace);
  }
}

class _$ScenarioDetDao extends ScenarioDetDao {
  _$ScenarioDetDao(
    this.database,
    this.changeListener,
  )   : _scenarioDetInsertionAdapter = InsertionAdapter(
            database,
            'scenario_det',
            (ScenarioDet item) => <String, Object?>{
                  'id': item.id,
                  'scenarioId': item.scenarioId,
                  'deviceId': item.deviceId,
                  'value': item.value
                }),
        _scenarioDetUpdateAdapter = UpdateAdapter(
            database,
            'scenario_det',
            ['id'],
            (ScenarioDet item) => <String, Object?>{
                  'id': item.id,
                  'scenarioId': item.scenarioId,
                  'deviceId': item.deviceId,
                  'value': item.value
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final InsertionAdapter<ScenarioDet> _scenarioDetInsertionAdapter;

  final UpdateAdapter<ScenarioDet> _scenarioDetUpdateAdapter;

  @override
  Future<int> insert(ScenarioDet t) {
    return _scenarioDetInsertionAdapter.insertAndReturnId(
        t, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertList(List<ScenarioDet> t) async {
    await _scenarioDetInsertionAdapter.insertList(
        t, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(ScenarioDet t) async {
    await _scenarioDetUpdateAdapter.update(t, OnConflictStrategy.replace);
  }
}

class _$LoggerDao extends LoggerDao {
  _$LoggerDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _loggerInsertionAdapter = InsertionAdapter(
            database,
            'logger',
            (Logger item) => <String, Object?>{
                  'id': item.id,
                  'time': item.time,
                  'className': item.className,
                  'methodName': item.methodName,
                  'value': item.value
                }),
        _loggerUpdateAdapter = UpdateAdapter(
            database,
            'logger',
            ['id'],
            (Logger item) => <String, Object?>{
                  'id': item.id,
                  'time': item.time,
                  'className': item.className,
                  'methodName': item.methodName,
                  'value': item.value
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Logger> _loggerInsertionAdapter;

  final UpdateAdapter<Logger> _loggerUpdateAdapter;

  @override
  Future<List<Logger>> getLogs() async {
    return _queryAdapter.queryList('select  * from logger',
        mapper: (Map<String, Object?> row) => Logger(
            id: row['id'] as int?,
            time: row['time'] as String?,
            className: row['className'] as String?,
            methodName: row['methodName'] as String?,
            value: row['value'] as String?));
  }

  @override
  Future<int> insert(Logger t) {
    return _loggerInsertionAdapter.insertAndReturnId(
        t, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertList(List<Logger> t) async {
    await _loggerInsertionAdapter.insertList(t, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(Logger t) async {
    await _loggerUpdateAdapter.update(t, OnConflictStrategy.replace);
  }
}
