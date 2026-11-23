// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String name;
  final String value;
  const SettingRow({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(name: Value(name), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? name, String? value}) =>
      SettingRow(name: name ?? this.name, value: value ?? this.value);
  SettingRow copyWithCompanion(AppSettingsCompanion data) {
    return SettingRow(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.name == this.name &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SizeOptionsTable extends SizeOptions
    with TableInfo<$SizeOptionsTable, SizeOptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SizeOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'size_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<SizeOptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SizeOptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SizeOptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $SizeOptionsTable createAlias(String alias) {
    return $SizeOptionsTable(attachedDatabase, alias);
  }
}

class SizeOptionRow extends DataClass implements Insertable<SizeOptionRow> {
  final String id;
  final String name;
  final int sortOrder;
  const SizeOptionRow({
    required this.id,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SizeOptionsCompanion toCompanion(bool nullToAbsent) {
    return SizeOptionsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory SizeOptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SizeOptionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  SizeOptionRow copyWith({String? id, String? name, int? sortOrder}) =>
      SizeOptionRow(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  SizeOptionRow copyWithCompanion(SizeOptionsCompanion data) {
    return SizeOptionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SizeOptionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SizeOptionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class SizeOptionsCompanion extends UpdateCompanion<SizeOptionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const SizeOptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SizeOptionsCompanion.insert({
    required String id,
    required String name,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<SizeOptionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SizeOptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return SizeOptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SizeOptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ColorOptionsTable extends ColorOptions
    with TableInfo<$ColorOptionsTable, ColorOptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ColorOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'color_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<ColorOptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ColorOptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ColorOptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ColorOptionsTable createAlias(String alias) {
    return $ColorOptionsTable(attachedDatabase, alias);
  }
}

class ColorOptionRow extends DataClass implements Insertable<ColorOptionRow> {
  final String id;
  final String name;
  final int sortOrder;
  const ColorOptionRow({
    required this.id,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ColorOptionsCompanion toCompanion(bool nullToAbsent) {
    return ColorOptionsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory ColorOptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ColorOptionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ColorOptionRow copyWith({String? id, String? name, int? sortOrder}) =>
      ColorOptionRow(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  ColorOptionRow copyWithCompanion(ColorOptionsCompanion data) {
    return ColorOptionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ColorOptionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ColorOptionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class ColorOptionsCompanion extends UpdateCompanion<ColorOptionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ColorOptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ColorOptionsCompanion.insert({
    required String id,
    required String name,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<ColorOptionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ColorOptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ColorOptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ColorOptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE COLLATE NOCASE',
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (role IN (\'CASHIER\', \'MANAGER\', \'OWNER\'))',
  );
  static const VerificationMeta _credentialHashMeta = const VerificationMeta(
    'credentialHash',
  );
  @override
  late final GeneratedColumn<String> credentialHash = GeneratedColumn<String>(
    'credential_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _staffNumberMeta = const VerificationMeta(
    'staffNumber',
  );
  @override
  late final GeneratedColumn<int> staffNumber = GeneratedColumn<int>(
    'staff_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failuresMeta = const VerificationMeta(
    'failures',
  );
  @override
  late final GeneratedColumn<int> failures = GeneratedColumn<int>(
    'failures',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockCountMeta = const VerificationMeta(
    'lockCount',
  );
  @override
  late final GeneratedColumn<int> lockCount = GeneratedColumn<int>(
    'lock_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedUntilMeta = const VerificationMeta(
    'lockedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
    'locked_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    role,
    credentialHash,
    active,
    staffNumber,
    failures,
    lockCount,
    lockedUntil,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('credential_hash')) {
      context.handle(
        _credentialHashMeta,
        credentialHash.isAcceptableOrUnknown(
          data['credential_hash']!,
          _credentialHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialHashMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('staff_number')) {
      context.handle(
        _staffNumberMeta,
        staffNumber.isAcceptableOrUnknown(
          data['staff_number']!,
          _staffNumberMeta,
        ),
      );
    }
    if (data.containsKey('failures')) {
      context.handle(
        _failuresMeta,
        failures.isAcceptableOrUnknown(data['failures']!, _failuresMeta),
      );
    }
    if (data.containsKey('lock_count')) {
      context.handle(
        _lockCountMeta,
        lockCount.isAcceptableOrUnknown(data['lock_count']!, _lockCountMeta),
      );
    }
    if (data.containsKey('locked_until')) {
      context.handle(
        _lockedUntilMeta,
        lockedUntil.isAcceptableOrUnknown(
          data['locked_until']!,
          _lockedUntilMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      credentialHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_hash'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      staffNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}staff_number'],
      ),
      failures: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failures'],
      )!,
      lockCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lock_count'],
      )!,
      lockedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_until'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final String id;
  final String name;
  final String role;
  final String credentialHash;
  final bool active;

  /// The number behind the operator ID printed on bills (OP001, OP002...).
  /// Given in order when the person is added, never reused.
  final int? staffNumber;
  final int failures;
  final int lockCount;
  final DateTime? lockedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserRow({
    required this.id,
    required this.name,
    required this.role,
    required this.credentialHash,
    required this.active,
    this.staffNumber,
    required this.failures,
    required this.lockCount,
    this.lockedUntil,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['credential_hash'] = Variable<String>(credentialHash);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || staffNumber != null) {
      map['staff_number'] = Variable<int>(staffNumber);
    }
    map['failures'] = Variable<int>(failures);
    map['lock_count'] = Variable<int>(lockCount);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      credentialHash: Value(credentialHash),
      active: Value(active),
      staffNumber: staffNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(staffNumber),
      failures: Value(failures),
      lockCount: Value(lockCount),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      credentialHash: serializer.fromJson<String>(json['credentialHash']),
      active: serializer.fromJson<bool>(json['active']),
      staffNumber: serializer.fromJson<int?>(json['staffNumber']),
      failures: serializer.fromJson<int>(json['failures']),
      lockCount: serializer.fromJson<int>(json['lockCount']),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'credentialHash': serializer.toJson<String>(credentialHash),
      'active': serializer.toJson<bool>(active),
      'staffNumber': serializer.toJson<int?>(staffNumber),
      'failures': serializer.toJson<int>(failures),
      'lockCount': serializer.toJson<int>(lockCount),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserRow copyWith({
    String? id,
    String? name,
    String? role,
    String? credentialHash,
    bool? active,
    Value<int?> staffNumber = const Value.absent(),
    int? failures,
    int? lockCount,
    Value<DateTime?> lockedUntil = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserRow(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    credentialHash: credentialHash ?? this.credentialHash,
    active: active ?? this.active,
    staffNumber: staffNumber.present ? staffNumber.value : this.staffNumber,
    failures: failures ?? this.failures,
    lockCount: lockCount ?? this.lockCount,
    lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      credentialHash: data.credentialHash.present
          ? data.credentialHash.value
          : this.credentialHash,
      active: data.active.present ? data.active.value : this.active,
      staffNumber: data.staffNumber.present
          ? data.staffNumber.value
          : this.staffNumber,
      failures: data.failures.present ? data.failures.value : this.failures,
      lockCount: data.lockCount.present ? data.lockCount.value : this.lockCount,
      lockedUntil: data.lockedUntil.present
          ? data.lockedUntil.value
          : this.lockedUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('credentialHash: $credentialHash, ')
          ..write('active: $active, ')
          ..write('staffNumber: $staffNumber, ')
          ..write('failures: $failures, ')
          ..write('lockCount: $lockCount, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    role,
    credentialHash,
    active,
    staffNumber,
    failures,
    lockCount,
    lockedUntil,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.credentialHash == this.credentialHash &&
          other.active == this.active &&
          other.staffNumber == this.staffNumber &&
          other.failures == this.failures &&
          other.lockCount == this.lockCount &&
          other.lockedUntil == this.lockedUntil &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> role;
  final Value<String> credentialHash;
  final Value<bool> active;
  final Value<int?> staffNumber;
  final Value<int> failures;
  final Value<int> lockCount;
  final Value<DateTime?> lockedUntil;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.credentialHash = const Value.absent(),
    this.active = const Value.absent(),
    this.staffNumber = const Value.absent(),
    this.failures = const Value.absent(),
    this.lockCount = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    required String role,
    required String credentialHash,
    this.active = const Value.absent(),
    this.staffNumber = const Value.absent(),
    this.failures = const Value.absent(),
    this.lockCount = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       role = Value(role),
       credentialHash = Value(credentialHash),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? credentialHash,
    Expression<bool>? active,
    Expression<int>? staffNumber,
    Expression<int>? failures,
    Expression<int>? lockCount,
    Expression<DateTime>? lockedUntil,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (credentialHash != null) 'credential_hash': credentialHash,
      if (active != null) 'active': active,
      if (staffNumber != null) 'staff_number': staffNumber,
      if (failures != null) 'failures': failures,
      if (lockCount != null) 'lock_count': lockCount,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? role,
    Value<String>? credentialHash,
    Value<bool>? active,
    Value<int?>? staffNumber,
    Value<int>? failures,
    Value<int>? lockCount,
    Value<DateTime?>? lockedUntil,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      credentialHash: credentialHash ?? this.credentialHash,
      active: active ?? this.active,
      staffNumber: staffNumber ?? this.staffNumber,
      failures: failures ?? this.failures,
      lockCount: lockCount ?? this.lockCount,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (credentialHash.present) {
      map['credential_hash'] = Variable<String>(credentialHash.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (staffNumber.present) {
      map['staff_number'] = Variable<int>(staffNumber.value);
    }
    if (failures.present) {
      map['failures'] = Variable<int>(failures.value);
    }
    if (lockCount.present) {
      map['lock_count'] = Variable<int>(lockCount.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('credentialHash: $credentialHash, ')
          ..write('active: $active, ')
          ..write('staffNumber: $staffNumber, ')
          ..write('failures: $failures, ')
          ..write('lockCount: $lockCount, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CountersTable extends Counters
    with TableInfo<$CountersTable, CounterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lotFirstMeta = const VerificationMeta(
    'lotFirst',
  );
  @override
  late final GeneratedColumn<int> lotFirst = GeneratedColumn<int>(
    'lot_first',
    aliasedName,
    false,
    check: () => ComparableExpr(lotFirst).isBetweenValues(0, 999),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lotLastMeta = const VerificationMeta(
    'lotLast',
  );
  @override
  late final GeneratedColumn<int> lotLast = GeneratedColumn<int>(
    'lot_last',
    aliasedName,
    false,
    check: () => ComparableExpr(lotLast).isBetweenValues(0, 999),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentLotMeta = const VerificationMeta(
    'currentLot',
  );
  @override
  late final GeneratedColumn<int> currentLot = GeneratedColumn<int>(
    'current_lot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextSerialMeta = const VerificationMeta(
    'nextSerial',
  );
  @override
  late final GeneratedColumn<int> nextSerial = GeneratedColumn<int>(
    'next_serial',
    aliasedName,
    false,
    check: () => ComparableExpr(nextSerial).isBetweenValues(0, 10000),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    lotFirst,
    lotLast,
    currentLot,
    nextSerial,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<CounterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lot_first')) {
      context.handle(
        _lotFirstMeta,
        lotFirst.isAcceptableOrUnknown(data['lot_first']!, _lotFirstMeta),
      );
    } else if (isInserting) {
      context.missing(_lotFirstMeta);
    }
    if (data.containsKey('lot_last')) {
      context.handle(
        _lotLastMeta,
        lotLast.isAcceptableOrUnknown(data['lot_last']!, _lotLastMeta),
      );
    } else if (isInserting) {
      context.missing(_lotLastMeta);
    }
    if (data.containsKey('current_lot')) {
      context.handle(
        _currentLotMeta,
        currentLot.isAcceptableOrUnknown(data['current_lot']!, _currentLotMeta),
      );
    } else if (isInserting) {
      context.missing(_currentLotMeta);
    }
    if (data.containsKey('next_serial')) {
      context.handle(
        _nextSerialMeta,
        nextSerial.isAcceptableOrUnknown(data['next_serial']!, _nextSerialMeta),
      );
    } else if (isInserting) {
      context.missing(_nextSerialMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CounterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CounterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lotFirst: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lot_first'],
      )!,
      lotLast: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lot_last'],
      )!,
      currentLot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_lot'],
      )!,
      nextSerial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_serial'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CountersTable createAlias(String alias) {
    return $CountersTable(attachedDatabase, alias);
  }
}

class CounterRow extends DataClass implements Insertable<CounterRow> {
  final String id;
  final String name;
  final int lotFirst;
  final int lotLast;
  final int currentLot;
  final int nextSerial;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CounterRow({
    required this.id,
    required this.name,
    required this.lotFirst,
    required this.lotLast,
    required this.currentLot,
    required this.nextSerial,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['lot_first'] = Variable<int>(lotFirst);
    map['lot_last'] = Variable<int>(lotLast);
    map['current_lot'] = Variable<int>(currentLot);
    map['next_serial'] = Variable<int>(nextSerial);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CountersCompanion toCompanion(bool nullToAbsent) {
    return CountersCompanion(
      id: Value(id),
      name: Value(name),
      lotFirst: Value(lotFirst),
      lotLast: Value(lotLast),
      currentLot: Value(currentLot),
      nextSerial: Value(nextSerial),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CounterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CounterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      lotFirst: serializer.fromJson<int>(json['lotFirst']),
      lotLast: serializer.fromJson<int>(json['lotLast']),
      currentLot: serializer.fromJson<int>(json['currentLot']),
      nextSerial: serializer.fromJson<int>(json['nextSerial']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'lotFirst': serializer.toJson<int>(lotFirst),
      'lotLast': serializer.toJson<int>(lotLast),
      'currentLot': serializer.toJson<int>(currentLot),
      'nextSerial': serializer.toJson<int>(nextSerial),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CounterRow copyWith({
    String? id,
    String? name,
    int? lotFirst,
    int? lotLast,
    int? currentLot,
    int? nextSerial,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CounterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    lotFirst: lotFirst ?? this.lotFirst,
    lotLast: lotLast ?? this.lotLast,
    currentLot: currentLot ?? this.currentLot,
    nextSerial: nextSerial ?? this.nextSerial,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CounterRow copyWithCompanion(CountersCompanion data) {
    return CounterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      lotFirst: data.lotFirst.present ? data.lotFirst.value : this.lotFirst,
      lotLast: data.lotLast.present ? data.lotLast.value : this.lotLast,
      currentLot: data.currentLot.present
          ? data.currentLot.value
          : this.currentLot,
      nextSerial: data.nextSerial.present
          ? data.nextSerial.value
          : this.nextSerial,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CounterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lotFirst: $lotFirst, ')
          ..write('lotLast: $lotLast, ')
          ..write('currentLot: $currentLot, ')
          ..write('nextSerial: $nextSerial, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    lotFirst,
    lotLast,
    currentLot,
    nextSerial,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CounterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.lotFirst == this.lotFirst &&
          other.lotLast == this.lotLast &&
          other.currentLot == this.currentLot &&
          other.nextSerial == this.nextSerial &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CountersCompanion extends UpdateCompanion<CounterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> lotFirst;
  final Value<int> lotLast;
  final Value<int> currentLot;
  final Value<int> nextSerial;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CountersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.lotFirst = const Value.absent(),
    this.lotLast = const Value.absent(),
    this.currentLot = const Value.absent(),
    this.nextSerial = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CountersCompanion.insert({
    required String id,
    required String name,
    required int lotFirst,
    required int lotLast,
    required int currentLot,
    required int nextSerial,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       lotFirst = Value(lotFirst),
       lotLast = Value(lotLast),
       currentLot = Value(currentLot),
       nextSerial = Value(nextSerial),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CounterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? lotFirst,
    Expression<int>? lotLast,
    Expression<int>? currentLot,
    Expression<int>? nextSerial,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (lotFirst != null) 'lot_first': lotFirst,
      if (lotLast != null) 'lot_last': lotLast,
      if (currentLot != null) 'current_lot': currentLot,
      if (nextSerial != null) 'next_serial': nextSerial,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CountersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? lotFirst,
    Value<int>? lotLast,
    Value<int>? currentLot,
    Value<int>? nextSerial,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CountersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      lotFirst: lotFirst ?? this.lotFirst,
      lotLast: lotLast ?? this.lotLast,
      currentLot: currentLot ?? this.currentLot,
      nextSerial: nextSerial ?? this.nextSerial,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lotFirst.present) {
      map['lot_first'] = Variable<int>(lotFirst.value);
    }
    if (lotLast.present) {
      map['lot_last'] = Variable<int>(lotLast.value);
    }
    if (currentLot.present) {
      map['current_lot'] = Variable<int>(currentLot.value);
    }
    if (nextSerial.present) {
      map['next_serial'] = Variable<int>(nextSerial.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lotFirst: $lotFirst, ')
          ..write('lotLast: $lotLast, ')
          ..write('currentLot: $currentLot, ')
          ..write('nextSerial: $nextSerial, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    parentId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;

  /// Null for a group.
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoryRow({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdBy,
    categoryId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String name;
  final String? createdBy;

  /// The category this style is in (none until the shop sets it).
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProductRow({
    required this.id,
    required this.name,
    this.createdBy,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdBy': serializer.toJson<String?>(createdBy),
      'categoryId': serializer.toJson<String?>(categoryId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductRow copyWith({
    String? id,
    String? name,
    Value<String?> createdBy = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProductRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdBy: $createdBy, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdBy, categoryId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdBy == this.createdBy &&
          other.categoryId == this.categoryId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> createdBy;
  final Value<String?> categoryId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.createdBy = const Value.absent(),
    this.categoryId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? createdBy,
    Expression<String>? categoryId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdBy != null) 'created_by': createdBy,
      if (categoryId != null) 'category_id': categoryId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? createdBy,
    Value<String?>? categoryId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdBy: $createdBy, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StyleMarkdownsTable extends StyleMarkdowns
    with TableInfo<$StyleMarkdownsTable, StyleMarkdownRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StyleMarkdownsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _percentBpMeta = const VerificationMeta(
    'percentBp',
  );
  @override
  late final GeneratedColumn<int> percentBp = GeneratedColumn<int>(
    'percent_bp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsBeforeMeta = const VerificationMeta(
    'endsBefore',
  );
  @override
  late final GeneratedColumn<DateTime> endsBefore = GeneratedColumn<DateTime>(
    'ends_before',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setByMeta = const VerificationMeta('setBy');
  @override
  late final GeneratedColumn<String> setBy = GeneratedColumn<String>(
    'set_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    percentBp,
    amountPaise,
    endsBefore,
    setBy,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'style_markdowns';
  @override
  VerificationContext validateIntegrity(
    Insertable<StyleMarkdownRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('percent_bp')) {
      context.handle(
        _percentBpMeta,
        percentBp.isAcceptableOrUnknown(data['percent_bp']!, _percentBpMeta),
      );
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    }
    if (data.containsKey('ends_before')) {
      context.handle(
        _endsBeforeMeta,
        endsBefore.isAcceptableOrUnknown(data['ends_before']!, _endsBeforeMeta),
      );
    } else if (isInserting) {
      context.missing(_endsBeforeMeta);
    }
    if (data.containsKey('set_by')) {
      context.handle(
        _setByMeta,
        setBy.isAcceptableOrUnknown(data['set_by']!, _setByMeta),
      );
    } else if (isInserting) {
      context.missing(_setByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  StyleMarkdownRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StyleMarkdownRow(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      percentBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percent_bp'],
      ),
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      ),
      endsBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_before'],
      )!,
      setBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StyleMarkdownsTable createAlias(String alias) {
    return $StyleMarkdownsTable(attachedDatabase, alias);
  }
}

class StyleMarkdownRow extends DataClass
    implements Insertable<StyleMarkdownRow> {
  final String productId;

  /// A percentage in basis points (2000 is 20%); null when it is an amount.
  final int? percentBp;

  /// A fixed amount in paise; null when it is a percentage.
  final int? amountPaise;
  final DateTime endsBefore;
  final String setBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StyleMarkdownRow({
    required this.productId,
    this.percentBp,
    this.amountPaise,
    required this.endsBefore,
    required this.setBy,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || percentBp != null) {
      map['percent_bp'] = Variable<int>(percentBp);
    }
    if (!nullToAbsent || amountPaise != null) {
      map['amount_paise'] = Variable<int>(amountPaise);
    }
    map['ends_before'] = Variable<DateTime>(endsBefore);
    map['set_by'] = Variable<String>(setBy);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StyleMarkdownsCompanion toCompanion(bool nullToAbsent) {
    return StyleMarkdownsCompanion(
      productId: Value(productId),
      percentBp: percentBp == null && nullToAbsent
          ? const Value.absent()
          : Value(percentBp),
      amountPaise: amountPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(amountPaise),
      endsBefore: Value(endsBefore),
      setBy: Value(setBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StyleMarkdownRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StyleMarkdownRow(
      productId: serializer.fromJson<String>(json['productId']),
      percentBp: serializer.fromJson<int?>(json['percentBp']),
      amountPaise: serializer.fromJson<int?>(json['amountPaise']),
      endsBefore: serializer.fromJson<DateTime>(json['endsBefore']),
      setBy: serializer.fromJson<String>(json['setBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'percentBp': serializer.toJson<int?>(percentBp),
      'amountPaise': serializer.toJson<int?>(amountPaise),
      'endsBefore': serializer.toJson<DateTime>(endsBefore),
      'setBy': serializer.toJson<String>(setBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StyleMarkdownRow copyWith({
    String? productId,
    Value<int?> percentBp = const Value.absent(),
    Value<int?> amountPaise = const Value.absent(),
    DateTime? endsBefore,
    String? setBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StyleMarkdownRow(
    productId: productId ?? this.productId,
    percentBp: percentBp.present ? percentBp.value : this.percentBp,
    amountPaise: amountPaise.present ? amountPaise.value : this.amountPaise,
    endsBefore: endsBefore ?? this.endsBefore,
    setBy: setBy ?? this.setBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StyleMarkdownRow copyWithCompanion(StyleMarkdownsCompanion data) {
    return StyleMarkdownRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      percentBp: data.percentBp.present ? data.percentBp.value : this.percentBp,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      endsBefore: data.endsBefore.present
          ? data.endsBefore.value
          : this.endsBefore,
      setBy: data.setBy.present ? data.setBy.value : this.setBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StyleMarkdownRow(')
          ..write('productId: $productId, ')
          ..write('percentBp: $percentBp, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('endsBefore: $endsBefore, ')
          ..write('setBy: $setBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    productId,
    percentBp,
    amountPaise,
    endsBefore,
    setBy,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StyleMarkdownRow &&
          other.productId == this.productId &&
          other.percentBp == this.percentBp &&
          other.amountPaise == this.amountPaise &&
          other.endsBefore == this.endsBefore &&
          other.setBy == this.setBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StyleMarkdownsCompanion extends UpdateCompanion<StyleMarkdownRow> {
  final Value<String> productId;
  final Value<int?> percentBp;
  final Value<int?> amountPaise;
  final Value<DateTime> endsBefore;
  final Value<String> setBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StyleMarkdownsCompanion({
    this.productId = const Value.absent(),
    this.percentBp = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.endsBefore = const Value.absent(),
    this.setBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StyleMarkdownsCompanion.insert({
    required String productId,
    this.percentBp = const Value.absent(),
    this.amountPaise = const Value.absent(),
    required DateTime endsBefore,
    required String setBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       endsBefore = Value(endsBefore),
       setBy = Value(setBy),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StyleMarkdownRow> custom({
    Expression<String>? productId,
    Expression<int>? percentBp,
    Expression<int>? amountPaise,
    Expression<DateTime>? endsBefore,
    Expression<String>? setBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (percentBp != null) 'percent_bp': percentBp,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (endsBefore != null) 'ends_before': endsBefore,
      if (setBy != null) 'set_by': setBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StyleMarkdownsCompanion copyWith({
    Value<String>? productId,
    Value<int?>? percentBp,
    Value<int?>? amountPaise,
    Value<DateTime>? endsBefore,
    Value<String>? setBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StyleMarkdownsCompanion(
      productId: productId ?? this.productId,
      percentBp: percentBp ?? this.percentBp,
      amountPaise: amountPaise ?? this.amountPaise,
      endsBefore: endsBefore ?? this.endsBefore,
      setBy: setBy ?? this.setBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (percentBp.present) {
      map['percent_bp'] = Variable<int>(percentBp.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (endsBefore.present) {
      map['ends_before'] = Variable<DateTime>(endsBefore.value);
    }
    if (setBy.present) {
      map['set_by'] = Variable<String>(setBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StyleMarkdownsCompanion(')
          ..write('productId: $productId, ')
          ..write('percentBp: $percentBp, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('endsBefore: $endsBefore, ')
          ..write('setBy: $setBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, phone, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final String id;
  final String name;

  /// The phone key (`customerPhoneKey`): the digits, last 10 when there are
  /// more. Unique.
  final String phone;
  final DateTime createdAt;
  const CustomerRow({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      createdAt: Value(createdAt),
    );
  }

  factory CustomerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomerRow copyWith({
    String? id,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) => CustomerRow(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomerRow copyWithCompanion(CustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.createdAt == this.createdAt);
}

class CustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String name,
    required String phone,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       phone = Value(phone),
       createdAt = Value(createdAt);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTable extends Shifts with TableInfo<$ShiftsTable, ShiftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _counterIdMeta = const VerificationMeta(
    'counterId',
  );
  @override
  late final GeneratedColumn<String> counterId = GeneratedColumn<String>(
    'counter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counters (id)',
    ),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingPaiseMeta = const VerificationMeta(
    'openingPaise',
  );
  @override
  late final GeneratedColumn<int> openingPaise = GeneratedColumn<int>(
    'opening_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(openingPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingCountMeta = const VerificationMeta(
    'openingCount',
  );
  @override
  late final GeneratedColumn<String> openingCount = GeneratedColumn<String>(
    'opening_count',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cashierId,
    counterId,
    openedAt,
    openingPaise,
    openingCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('counter_id')) {
      context.handle(
        _counterIdMeta,
        counterId.isAcceptableOrUnknown(data['counter_id']!, _counterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_counterIdMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('opening_paise')) {
      context.handle(
        _openingPaiseMeta,
        openingPaise.isAcceptableOrUnknown(
          data['opening_paise']!,
          _openingPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingPaiseMeta);
    }
    if (data.containsKey('opening_count')) {
      context.handle(
        _openingCountMeta,
        openingCount.isAcceptableOrUnknown(
          data['opening_count']!,
          _openingCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      counterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_id'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      openingPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_paise'],
      )!,
      openingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_count'],
      )!,
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }
}

class ShiftRow extends DataClass implements Insertable<ShiftRow> {
  final String id;
  final String cashierId;
  final String counterId;
  final DateTime openedAt;
  final int openingPaise;

  /// The opening count as JSON: denomination name to how many.
  final String openingCount;
  const ShiftRow({
    required this.id,
    required this.cashierId,
    required this.counterId,
    required this.openedAt,
    required this.openingPaise,
    required this.openingCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cashier_id'] = Variable<String>(cashierId);
    map['counter_id'] = Variable<String>(counterId);
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['opening_paise'] = Variable<int>(openingPaise);
    map['opening_count'] = Variable<String>(openingCount);
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      cashierId: Value(cashierId),
      counterId: Value(counterId),
      openedAt: Value(openedAt),
      openingPaise: Value(openingPaise),
      openingCount: Value(openingCount),
    );
  }

  factory ShiftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftRow(
      id: serializer.fromJson<String>(json['id']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      counterId: serializer.fromJson<String>(json['counterId']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      openingPaise: serializer.fromJson<int>(json['openingPaise']),
      openingCount: serializer.fromJson<String>(json['openingCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cashierId': serializer.toJson<String>(cashierId),
      'counterId': serializer.toJson<String>(counterId),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'openingPaise': serializer.toJson<int>(openingPaise),
      'openingCount': serializer.toJson<String>(openingCount),
    };
  }

  ShiftRow copyWith({
    String? id,
    String? cashierId,
    String? counterId,
    DateTime? openedAt,
    int? openingPaise,
    String? openingCount,
  }) => ShiftRow(
    id: id ?? this.id,
    cashierId: cashierId ?? this.cashierId,
    counterId: counterId ?? this.counterId,
    openedAt: openedAt ?? this.openedAt,
    openingPaise: openingPaise ?? this.openingPaise,
    openingCount: openingCount ?? this.openingCount,
  );
  ShiftRow copyWithCompanion(ShiftsCompanion data) {
    return ShiftRow(
      id: data.id.present ? data.id.value : this.id,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      counterId: data.counterId.present ? data.counterId.value : this.counterId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      openingPaise: data.openingPaise.present
          ? data.openingPaise.value
          : this.openingPaise,
      openingCount: data.openingCount.present
          ? data.openingCount.value
          : this.openingCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRow(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('counterId: $counterId, ')
          ..write('openedAt: $openedAt, ')
          ..write('openingPaise: $openingPaise, ')
          ..write('openingCount: $openingCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cashierId,
    counterId,
    openedAt,
    openingPaise,
    openingCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftRow &&
          other.id == this.id &&
          other.cashierId == this.cashierId &&
          other.counterId == this.counterId &&
          other.openedAt == this.openedAt &&
          other.openingPaise == this.openingPaise &&
          other.openingCount == this.openingCount);
}

class ShiftsCompanion extends UpdateCompanion<ShiftRow> {
  final Value<String> id;
  final Value<String> cashierId;
  final Value<String> counterId;
  final Value<DateTime> openedAt;
  final Value<int> openingPaise;
  final Value<String> openingCount;
  final Value<int> rowid;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.counterId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openingPaise = const Value.absent(),
    this.openingCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftsCompanion.insert({
    required String id,
    required String cashierId,
    required String counterId,
    required DateTime openedAt,
    required int openingPaise,
    required String openingCount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cashierId = Value(cashierId),
       counterId = Value(counterId),
       openedAt = Value(openedAt),
       openingPaise = Value(openingPaise),
       openingCount = Value(openingCount);
  static Insertable<ShiftRow> custom({
    Expression<String>? id,
    Expression<String>? cashierId,
    Expression<String>? counterId,
    Expression<DateTime>? openedAt,
    Expression<int>? openingPaise,
    Expression<String>? openingCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cashierId != null) 'cashier_id': cashierId,
      if (counterId != null) 'counter_id': counterId,
      if (openedAt != null) 'opened_at': openedAt,
      if (openingPaise != null) 'opening_paise': openingPaise,
      if (openingCount != null) 'opening_count': openingCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftsCompanion copyWith({
    Value<String>? id,
    Value<String>? cashierId,
    Value<String>? counterId,
    Value<DateTime>? openedAt,
    Value<int>? openingPaise,
    Value<String>? openingCount,
    Value<int>? rowid,
  }) {
    return ShiftsCompanion(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      counterId: counterId ?? this.counterId,
      openedAt: openedAt ?? this.openedAt,
      openingPaise: openingPaise ?? this.openingPaise,
      openingCount: openingCount ?? this.openingCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (counterId.present) {
      map['counter_id'] = Variable<String>(counterId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (openingPaise.present) {
      map['opening_paise'] = Variable<int>(openingPaise.value);
    }
    if (openingCount.present) {
      map['opening_count'] = Variable<String>(openingCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('counterId: $counterId, ')
          ..write('openedAt: $openedAt, ')
          ..write('openingPaise: $openingPaise, ')
          ..write('openingCount: $openingCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuesReceiptsTable extends DuesReceipts
    with TableInfo<$DuesReceiptsTable, DuesReceiptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuesReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (id)',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _receivedByMeta = const VerificationMeta(
    'receivedBy',
  );
  @override
  late final GeneratedColumn<String> receivedBy = GeneratedColumn<String>(
    'received_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashPaiseMeta = const VerificationMeta(
    'cashPaise',
  );
  @override
  late final GeneratedColumn<int> cashPaise = GeneratedColumn<int>(
    'cash_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(cashPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _upiPaiseMeta = const VerificationMeta(
    'upiPaise',
  );
  @override
  late final GeneratedColumn<int> upiPaise = GeneratedColumn<int>(
    'upi_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(upiPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardPaiseMeta = const VerificationMeta(
    'cardPaise',
  );
  @override
  late final GeneratedColumn<int> cardPaise = GeneratedColumn<int>(
    'card_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(cardPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changePaiseMeta = const VerificationMeta(
    'changePaise',
  );
  @override
  late final GeneratedColumn<int> changePaise = GeneratedColumn<int>(
    'change_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(changePaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedPaiseMeta = const VerificationMeta(
    'appliedPaise',
  );
  @override
  late final GeneratedColumn<int> appliedPaise = GeneratedColumn<int>(
    'applied_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(appliedPaise).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    at,
    shiftId,
    receivedBy,
    cashPaise,
    upiPaise,
    cardPaise,
    changePaise,
    appliedPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dues_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DuesReceiptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('received_by')) {
      context.handle(
        _receivedByMeta,
        receivedBy.isAcceptableOrUnknown(data['received_by']!, _receivedByMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedByMeta);
    }
    if (data.containsKey('cash_paise')) {
      context.handle(
        _cashPaiseMeta,
        cashPaise.isAcceptableOrUnknown(data['cash_paise']!, _cashPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_cashPaiseMeta);
    }
    if (data.containsKey('upi_paise')) {
      context.handle(
        _upiPaiseMeta,
        upiPaise.isAcceptableOrUnknown(data['upi_paise']!, _upiPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_upiPaiseMeta);
    }
    if (data.containsKey('card_paise')) {
      context.handle(
        _cardPaiseMeta,
        cardPaise.isAcceptableOrUnknown(data['card_paise']!, _cardPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_cardPaiseMeta);
    }
    if (data.containsKey('change_paise')) {
      context.handle(
        _changePaiseMeta,
        changePaise.isAcceptableOrUnknown(
          data['change_paise']!,
          _changePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changePaiseMeta);
    }
    if (data.containsKey('applied_paise')) {
      context.handle(
        _appliedPaiseMeta,
        appliedPaise.isAcceptableOrUnknown(
          data['applied_paise']!,
          _appliedPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appliedPaiseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DuesReceiptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuesReceiptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      receivedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}received_by'],
      )!,
      cashPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_paise'],
      )!,
      upiPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upi_paise'],
      )!,
      cardPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_paise'],
      )!,
      changePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_paise'],
      )!,
      appliedPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_paise'],
      )!,
    );
  }

  @override
  $DuesReceiptsTable createAlias(String alias) {
    return $DuesReceiptsTable(attachedDatabase, alias);
  }
}

class DuesReceiptRow extends DataClass implements Insertable<DuesReceiptRow> {
  final String id;
  final String customerId;
  final DateTime at;
  final String shiftId;
  final String receivedBy;
  final int cashPaise;
  final int upiPaise;
  final int cardPaise;
  final int changePaise;

  /// What was taken off the debt: cash + UPI + card - change.
  final int appliedPaise;
  const DuesReceiptRow({
    required this.id,
    required this.customerId,
    required this.at,
    required this.shiftId,
    required this.receivedBy,
    required this.cashPaise,
    required this.upiPaise,
    required this.cardPaise,
    required this.changePaise,
    required this.appliedPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['at'] = Variable<DateTime>(at);
    map['shift_id'] = Variable<String>(shiftId);
    map['received_by'] = Variable<String>(receivedBy);
    map['cash_paise'] = Variable<int>(cashPaise);
    map['upi_paise'] = Variable<int>(upiPaise);
    map['card_paise'] = Variable<int>(cardPaise);
    map['change_paise'] = Variable<int>(changePaise);
    map['applied_paise'] = Variable<int>(appliedPaise);
    return map;
  }

  DuesReceiptsCompanion toCompanion(bool nullToAbsent) {
    return DuesReceiptsCompanion(
      id: Value(id),
      customerId: Value(customerId),
      at: Value(at),
      shiftId: Value(shiftId),
      receivedBy: Value(receivedBy),
      cashPaise: Value(cashPaise),
      upiPaise: Value(upiPaise),
      cardPaise: Value(cardPaise),
      changePaise: Value(changePaise),
      appliedPaise: Value(appliedPaise),
    );
  }

  factory DuesReceiptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuesReceiptRow(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      at: serializer.fromJson<DateTime>(json['at']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      receivedBy: serializer.fromJson<String>(json['receivedBy']),
      cashPaise: serializer.fromJson<int>(json['cashPaise']),
      upiPaise: serializer.fromJson<int>(json['upiPaise']),
      cardPaise: serializer.fromJson<int>(json['cardPaise']),
      changePaise: serializer.fromJson<int>(json['changePaise']),
      appliedPaise: serializer.fromJson<int>(json['appliedPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'at': serializer.toJson<DateTime>(at),
      'shiftId': serializer.toJson<String>(shiftId),
      'receivedBy': serializer.toJson<String>(receivedBy),
      'cashPaise': serializer.toJson<int>(cashPaise),
      'upiPaise': serializer.toJson<int>(upiPaise),
      'cardPaise': serializer.toJson<int>(cardPaise),
      'changePaise': serializer.toJson<int>(changePaise),
      'appliedPaise': serializer.toJson<int>(appliedPaise),
    };
  }

  DuesReceiptRow copyWith({
    String? id,
    String? customerId,
    DateTime? at,
    String? shiftId,
    String? receivedBy,
    int? cashPaise,
    int? upiPaise,
    int? cardPaise,
    int? changePaise,
    int? appliedPaise,
  }) => DuesReceiptRow(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    at: at ?? this.at,
    shiftId: shiftId ?? this.shiftId,
    receivedBy: receivedBy ?? this.receivedBy,
    cashPaise: cashPaise ?? this.cashPaise,
    upiPaise: upiPaise ?? this.upiPaise,
    cardPaise: cardPaise ?? this.cardPaise,
    changePaise: changePaise ?? this.changePaise,
    appliedPaise: appliedPaise ?? this.appliedPaise,
  );
  DuesReceiptRow copyWithCompanion(DuesReceiptsCompanion data) {
    return DuesReceiptRow(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      at: data.at.present ? data.at.value : this.at,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      receivedBy: data.receivedBy.present
          ? data.receivedBy.value
          : this.receivedBy,
      cashPaise: data.cashPaise.present ? data.cashPaise.value : this.cashPaise,
      upiPaise: data.upiPaise.present ? data.upiPaise.value : this.upiPaise,
      cardPaise: data.cardPaise.present ? data.cardPaise.value : this.cardPaise,
      changePaise: data.changePaise.present
          ? data.changePaise.value
          : this.changePaise,
      appliedPaise: data.appliedPaise.present
          ? data.appliedPaise.value
          : this.appliedPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuesReceiptRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('at: $at, ')
          ..write('shiftId: $shiftId, ')
          ..write('receivedBy: $receivedBy, ')
          ..write('cashPaise: $cashPaise, ')
          ..write('upiPaise: $upiPaise, ')
          ..write('cardPaise: $cardPaise, ')
          ..write('changePaise: $changePaise, ')
          ..write('appliedPaise: $appliedPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    at,
    shiftId,
    receivedBy,
    cashPaise,
    upiPaise,
    cardPaise,
    changePaise,
    appliedPaise,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuesReceiptRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.at == this.at &&
          other.shiftId == this.shiftId &&
          other.receivedBy == this.receivedBy &&
          other.cashPaise == this.cashPaise &&
          other.upiPaise == this.upiPaise &&
          other.cardPaise == this.cardPaise &&
          other.changePaise == this.changePaise &&
          other.appliedPaise == this.appliedPaise);
}

class DuesReceiptsCompanion extends UpdateCompanion<DuesReceiptRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<DateTime> at;
  final Value<String> shiftId;
  final Value<String> receivedBy;
  final Value<int> cashPaise;
  final Value<int> upiPaise;
  final Value<int> cardPaise;
  final Value<int> changePaise;
  final Value<int> appliedPaise;
  final Value<int> rowid;
  const DuesReceiptsCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.at = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.receivedBy = const Value.absent(),
    this.cashPaise = const Value.absent(),
    this.upiPaise = const Value.absent(),
    this.cardPaise = const Value.absent(),
    this.changePaise = const Value.absent(),
    this.appliedPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuesReceiptsCompanion.insert({
    required String id,
    required String customerId,
    required DateTime at,
    required String shiftId,
    required String receivedBy,
    required int cashPaise,
    required int upiPaise,
    required int cardPaise,
    required int changePaise,
    required int appliedPaise,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       at = Value(at),
       shiftId = Value(shiftId),
       receivedBy = Value(receivedBy),
       cashPaise = Value(cashPaise),
       upiPaise = Value(upiPaise),
       cardPaise = Value(cardPaise),
       changePaise = Value(changePaise),
       appliedPaise = Value(appliedPaise);
  static Insertable<DuesReceiptRow> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<DateTime>? at,
    Expression<String>? shiftId,
    Expression<String>? receivedBy,
    Expression<int>? cashPaise,
    Expression<int>? upiPaise,
    Expression<int>? cardPaise,
    Expression<int>? changePaise,
    Expression<int>? appliedPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (at != null) 'at': at,
      if (shiftId != null) 'shift_id': shiftId,
      if (receivedBy != null) 'received_by': receivedBy,
      if (cashPaise != null) 'cash_paise': cashPaise,
      if (upiPaise != null) 'upi_paise': upiPaise,
      if (cardPaise != null) 'card_paise': cardPaise,
      if (changePaise != null) 'change_paise': changePaise,
      if (appliedPaise != null) 'applied_paise': appliedPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuesReceiptsCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<DateTime>? at,
    Value<String>? shiftId,
    Value<String>? receivedBy,
    Value<int>? cashPaise,
    Value<int>? upiPaise,
    Value<int>? cardPaise,
    Value<int>? changePaise,
    Value<int>? appliedPaise,
    Value<int>? rowid,
  }) {
    return DuesReceiptsCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      at: at ?? this.at,
      shiftId: shiftId ?? this.shiftId,
      receivedBy: receivedBy ?? this.receivedBy,
      cashPaise: cashPaise ?? this.cashPaise,
      upiPaise: upiPaise ?? this.upiPaise,
      cardPaise: cardPaise ?? this.cardPaise,
      changePaise: changePaise ?? this.changePaise,
      appliedPaise: appliedPaise ?? this.appliedPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (receivedBy.present) {
      map['received_by'] = Variable<String>(receivedBy.value);
    }
    if (cashPaise.present) {
      map['cash_paise'] = Variable<int>(cashPaise.value);
    }
    if (upiPaise.present) {
      map['upi_paise'] = Variable<int>(upiPaise.value);
    }
    if (cardPaise.present) {
      map['card_paise'] = Variable<int>(cardPaise.value);
    }
    if (changePaise.present) {
      map['change_paise'] = Variable<int>(changePaise.value);
    }
    if (appliedPaise.present) {
      map['applied_paise'] = Variable<int>(appliedPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DuesReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('at: $at, ')
          ..write('shiftId: $shiftId, ')
          ..write('receivedBy: $receivedBy, ')
          ..write('cashPaise: $cashPaise, ')
          ..write('upiPaise: $upiPaise, ')
          ..write('cardPaise: $cardPaise, ')
          ..write('changePaise: $changePaise, ')
          ..write('appliedPaise: $appliedPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, BillRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billNoMeta = const VerificationMeta('billNo');
  @override
  late final GeneratedColumn<String> billNo = GeneratedColumn<String>(
    'bill_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _counterIdMeta = const VerificationMeta(
    'counterId',
  );
  @override
  late final GeneratedColumn<String> counterId = GeneratedColumn<String>(
    'counter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counters (id)',
    ),
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerPhoneMeta = const VerificationMeta(
    'customerPhone',
  );
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
    'customer_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPaiseMeta = const VerificationMeta(
    'totalPaise',
  );
  @override
  late final GeneratedColumn<int> totalPaise = GeneratedColumn<int>(
    'total_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(totalPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changePaiseMeta = const VerificationMeta(
    'changePaise',
  );
  @override
  late final GeneratedColumn<int> changePaise = GeneratedColumn<int>(
    'change_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(changePaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billedAtMeta = const VerificationMeta(
    'billedAt',
  );
  @override
  late final GeneratedColumn<DateTime> billedAt = GeneratedColumn<DateTime>(
    'billed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    billNo,
    counterId,
    cashierId,
    shiftId,
    customerName,
    customerPhone,
    totalPaise,
    changePaise,
    billedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_no')) {
      context.handle(
        _billNoMeta,
        billNo.isAcceptableOrUnknown(data['bill_no']!, _billNoMeta),
      );
    } else if (isInserting) {
      context.missing(_billNoMeta);
    }
    if (data.containsKey('counter_id')) {
      context.handle(
        _counterIdMeta,
        counterId.isAcceptableOrUnknown(data['counter_id']!, _counterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_counterIdMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
        _customerPhoneMeta,
        customerPhone.isAcceptableOrUnknown(
          data['customer_phone']!,
          _customerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('total_paise')) {
      context.handle(
        _totalPaiseMeta,
        totalPaise.isAcceptableOrUnknown(data['total_paise']!, _totalPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPaiseMeta);
    }
    if (data.containsKey('change_paise')) {
      context.handle(
        _changePaiseMeta,
        changePaise.isAcceptableOrUnknown(
          data['change_paise']!,
          _changePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changePaiseMeta);
    }
    if (data.containsKey('billed_at')) {
      context.handle(
        _billedAtMeta,
        billedAt.isAcceptableOrUnknown(data['billed_at']!, _billedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_billedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_no'],
      )!,
      counterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_id'],
      )!,
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      customerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_phone'],
      ),
      totalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_paise'],
      )!,
      changePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_paise'],
      )!,
      billedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}billed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class BillRow extends DataClass implements Insertable<BillRow> {
  final String id;
  final String billNo;
  final String counterId;
  final String cashierId;
  final String? shiftId;
  final String? customerName;
  final String? customerPhone;
  final int totalPaise;
  final int changePaise;
  final DateTime billedAt;
  final DateTime createdAt;
  const BillRow({
    required this.id,
    required this.billNo,
    required this.counterId,
    required this.cashierId,
    this.shiftId,
    this.customerName,
    this.customerPhone,
    required this.totalPaise,
    required this.changePaise,
    required this.billedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_no'] = Variable<String>(billNo);
    map['counter_id'] = Variable<String>(counterId);
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    map['total_paise'] = Variable<int>(totalPaise);
    map['change_paise'] = Variable<int>(changePaise);
    map['billed_at'] = Variable<DateTime>(billedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      billNo: Value(billNo),
      counterId: Value(counterId),
      cashierId: Value(cashierId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      totalPaise: Value(totalPaise),
      changePaise: Value(changePaise),
      billedAt: Value(billedAt),
      createdAt: Value(createdAt),
    );
  }

  factory BillRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillRow(
      id: serializer.fromJson<String>(json['id']),
      billNo: serializer.fromJson<String>(json['billNo']),
      counterId: serializer.fromJson<String>(json['counterId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      totalPaise: serializer.fromJson<int>(json['totalPaise']),
      changePaise: serializer.fromJson<int>(json['changePaise']),
      billedAt: serializer.fromJson<DateTime>(json['billedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billNo': serializer.toJson<String>(billNo),
      'counterId': serializer.toJson<String>(counterId),
      'cashierId': serializer.toJson<String>(cashierId),
      'shiftId': serializer.toJson<String?>(shiftId),
      'customerName': serializer.toJson<String?>(customerName),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'totalPaise': serializer.toJson<int>(totalPaise),
      'changePaise': serializer.toJson<int>(changePaise),
      'billedAt': serializer.toJson<DateTime>(billedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BillRow copyWith({
    String? id,
    String? billNo,
    String? counterId,
    String? cashierId,
    Value<String?> shiftId = const Value.absent(),
    Value<String?> customerName = const Value.absent(),
    Value<String?> customerPhone = const Value.absent(),
    int? totalPaise,
    int? changePaise,
    DateTime? billedAt,
    DateTime? createdAt,
  }) => BillRow(
    id: id ?? this.id,
    billNo: billNo ?? this.billNo,
    counterId: counterId ?? this.counterId,
    cashierId: cashierId ?? this.cashierId,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    customerName: customerName.present ? customerName.value : this.customerName,
    customerPhone: customerPhone.present
        ? customerPhone.value
        : this.customerPhone,
    totalPaise: totalPaise ?? this.totalPaise,
    changePaise: changePaise ?? this.changePaise,
    billedAt: billedAt ?? this.billedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  BillRow copyWithCompanion(BillsCompanion data) {
    return BillRow(
      id: data.id.present ? data.id.value : this.id,
      billNo: data.billNo.present ? data.billNo.value : this.billNo,
      counterId: data.counterId.present ? data.counterId.value : this.counterId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      totalPaise: data.totalPaise.present
          ? data.totalPaise.value
          : this.totalPaise,
      changePaise: data.changePaise.present
          ? data.changePaise.value
          : this.changePaise,
      billedAt: data.billedAt.present ? data.billedAt.value : this.billedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillRow(')
          ..write('id: $id, ')
          ..write('billNo: $billNo, ')
          ..write('counterId: $counterId, ')
          ..write('cashierId: $cashierId, ')
          ..write('shiftId: $shiftId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('totalPaise: $totalPaise, ')
          ..write('changePaise: $changePaise, ')
          ..write('billedAt: $billedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    billNo,
    counterId,
    cashierId,
    shiftId,
    customerName,
    customerPhone,
    totalPaise,
    changePaise,
    billedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillRow &&
          other.id == this.id &&
          other.billNo == this.billNo &&
          other.counterId == this.counterId &&
          other.cashierId == this.cashierId &&
          other.shiftId == this.shiftId &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.totalPaise == this.totalPaise &&
          other.changePaise == this.changePaise &&
          other.billedAt == this.billedAt &&
          other.createdAt == this.createdAt);
}

class BillsCompanion extends UpdateCompanion<BillRow> {
  final Value<String> id;
  final Value<String> billNo;
  final Value<String> counterId;
  final Value<String> cashierId;
  final Value<String?> shiftId;
  final Value<String?> customerName;
  final Value<String?> customerPhone;
  final Value<int> totalPaise;
  final Value<int> changePaise;
  final Value<DateTime> billedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.billNo = const Value.absent(),
    this.counterId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.totalPaise = const Value.absent(),
    this.changePaise = const Value.absent(),
    this.billedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillsCompanion.insert({
    required String id,
    required String billNo,
    required String counterId,
    required String cashierId,
    this.shiftId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    required int totalPaise,
    required int changePaise,
    required DateTime billedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       billNo = Value(billNo),
       counterId = Value(counterId),
       cashierId = Value(cashierId),
       totalPaise = Value(totalPaise),
       changePaise = Value(changePaise),
       billedAt = Value(billedAt),
       createdAt = Value(createdAt);
  static Insertable<BillRow> custom({
    Expression<String>? id,
    Expression<String>? billNo,
    Expression<String>? counterId,
    Expression<String>? cashierId,
    Expression<String>? shiftId,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<int>? totalPaise,
    Expression<int>? changePaise,
    Expression<DateTime>? billedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billNo != null) 'bill_no': billNo,
      if (counterId != null) 'counter_id': counterId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (shiftId != null) 'shift_id': shiftId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (totalPaise != null) 'total_paise': totalPaise,
      if (changePaise != null) 'change_paise': changePaise,
      if (billedAt != null) 'billed_at': billedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillsCompanion copyWith({
    Value<String>? id,
    Value<String>? billNo,
    Value<String>? counterId,
    Value<String>? cashierId,
    Value<String?>? shiftId,
    Value<String?>? customerName,
    Value<String?>? customerPhone,
    Value<int>? totalPaise,
    Value<int>? changePaise,
    Value<DateTime>? billedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BillsCompanion(
      id: id ?? this.id,
      billNo: billNo ?? this.billNo,
      counterId: counterId ?? this.counterId,
      cashierId: cashierId ?? this.cashierId,
      shiftId: shiftId ?? this.shiftId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalPaise: totalPaise ?? this.totalPaise,
      changePaise: changePaise ?? this.changePaise,
      billedAt: billedAt ?? this.billedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (billNo.present) {
      map['bill_no'] = Variable<String>(billNo.value);
    }
    if (counterId.present) {
      map['counter_id'] = Variable<String>(counterId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (totalPaise.present) {
      map['total_paise'] = Variable<int>(totalPaise.value);
    }
    if (changePaise.present) {
      map['change_paise'] = Variable<int>(changePaise.value);
    }
    if (billedAt.present) {
      map['billed_at'] = Variable<DateTime>(billedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('billNo: $billNo, ')
          ..write('counterId: $counterId, ')
          ..write('cashierId: $cashierId, ')
          ..write('shiftId: $shiftId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('totalPaise: $totalPaise, ')
          ..write('changePaise: $changePaise, ')
          ..write('billedAt: $billedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditNotesTable extends CreditNotes
    with TableInfo<$CreditNotesTable, CreditNoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _counterIdMeta = const VerificationMeta(
    'counterId',
  );
  @override
  late final GeneratedColumn<String> counterId = GeneratedColumn<String>(
    'counter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counters (id)',
    ),
  );
  static const VerificationMeta _serialMeta = const VerificationMeta('serial');
  @override
  late final GeneratedColumn<int> serial = GeneratedColumn<int>(
    'serial',
    aliasedName,
    false,
    check: () => ComparableExpr(serial).isBetweenValues(1, 99999),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(amountPaise).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedByMeta = const VerificationMeta(
    'issuedBy',
  );
  @override
  late final GeneratedColumn<String> issuedBy = GeneratedColumn<String>(
    'issued_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    counterId,
    serial,
    amountPaise,
    issuedAt,
    issuedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditNoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('counter_id')) {
      context.handle(
        _counterIdMeta,
        counterId.isAcceptableOrUnknown(data['counter_id']!, _counterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_counterIdMeta);
    }
    if (data.containsKey('serial')) {
      context.handle(
        _serialMeta,
        serial.isAcceptableOrUnknown(data['serial']!, _serialMeta),
      );
    } else if (isInserting) {
      context.missing(_serialMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('issued_by')) {
      context.handle(
        _issuedByMeta,
        issuedBy.isAcceptableOrUnknown(data['issued_by']!, _issuedByMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedByMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {counterId, serial},
  ];
  @override
  CreditNoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditNoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      counterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_id'],
      )!,
      serial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}serial'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      issuedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issued_by'],
      )!,
    );
  }

  @override
  $CreditNotesTable createAlias(String alias) {
    return $CreditNotesTable(attachedDatabase, alias);
  }
}

class CreditNoteRow extends DataClass implements Insertable<CreditNoteRow> {
  final String id;
  final String code;
  final String counterId;
  final int serial;
  final int amountPaise;
  final DateTime issuedAt;
  final String issuedBy;
  const CreditNoteRow({
    required this.id,
    required this.code,
    required this.counterId,
    required this.serial,
    required this.amountPaise,
    required this.issuedAt,
    required this.issuedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['counter_id'] = Variable<String>(counterId);
    map['serial'] = Variable<int>(serial);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    map['issued_by'] = Variable<String>(issuedBy);
    return map;
  }

  CreditNotesCompanion toCompanion(bool nullToAbsent) {
    return CreditNotesCompanion(
      id: Value(id),
      code: Value(code),
      counterId: Value(counterId),
      serial: Value(serial),
      amountPaise: Value(amountPaise),
      issuedAt: Value(issuedAt),
      issuedBy: Value(issuedBy),
    );
  }

  factory CreditNoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditNoteRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      counterId: serializer.fromJson<String>(json['counterId']),
      serial: serializer.fromJson<int>(json['serial']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      issuedBy: serializer.fromJson<String>(json['issuedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'counterId': serializer.toJson<String>(counterId),
      'serial': serializer.toJson<int>(serial),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'issuedBy': serializer.toJson<String>(issuedBy),
    };
  }

  CreditNoteRow copyWith({
    String? id,
    String? code,
    String? counterId,
    int? serial,
    int? amountPaise,
    DateTime? issuedAt,
    String? issuedBy,
  }) => CreditNoteRow(
    id: id ?? this.id,
    code: code ?? this.code,
    counterId: counterId ?? this.counterId,
    serial: serial ?? this.serial,
    amountPaise: amountPaise ?? this.amountPaise,
    issuedAt: issuedAt ?? this.issuedAt,
    issuedBy: issuedBy ?? this.issuedBy,
  );
  CreditNoteRow copyWithCompanion(CreditNotesCompanion data) {
    return CreditNoteRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      counterId: data.counterId.present ? data.counterId.value : this.counterId,
      serial: data.serial.present ? data.serial.value : this.serial,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      issuedBy: data.issuedBy.present ? data.issuedBy.value : this.issuedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditNoteRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('counterId: $counterId, ')
          ..write('serial: $serial, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('issuedBy: $issuedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, counterId, serial, amountPaise, issuedAt, issuedBy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditNoteRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.counterId == this.counterId &&
          other.serial == this.serial &&
          other.amountPaise == this.amountPaise &&
          other.issuedAt == this.issuedAt &&
          other.issuedBy == this.issuedBy);
}

class CreditNotesCompanion extends UpdateCompanion<CreditNoteRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> counterId;
  final Value<int> serial;
  final Value<int> amountPaise;
  final Value<DateTime> issuedAt;
  final Value<String> issuedBy;
  final Value<int> rowid;
  const CreditNotesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.counterId = const Value.absent(),
    this.serial = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.issuedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditNotesCompanion.insert({
    required String id,
    required String code,
    required String counterId,
    required int serial,
    required int amountPaise,
    required DateTime issuedAt,
    required String issuedBy,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       counterId = Value(counterId),
       serial = Value(serial),
       amountPaise = Value(amountPaise),
       issuedAt = Value(issuedAt),
       issuedBy = Value(issuedBy);
  static Insertable<CreditNoteRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? counterId,
    Expression<int>? serial,
    Expression<int>? amountPaise,
    Expression<DateTime>? issuedAt,
    Expression<String>? issuedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (counterId != null) 'counter_id': counterId,
      if (serial != null) 'serial': serial,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (issuedBy != null) 'issued_by': issuedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? counterId,
    Value<int>? serial,
    Value<int>? amountPaise,
    Value<DateTime>? issuedAt,
    Value<String>? issuedBy,
    Value<int>? rowid,
  }) {
    return CreditNotesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      counterId: counterId ?? this.counterId,
      serial: serial ?? this.serial,
      amountPaise: amountPaise ?? this.amountPaise,
      issuedAt: issuedAt ?? this.issuedAt,
      issuedBy: issuedBy ?? this.issuedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (counterId.present) {
      map['counter_id'] = Variable<String>(counterId.value);
    }
    if (serial.present) {
      map['serial'] = Variable<int>(serial.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (issuedBy.present) {
      map['issued_by'] = Variable<String>(issuedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditNotesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('counterId: $counterId, ')
          ..write('serial: $serial, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('issuedBy: $issuedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReturnsTable extends Returns with TableInfo<$ReturnsTable, ReturnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReturnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _refundModeMeta = const VerificationMeta(
    'refundMode',
  );
  @override
  late final GeneratedColumn<String> refundMode = GeneratedColumn<String>(
    'refund_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (refund_mode IN (\'cash\', \'upi\', \'card\', \'credit_note\'))',
  );
  static const VerificationMeta _creditNoteIdMeta = const VerificationMeta(
    'creditNoteId',
  );
  @override
  late final GeneratedColumn<String> creditNoteId = GeneratedColumn<String>(
    'credit_note_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES credit_notes (id)',
    ),
  );
  static const VerificationMeta _totalPaiseMeta = const VerificationMeta(
    'totalPaise',
  );
  @override
  late final GeneratedColumn<int> totalPaise = GeneratedColumn<int>(
    'total_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(totalPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _returnedAtMeta = const VerificationMeta(
    'returnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> returnedAt = GeneratedColumn<DateTime>(
    'returned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cashierId,
    shiftId,
    approvedBy,
    refundMode,
    creditNoteId,
    totalPaise,
    returnedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'returns';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReturnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('refund_mode')) {
      context.handle(
        _refundModeMeta,
        refundMode.isAcceptableOrUnknown(data['refund_mode']!, _refundModeMeta),
      );
    } else if (isInserting) {
      context.missing(_refundModeMeta);
    }
    if (data.containsKey('credit_note_id')) {
      context.handle(
        _creditNoteIdMeta,
        creditNoteId.isAcceptableOrUnknown(
          data['credit_note_id']!,
          _creditNoteIdMeta,
        ),
      );
    }
    if (data.containsKey('total_paise')) {
      context.handle(
        _totalPaiseMeta,
        totalPaise.isAcceptableOrUnknown(data['total_paise']!, _totalPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPaiseMeta);
    }
    if (data.containsKey('returned_at')) {
      context.handle(
        _returnedAtMeta,
        returnedAt.isAcceptableOrUnknown(data['returned_at']!, _returnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_returnedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReturnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReturnRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      refundMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_mode'],
      )!,
      creditNoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_note_id'],
      ),
      totalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_paise'],
      )!,
      returnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}returned_at'],
      )!,
    );
  }

  @override
  $ReturnsTable createAlias(String alias) {
    return $ReturnsTable(attachedDatabase, alias);
  }
}

class ReturnRow extends DataClass implements Insertable<ReturnRow> {
  final String id;
  final String cashierId;
  final String? shiftId;
  final String? approvedBy;
  final String refundMode;
  final String? creditNoteId;
  final int totalPaise;
  final DateTime returnedAt;
  const ReturnRow({
    required this.id,
    required this.cashierId,
    this.shiftId,
    this.approvedBy,
    required this.refundMode,
    this.creditNoteId,
    required this.totalPaise,
    required this.returnedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    map['refund_mode'] = Variable<String>(refundMode);
    if (!nullToAbsent || creditNoteId != null) {
      map['credit_note_id'] = Variable<String>(creditNoteId);
    }
    map['total_paise'] = Variable<int>(totalPaise);
    map['returned_at'] = Variable<DateTime>(returnedAt);
    return map;
  }

  ReturnsCompanion toCompanion(bool nullToAbsent) {
    return ReturnsCompanion(
      id: Value(id),
      cashierId: Value(cashierId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
      refundMode: Value(refundMode),
      creditNoteId: creditNoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(creditNoteId),
      totalPaise: Value(totalPaise),
      returnedAt: Value(returnedAt),
    );
  }

  factory ReturnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReturnRow(
      id: serializer.fromJson<String>(json['id']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      refundMode: serializer.fromJson<String>(json['refundMode']),
      creditNoteId: serializer.fromJson<String?>(json['creditNoteId']),
      totalPaise: serializer.fromJson<int>(json['totalPaise']),
      returnedAt: serializer.fromJson<DateTime>(json['returnedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cashierId': serializer.toJson<String>(cashierId),
      'shiftId': serializer.toJson<String?>(shiftId),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'refundMode': serializer.toJson<String>(refundMode),
      'creditNoteId': serializer.toJson<String?>(creditNoteId),
      'totalPaise': serializer.toJson<int>(totalPaise),
      'returnedAt': serializer.toJson<DateTime>(returnedAt),
    };
  }

  ReturnRow copyWith({
    String? id,
    String? cashierId,
    Value<String?> shiftId = const Value.absent(),
    Value<String?> approvedBy = const Value.absent(),
    String? refundMode,
    Value<String?> creditNoteId = const Value.absent(),
    int? totalPaise,
    DateTime? returnedAt,
  }) => ReturnRow(
    id: id ?? this.id,
    cashierId: cashierId ?? this.cashierId,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    refundMode: refundMode ?? this.refundMode,
    creditNoteId: creditNoteId.present ? creditNoteId.value : this.creditNoteId,
    totalPaise: totalPaise ?? this.totalPaise,
    returnedAt: returnedAt ?? this.returnedAt,
  );
  ReturnRow copyWithCompanion(ReturnsCompanion data) {
    return ReturnRow(
      id: data.id.present ? data.id.value : this.id,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      refundMode: data.refundMode.present
          ? data.refundMode.value
          : this.refundMode,
      creditNoteId: data.creditNoteId.present
          ? data.creditNoteId.value
          : this.creditNoteId,
      totalPaise: data.totalPaise.present
          ? data.totalPaise.value
          : this.totalPaise,
      returnedAt: data.returnedAt.present
          ? data.returnedAt.value
          : this.returnedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReturnRow(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('shiftId: $shiftId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('refundMode: $refundMode, ')
          ..write('creditNoteId: $creditNoteId, ')
          ..write('totalPaise: $totalPaise, ')
          ..write('returnedAt: $returnedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cashierId,
    shiftId,
    approvedBy,
    refundMode,
    creditNoteId,
    totalPaise,
    returnedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReturnRow &&
          other.id == this.id &&
          other.cashierId == this.cashierId &&
          other.shiftId == this.shiftId &&
          other.approvedBy == this.approvedBy &&
          other.refundMode == this.refundMode &&
          other.creditNoteId == this.creditNoteId &&
          other.totalPaise == this.totalPaise &&
          other.returnedAt == this.returnedAt);
}

class ReturnsCompanion extends UpdateCompanion<ReturnRow> {
  final Value<String> id;
  final Value<String> cashierId;
  final Value<String?> shiftId;
  final Value<String?> approvedBy;
  final Value<String> refundMode;
  final Value<String?> creditNoteId;
  final Value<int> totalPaise;
  final Value<DateTime> returnedAt;
  final Value<int> rowid;
  const ReturnsCompanion({
    this.id = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.refundMode = const Value.absent(),
    this.creditNoteId = const Value.absent(),
    this.totalPaise = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReturnsCompanion.insert({
    required String id,
    required String cashierId,
    this.shiftId = const Value.absent(),
    this.approvedBy = const Value.absent(),
    required String refundMode,
    this.creditNoteId = const Value.absent(),
    required int totalPaise,
    required DateTime returnedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cashierId = Value(cashierId),
       refundMode = Value(refundMode),
       totalPaise = Value(totalPaise),
       returnedAt = Value(returnedAt);
  static Insertable<ReturnRow> custom({
    Expression<String>? id,
    Expression<String>? cashierId,
    Expression<String>? shiftId,
    Expression<String>? approvedBy,
    Expression<String>? refundMode,
    Expression<String>? creditNoteId,
    Expression<int>? totalPaise,
    Expression<DateTime>? returnedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cashierId != null) 'cashier_id': cashierId,
      if (shiftId != null) 'shift_id': shiftId,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (refundMode != null) 'refund_mode': refundMode,
      if (creditNoteId != null) 'credit_note_id': creditNoteId,
      if (totalPaise != null) 'total_paise': totalPaise,
      if (returnedAt != null) 'returned_at': returnedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReturnsCompanion copyWith({
    Value<String>? id,
    Value<String>? cashierId,
    Value<String?>? shiftId,
    Value<String?>? approvedBy,
    Value<String>? refundMode,
    Value<String?>? creditNoteId,
    Value<int>? totalPaise,
    Value<DateTime>? returnedAt,
    Value<int>? rowid,
  }) {
    return ReturnsCompanion(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      shiftId: shiftId ?? this.shiftId,
      approvedBy: approvedBy ?? this.approvedBy,
      refundMode: refundMode ?? this.refundMode,
      creditNoteId: creditNoteId ?? this.creditNoteId,
      totalPaise: totalPaise ?? this.totalPaise,
      returnedAt: returnedAt ?? this.returnedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (refundMode.present) {
      map['refund_mode'] = Variable<String>(refundMode.value);
    }
    if (creditNoteId.present) {
      map['credit_note_id'] = Variable<String>(creditNoteId.value);
    }
    if (totalPaise.present) {
      map['total_paise'] = Variable<int>(totalPaise.value);
    }
    if (returnedAt.present) {
      map['returned_at'] = Variable<DateTime>(returnedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReturnsCompanion(')
          ..write('id: $id, ')
          ..write('cashierId: $cashierId, ')
          ..write('shiftId: $shiftId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('refundMode: $refundMode, ')
          ..write('creditNoteId: $creditNoteId, ')
          ..write('totalPaise: $totalPaise, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuesLedgerTable extends DuesLedger
    with TableInfo<$DuesLedgerTable, DuesLedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuesLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (id)',
    ),
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bills (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'OWED\', \'PAYMENT\', \'RETURN_OFFSET\', \'WRITE_OFF\'))',
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    check: () => BooleanExpressionOperators(amountPaise.equals(0)).not(),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dues_receipts (id)',
    ),
  );
  static const VerificationMeta _returnIdMeta = const VerificationMeta(
    'returnId',
  );
  @override
  late final GeneratedColumn<String> returnId = GeneratedColumn<String>(
    'return_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES returns (id)',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    billId,
    kind,
    amountPaise,
    receiptId,
    returnId,
    at,
    actorId,
    approvedBy,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dues_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<DuesLedgerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    }
    if (data.containsKey('return_id')) {
      context.handle(
        _returnIdMeta,
        returnId.isAcceptableOrUnknown(data['return_id']!, _returnIdMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actorIdMeta);
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DuesLedgerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuesLedgerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      ),
      returnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}return_id'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $DuesLedgerTable createAlias(String alias) {
    return $DuesLedgerTable(attachedDatabase, alias);
  }
}

class DuesLedgerRow extends DataClass implements Insertable<DuesLedgerRow> {
  final String id;
  final String customerId;
  final String billId;
  final String kind;

  /// Positive when it adds to what is owed (OWED), negative when it takes off.
  final int amountPaise;
  final String? receiptId;
  final String? returnId;
  final DateTime at;
  final String actorId;

  /// For OWED: the manager or owner who allowed it.
  final String? approvedBy;

  /// For WRITE_OFF: why (required).
  final String? note;
  const DuesLedgerRow({
    required this.id,
    required this.customerId,
    required this.billId,
    required this.kind,
    required this.amountPaise,
    this.receiptId,
    this.returnId,
    required this.at,
    required this.actorId,
    this.approvedBy,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['bill_id'] = Variable<String>(billId);
    map['kind'] = Variable<String>(kind);
    map['amount_paise'] = Variable<int>(amountPaise);
    if (!nullToAbsent || receiptId != null) {
      map['receipt_id'] = Variable<String>(receiptId);
    }
    if (!nullToAbsent || returnId != null) {
      map['return_id'] = Variable<String>(returnId);
    }
    map['at'] = Variable<DateTime>(at);
    map['actor_id'] = Variable<String>(actorId);
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  DuesLedgerCompanion toCompanion(bool nullToAbsent) {
    return DuesLedgerCompanion(
      id: Value(id),
      customerId: Value(customerId),
      billId: Value(billId),
      kind: Value(kind),
      amountPaise: Value(amountPaise),
      receiptId: receiptId == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptId),
      returnId: returnId == null && nullToAbsent
          ? const Value.absent()
          : Value(returnId),
      at: Value(at),
      actorId: Value(actorId),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory DuesLedgerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuesLedgerRow(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      billId: serializer.fromJson<String>(json['billId']),
      kind: serializer.fromJson<String>(json['kind']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      receiptId: serializer.fromJson<String?>(json['receiptId']),
      returnId: serializer.fromJson<String?>(json['returnId']),
      at: serializer.fromJson<DateTime>(json['at']),
      actorId: serializer.fromJson<String>(json['actorId']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'billId': serializer.toJson<String>(billId),
      'kind': serializer.toJson<String>(kind),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'receiptId': serializer.toJson<String?>(receiptId),
      'returnId': serializer.toJson<String?>(returnId),
      'at': serializer.toJson<DateTime>(at),
      'actorId': serializer.toJson<String>(actorId),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'note': serializer.toJson<String?>(note),
    };
  }

  DuesLedgerRow copyWith({
    String? id,
    String? customerId,
    String? billId,
    String? kind,
    int? amountPaise,
    Value<String?> receiptId = const Value.absent(),
    Value<String?> returnId = const Value.absent(),
    DateTime? at,
    String? actorId,
    Value<String?> approvedBy = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => DuesLedgerRow(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    billId: billId ?? this.billId,
    kind: kind ?? this.kind,
    amountPaise: amountPaise ?? this.amountPaise,
    receiptId: receiptId.present ? receiptId.value : this.receiptId,
    returnId: returnId.present ? returnId.value : this.returnId,
    at: at ?? this.at,
    actorId: actorId ?? this.actorId,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    note: note.present ? note.value : this.note,
  );
  DuesLedgerRow copyWithCompanion(DuesLedgerCompanion data) {
    return DuesLedgerRow(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      billId: data.billId.present ? data.billId.value : this.billId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      returnId: data.returnId.present ? data.returnId.value : this.returnId,
      at: data.at.present ? data.at.value : this.at,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuesLedgerRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('billId: $billId, ')
          ..write('kind: $kind, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('receiptId: $receiptId, ')
          ..write('returnId: $returnId, ')
          ..write('at: $at, ')
          ..write('actorId: $actorId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    billId,
    kind,
    amountPaise,
    receiptId,
    returnId,
    at,
    actorId,
    approvedBy,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuesLedgerRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.billId == this.billId &&
          other.kind == this.kind &&
          other.amountPaise == this.amountPaise &&
          other.receiptId == this.receiptId &&
          other.returnId == this.returnId &&
          other.at == this.at &&
          other.actorId == this.actorId &&
          other.approvedBy == this.approvedBy &&
          other.note == this.note);
}

class DuesLedgerCompanion extends UpdateCompanion<DuesLedgerRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> billId;
  final Value<String> kind;
  final Value<int> amountPaise;
  final Value<String?> receiptId;
  final Value<String?> returnId;
  final Value<DateTime> at;
  final Value<String> actorId;
  final Value<String?> approvedBy;
  final Value<String?> note;
  final Value<int> rowid;
  const DuesLedgerCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.billId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.returnId = const Value.absent(),
    this.at = const Value.absent(),
    this.actorId = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuesLedgerCompanion.insert({
    required String id,
    required String customerId,
    required String billId,
    required String kind,
    required int amountPaise,
    this.receiptId = const Value.absent(),
    this.returnId = const Value.absent(),
    required DateTime at,
    required String actorId,
    this.approvedBy = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       billId = Value(billId),
       kind = Value(kind),
       amountPaise = Value(amountPaise),
       at = Value(at),
       actorId = Value(actorId);
  static Insertable<DuesLedgerRow> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? billId,
    Expression<String>? kind,
    Expression<int>? amountPaise,
    Expression<String>? receiptId,
    Expression<String>? returnId,
    Expression<DateTime>? at,
    Expression<String>? actorId,
    Expression<String>? approvedBy,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (billId != null) 'bill_id': billId,
      if (kind != null) 'kind': kind,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (receiptId != null) 'receipt_id': receiptId,
      if (returnId != null) 'return_id': returnId,
      if (at != null) 'at': at,
      if (actorId != null) 'actor_id': actorId,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuesLedgerCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String>? billId,
    Value<String>? kind,
    Value<int>? amountPaise,
    Value<String?>? receiptId,
    Value<String?>? returnId,
    Value<DateTime>? at,
    Value<String>? actorId,
    Value<String?>? approvedBy,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return DuesLedgerCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      billId: billId ?? this.billId,
      kind: kind ?? this.kind,
      amountPaise: amountPaise ?? this.amountPaise,
      receiptId: receiptId ?? this.receiptId,
      returnId: returnId ?? this.returnId,
      at: at ?? this.at,
      actorId: actorId ?? this.actorId,
      approvedBy: approvedBy ?? this.approvedBy,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (returnId.present) {
      map['return_id'] = Variable<String>(returnId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DuesLedgerCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('billId: $billId, ')
          ..write('kind: $kind, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('receiptId: $receiptId, ')
          ..write('returnId: $returnId, ')
          ..write('at: $at, ')
          ..write('actorId: $actorId, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VariantsTable extends Variants
    with TableInfo<$VariantsTable, VariantRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<String> size = GeneratedColumn<String>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mrpPaiseMeta = const VerificationMeta(
    'mrpPaise',
  );
  @override
  late final GeneratedColumn<int> mrpPaise = GeneratedColumn<int>(
    'mrp_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(mrpPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    size,
    color,
    mrpPaise,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<VariantRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('mrp_paise')) {
      context.handle(
        _mrpPaiseMeta,
        mrpPaise.isAcceptableOrUnknown(data['mrp_paise']!, _mrpPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_mrpPaiseMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {productId, size, color},
  ];
  @override
  VariantRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VariantRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      mrpPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mrp_paise'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VariantsTable createAlias(String alias) {
    return $VariantsTable(attachedDatabase, alias);
  }
}

class VariantRow extends DataClass implements Insertable<VariantRow> {
  final String id;
  final String productId;
  final String size;
  final String color;
  final int mrpPaise;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VariantRow({
    required this.id,
    required this.productId,
    required this.size,
    required this.color,
    required this.mrpPaise,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['size'] = Variable<String>(size);
    map['color'] = Variable<String>(color);
    map['mrp_paise'] = Variable<int>(mrpPaise);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VariantsCompanion toCompanion(bool nullToAbsent) {
    return VariantsCompanion(
      id: Value(id),
      productId: Value(productId),
      size: Value(size),
      color: Value(color),
      mrpPaise: Value(mrpPaise),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VariantRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VariantRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      size: serializer.fromJson<String>(json['size']),
      color: serializer.fromJson<String>(json['color']),
      mrpPaise: serializer.fromJson<int>(json['mrpPaise']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'size': serializer.toJson<String>(size),
      'color': serializer.toJson<String>(color),
      'mrpPaise': serializer.toJson<int>(mrpPaise),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VariantRow copyWith({
    String? id,
    String? productId,
    String? size,
    String? color,
    int? mrpPaise,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VariantRow(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    size: size ?? this.size,
    color: color ?? this.color,
    mrpPaise: mrpPaise ?? this.mrpPaise,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VariantRow copyWithCompanion(VariantsCompanion data) {
    return VariantRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      size: data.size.present ? data.size.value : this.size,
      color: data.color.present ? data.color.value : this.color,
      mrpPaise: data.mrpPaise.present ? data.mrpPaise.value : this.mrpPaise,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VariantRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('size: $size, ')
          ..write('color: $color, ')
          ..write('mrpPaise: $mrpPaise, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, size, color, mrpPaise, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VariantRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.size == this.size &&
          other.color == this.color &&
          other.mrpPaise == this.mrpPaise &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VariantsCompanion extends UpdateCompanion<VariantRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> size;
  final Value<String> color;
  final Value<int> mrpPaise;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VariantsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.size = const Value.absent(),
    this.color = const Value.absent(),
    this.mrpPaise = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VariantsCompanion.insert({
    required String id,
    required String productId,
    required String size,
    required String color,
    required int mrpPaise,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       size = Value(size),
       color = Value(color),
       mrpPaise = Value(mrpPaise),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VariantRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? size,
    Expression<String>? color,
    Expression<int>? mrpPaise,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (mrpPaise != null) 'mrp_paise': mrpPaise,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VariantsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? size,
    Value<String>? color,
    Value<int>? mrpPaise,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VariantsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      size: size ?? this.size,
      color: color ?? this.color,
      mrpPaise: mrpPaise ?? this.mrpPaise,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (size.present) {
      map['size'] = Variable<String>(size.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (mrpPaise.present) {
      map['mrp_paise'] = Variable<int>(mrpPaise.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VariantsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('size: $size, ')
          ..write('color: $color, ')
          ..write('mrpPaise: $mrpPaise, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BatchesTable extends Batches with TableInfo<$BatchesTable, BatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supplierMeta = const VerificationMeta(
    'supplier',
  );
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
    'supplier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lotMeta = const VerificationMeta('lot');
  @override
  late final GeneratedColumn<int> lot = GeneratedColumn<int>(
    'lot',
    aliasedName,
    false,
    check: () => ComparableExpr(lot).isBetweenValues(0, 999),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasedAtMeta = const VerificationMeta(
    'purchasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
    'purchased_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supplier,
    lot,
    purchasedAt,
    createdBy,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('supplier')) {
      context.handle(
        _supplierMeta,
        supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta),
      );
    } else if (isInserting) {
      context.missing(_supplierMeta);
    }
    if (data.containsKey('lot')) {
      context.handle(
        _lotMeta,
        lot.isAcceptableOrUnknown(data['lot']!, _lotMeta),
      );
    } else if (isInserting) {
      context.missing(_lotMeta);
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
        _purchasedAtMeta,
        purchasedAt.isAcceptableOrUnknown(
          data['purchased_at']!,
          _purchasedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasedAtMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      supplier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier'],
      )!,
      lot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lot'],
      )!,
      purchasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchased_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BatchesTable createAlias(String alias) {
    return $BatchesTable(attachedDatabase, alias);
  }
}

class BatchRow extends DataClass implements Insertable<BatchRow> {
  final String id;
  final String supplier;
  final int lot;
  final DateTime purchasedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BatchRow({
    required this.id,
    required this.supplier,
    required this.lot,
    required this.purchasedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['supplier'] = Variable<String>(supplier);
    map['lot'] = Variable<int>(lot);
    map['purchased_at'] = Variable<DateTime>(purchasedAt);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BatchesCompanion toCompanion(bool nullToAbsent) {
    return BatchesCompanion(
      id: Value(id),
      supplier: Value(supplier),
      lot: Value(lot),
      purchasedAt: Value(purchasedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchRow(
      id: serializer.fromJson<String>(json['id']),
      supplier: serializer.fromJson<String>(json['supplier']),
      lot: serializer.fromJson<int>(json['lot']),
      purchasedAt: serializer.fromJson<DateTime>(json['purchasedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'supplier': serializer.toJson<String>(supplier),
      'lot': serializer.toJson<int>(lot),
      'purchasedAt': serializer.toJson<DateTime>(purchasedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BatchRow copyWith({
    String? id,
    String? supplier,
    int? lot,
    DateTime? purchasedAt,
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BatchRow(
    id: id ?? this.id,
    supplier: supplier ?? this.supplier,
    lot: lot ?? this.lot,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BatchRow copyWithCompanion(BatchesCompanion data) {
    return BatchRow(
      id: data.id.present ? data.id.value : this.id,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      lot: data.lot.present ? data.lot.value : this.lot,
      purchasedAt: data.purchasedAt.present
          ? data.purchasedAt.value
          : this.purchasedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchRow(')
          ..write('id: $id, ')
          ..write('supplier: $supplier, ')
          ..write('lot: $lot, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supplier,
    lot,
    purchasedAt,
    createdBy,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchRow &&
          other.id == this.id &&
          other.supplier == this.supplier &&
          other.lot == this.lot &&
          other.purchasedAt == this.purchasedAt &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BatchesCompanion extends UpdateCompanion<BatchRow> {
  final Value<String> id;
  final Value<String> supplier;
  final Value<int> lot;
  final Value<DateTime> purchasedAt;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BatchesCompanion({
    this.id = const Value.absent(),
    this.supplier = const Value.absent(),
    this.lot = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchesCompanion.insert({
    required String id,
    required String supplier,
    required int lot,
    required DateTime purchasedAt,
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       supplier = Value(supplier),
       lot = Value(lot),
       purchasedAt = Value(purchasedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BatchRow> custom({
    Expression<String>? id,
    Expression<String>? supplier,
    Expression<int>? lot,
    Expression<DateTime>? purchasedAt,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supplier != null) 'supplier': supplier,
      if (lot != null) 'lot': lot,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? supplier,
    Value<int>? lot,
    Value<DateTime>? purchasedAt,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BatchesCompanion(
      id: id ?? this.id,
      supplier: supplier ?? this.supplier,
      lot: lot ?? this.lot,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (lot.present) {
      map['lot'] = Variable<int>(lot.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchesCompanion(')
          ..write('id: $id, ')
          ..write('supplier: $supplier, ')
          ..write('lot: $lot, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BatchLinesTable extends BatchLines
    with TableInfo<$BatchLinesTable, BatchLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (id)',
    ),
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES variants (id)',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    check: () => ComparableExpr(quantity).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitCostPaiseMeta = const VerificationMeta(
    'unitCostPaise',
  );
  @override
  late final GeneratedColumn<int> unitCostPaise = GeneratedColumn<int>(
    'unit_cost_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(unitCostPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    batchId,
    variantId,
    quantity,
    unitCostPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batch_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_cost_paise')) {
      context.handle(
        _unitCostPaiseMeta,
        unitCostPaise.isAcceptableOrUnknown(
          data['unit_cost_paise']!,
          _unitCostPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitCostPaiseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {batchId, variantId},
  ];
  @override
  BatchLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitCostPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_cost_paise'],
      )!,
    );
  }

  @override
  $BatchLinesTable createAlias(String alias) {
    return $BatchLinesTable(attachedDatabase, alias);
  }
}

class BatchLineRow extends DataClass implements Insertable<BatchLineRow> {
  final String id;
  final String batchId;
  final String variantId;
  final int quantity;
  final int unitCostPaise;
  const BatchLineRow({
    required this.id,
    required this.batchId,
    required this.variantId,
    required this.quantity,
    required this.unitCostPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['batch_id'] = Variable<String>(batchId);
    map['variant_id'] = Variable<String>(variantId);
    map['quantity'] = Variable<int>(quantity);
    map['unit_cost_paise'] = Variable<int>(unitCostPaise);
    return map;
  }

  BatchLinesCompanion toCompanion(bool nullToAbsent) {
    return BatchLinesCompanion(
      id: Value(id),
      batchId: Value(batchId),
      variantId: Value(variantId),
      quantity: Value(quantity),
      unitCostPaise: Value(unitCostPaise),
    );
  }

  factory BatchLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchLineRow(
      id: serializer.fromJson<String>(json['id']),
      batchId: serializer.fromJson<String>(json['batchId']),
      variantId: serializer.fromJson<String>(json['variantId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitCostPaise: serializer.fromJson<int>(json['unitCostPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'batchId': serializer.toJson<String>(batchId),
      'variantId': serializer.toJson<String>(variantId),
      'quantity': serializer.toJson<int>(quantity),
      'unitCostPaise': serializer.toJson<int>(unitCostPaise),
    };
  }

  BatchLineRow copyWith({
    String? id,
    String? batchId,
    String? variantId,
    int? quantity,
    int? unitCostPaise,
  }) => BatchLineRow(
    id: id ?? this.id,
    batchId: batchId ?? this.batchId,
    variantId: variantId ?? this.variantId,
    quantity: quantity ?? this.quantity,
    unitCostPaise: unitCostPaise ?? this.unitCostPaise,
  );
  BatchLineRow copyWithCompanion(BatchLinesCompanion data) {
    return BatchLineRow(
      id: data.id.present ? data.id.value : this.id,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCostPaise: data.unitCostPaise.present
          ? data.unitCostPaise.value
          : this.unitCostPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchLineRow(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('variantId: $variantId, ')
          ..write('quantity: $quantity, ')
          ..write('unitCostPaise: $unitCostPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, batchId, variantId, quantity, unitCostPaise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchLineRow &&
          other.id == this.id &&
          other.batchId == this.batchId &&
          other.variantId == this.variantId &&
          other.quantity == this.quantity &&
          other.unitCostPaise == this.unitCostPaise);
}

class BatchLinesCompanion extends UpdateCompanion<BatchLineRow> {
  final Value<String> id;
  final Value<String> batchId;
  final Value<String> variantId;
  final Value<int> quantity;
  final Value<int> unitCostPaise;
  final Value<int> rowid;
  const BatchLinesCompanion({
    this.id = const Value.absent(),
    this.batchId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCostPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchLinesCompanion.insert({
    required String id,
    required String batchId,
    required String variantId,
    required int quantity,
    required int unitCostPaise,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       batchId = Value(batchId),
       variantId = Value(variantId),
       quantity = Value(quantity),
       unitCostPaise = Value(unitCostPaise);
  static Insertable<BatchLineRow> custom({
    Expression<String>? id,
    Expression<String>? batchId,
    Expression<String>? variantId,
    Expression<int>? quantity,
    Expression<int>? unitCostPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (batchId != null) 'batch_id': batchId,
      if (variantId != null) 'variant_id': variantId,
      if (quantity != null) 'quantity': quantity,
      if (unitCostPaise != null) 'unit_cost_paise': unitCostPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? batchId,
    Value<String>? variantId,
    Value<int>? quantity,
    Value<int>? unitCostPaise,
    Value<int>? rowid,
  }) {
    return BatchLinesCompanion(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      unitCostPaise: unitCostPaise ?? this.unitCostPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitCostPaise.present) {
      map['unit_cost_paise'] = Variable<int>(unitCostPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchLinesCompanion(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('variantId: $variantId, ')
          ..write('quantity: $quantity, ')
          ..write('unitCostPaise: $unitCostPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArticlesTable extends Articles
    with TableInfo<$ArticlesTable, ArticleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeValueMeta = const VerificationMeta(
    'barcodeValue',
  );
  @override
  late final GeneratedColumn<String> barcodeValue = GeneratedColumn<String>(
    'barcode_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (length(barcode_value) = 12 AND barcode_value NOT GLOB \'*[^0-9]*\')',
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES variants (id)',
    ),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (id)',
    ),
  );
  static const VerificationMeta _mrpPaiseMeta = const VerificationMeta(
    'mrpPaise',
  );
  @override
  late final GeneratedColumn<int> mrpPaise = GeneratedColumn<int>(
    'mrp_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(mrpPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'IN_STOCK\', \'SOLD\', \'RETURNED\', \'DAMAGED\'))',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    barcodeValue,
    variantId,
    batchId,
    mrpPaise,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('barcode_value')) {
      context.handle(
        _barcodeValueMeta,
        barcodeValue.isAcceptableOrUnknown(
          data['barcode_value']!,
          _barcodeValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_barcodeValueMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('mrp_paise')) {
      context.handle(
        _mrpPaiseMeta,
        mrpPaise.isAcceptableOrUnknown(data['mrp_paise']!, _mrpPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_mrpPaiseMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArticleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      barcodeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_value'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      mrpPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mrp_paise'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ArticlesTable createAlias(String alias) {
    return $ArticlesTable(attachedDatabase, alias);
  }
}

class ArticleRow extends DataClass implements Insertable<ArticleRow> {
  final String id;
  final String barcodeValue;
  final String variantId;
  final String batchId;
  final int mrpPaise;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ArticleRow({
    required this.id,
    required this.barcodeValue,
    required this.variantId,
    required this.batchId,
    required this.mrpPaise,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['barcode_value'] = Variable<String>(barcodeValue);
    map['variant_id'] = Variable<String>(variantId);
    map['batch_id'] = Variable<String>(batchId);
    map['mrp_paise'] = Variable<int>(mrpPaise);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ArticlesCompanion toCompanion(bool nullToAbsent) {
    return ArticlesCompanion(
      id: Value(id),
      barcodeValue: Value(barcodeValue),
      variantId: Value(variantId),
      batchId: Value(batchId),
      mrpPaise: Value(mrpPaise),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ArticleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleRow(
      id: serializer.fromJson<String>(json['id']),
      barcodeValue: serializer.fromJson<String>(json['barcodeValue']),
      variantId: serializer.fromJson<String>(json['variantId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      mrpPaise: serializer.fromJson<int>(json['mrpPaise']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'barcodeValue': serializer.toJson<String>(barcodeValue),
      'variantId': serializer.toJson<String>(variantId),
      'batchId': serializer.toJson<String>(batchId),
      'mrpPaise': serializer.toJson<int>(mrpPaise),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ArticleRow copyWith({
    String? id,
    String? barcodeValue,
    String? variantId,
    String? batchId,
    int? mrpPaise,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ArticleRow(
    id: id ?? this.id,
    barcodeValue: barcodeValue ?? this.barcodeValue,
    variantId: variantId ?? this.variantId,
    batchId: batchId ?? this.batchId,
    mrpPaise: mrpPaise ?? this.mrpPaise,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ArticleRow copyWithCompanion(ArticlesCompanion data) {
    return ArticleRow(
      id: data.id.present ? data.id.value : this.id,
      barcodeValue: data.barcodeValue.present
          ? data.barcodeValue.value
          : this.barcodeValue,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      mrpPaise: data.mrpPaise.present ? data.mrpPaise.value : this.mrpPaise,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticleRow(')
          ..write('id: $id, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('variantId: $variantId, ')
          ..write('batchId: $batchId, ')
          ..write('mrpPaise: $mrpPaise, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    barcodeValue,
    variantId,
    batchId,
    mrpPaise,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticleRow &&
          other.id == this.id &&
          other.barcodeValue == this.barcodeValue &&
          other.variantId == this.variantId &&
          other.batchId == this.batchId &&
          other.mrpPaise == this.mrpPaise &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ArticlesCompanion extends UpdateCompanion<ArticleRow> {
  final Value<String> id;
  final Value<String> barcodeValue;
  final Value<String> variantId;
  final Value<String> batchId;
  final Value<int> mrpPaise;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ArticlesCompanion({
    this.id = const Value.absent(),
    this.barcodeValue = const Value.absent(),
    this.variantId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.mrpPaise = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArticlesCompanion.insert({
    required String id,
    required String barcodeValue,
    required String variantId,
    required String batchId,
    required int mrpPaise,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       barcodeValue = Value(barcodeValue),
       variantId = Value(variantId),
       batchId = Value(batchId),
       mrpPaise = Value(mrpPaise),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ArticleRow> custom({
    Expression<String>? id,
    Expression<String>? barcodeValue,
    Expression<String>? variantId,
    Expression<String>? batchId,
    Expression<int>? mrpPaise,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (barcodeValue != null) 'barcode_value': barcodeValue,
      if (variantId != null) 'variant_id': variantId,
      if (batchId != null) 'batch_id': batchId,
      if (mrpPaise != null) 'mrp_paise': mrpPaise,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArticlesCompanion copyWith({
    Value<String>? id,
    Value<String>? barcodeValue,
    Value<String>? variantId,
    Value<String>? batchId,
    Value<int>? mrpPaise,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ArticlesCompanion(
      id: id ?? this.id,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      variantId: variantId ?? this.variantId,
      batchId: batchId ?? this.batchId,
      mrpPaise: mrpPaise ?? this.mrpPaise,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (barcodeValue.present) {
      map['barcode_value'] = Variable<String>(barcodeValue.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (mrpPaise.present) {
      map['mrp_paise'] = Variable<int>(mrpPaise.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticlesCompanion(')
          ..write('id: $id, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('variantId: $variantId, ')
          ..write('batchId: $batchId, ')
          ..write('mrpPaise: $mrpPaise, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog with TableInfo<$AuditLogTable, AuditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    actor,
    action,
    entityType,
    entityId,
    details,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    } else if (isInserting) {
      context.missing(_detailsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      )!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditRow extends DataClass implements Insertable<AuditRow> {
  final String id;
  final DateTime at;
  final String? actor;
  final String action;
  final String entityType;
  final String entityId;
  final String details;
  const AuditRow({
    required this.id,
    required this.at,
    this.actor,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.details,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || actor != null) {
      map['actor'] = Variable<String>(actor);
    }
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['details'] = Variable<String>(details);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      at: Value(at),
      actor: actor == null && nullToAbsent
          ? const Value.absent()
          : Value(actor),
      action: Value(action),
      entityType: Value(entityType),
      entityId: Value(entityId),
      details: Value(details),
    );
  }

  factory AuditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditRow(
      id: serializer.fromJson<String>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      actor: serializer.fromJson<String?>(json['actor']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      details: serializer.fromJson<String>(json['details']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'at': serializer.toJson<DateTime>(at),
      'actor': serializer.toJson<String?>(actor),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'details': serializer.toJson<String>(details),
    };
  }

  AuditRow copyWith({
    String? id,
    DateTime? at,
    Value<String?> actor = const Value.absent(),
    String? action,
    String? entityType,
    String? entityId,
    String? details,
  }) => AuditRow(
    id: id ?? this.id,
    at: at ?? this.at,
    actor: actor.present ? actor.value : this.actor,
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    details: details ?? this.details,
  );
  AuditRow copyWithCompanion(AuditLogCompanion data) {
    return AuditRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      actor: data.actor.present ? data.actor.value : this.actor,
      action: data.action.present ? data.action.value : this.action,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      details: data.details.present ? data.details.value : this.details,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('actor: $actor, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('details: $details')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, at, actor, action, entityType, entityId, details);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.actor == this.actor &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.details == this.details);
}

class AuditLogCompanion extends UpdateCompanion<AuditRow> {
  final Value<String> id;
  final Value<DateTime> at;
  final Value<String?> actor;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> details;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.actor = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.details = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    required String id,
    required DateTime at,
    this.actor = const Value.absent(),
    required String action,
    required String entityType,
    required String entityId,
    required String details,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       at = Value(at),
       action = Value(action),
       entityType = Value(entityType),
       entityId = Value(entityId),
       details = Value(details);
  static Insertable<AuditRow> custom({
    Expression<String>? id,
    Expression<DateTime>? at,
    Expression<String>? actor,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? details,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (actor != null) 'actor': actor,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (details != null) 'details': details,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? at,
    Value<String?>? actor,
    Value<String>? action,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? details,
    Value<int>? rowid,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      actor: actor ?? this.actor,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      details: details ?? this.details,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('actor: $actor, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('details: $details, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    entityType,
    entityId,
    operation,
    payload,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final String id;
  final DateTime createdAt;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final DateTime? sentAt;
  const OutboxRow({
    required this.id,
    required this.createdAt,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
    };
  }

  OutboxRow copyWith({
    String? id,
    DateTime? createdAt,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    Value<DateTime?> sentAt = const Value.absent(),
  }) => OutboxRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    entityType,
    entityId,
    operation,
    payload,
    sentAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.sentAt == this.sentAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<DateTime?> sentAt;
  final Value<int> rowid;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String id,
    required DateTime createdAt,
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payload = Value(payload);
  static Insertable<OutboxRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<DateTime>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payload,
    Value<DateTime?>? sentAt,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillLinesTable extends BillLines
    with TableInfo<$BillLinesTable, BillLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bills (id)',
    ),
  );
  static const VerificationMeta _articleIdMeta = const VerificationMeta(
    'articleId',
  );
  @override
  late final GeneratedColumn<String> articleId = GeneratedColumn<String>(
    'article_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES articles (id)',
    ),
  );
  static const VerificationMeta _barcodeValueMeta = const VerificationMeta(
    'barcodeValue',
  );
  @override
  late final GeneratedColumn<String> barcodeValue = GeneratedColumn<String>(
    'barcode_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<String> size = GeneratedColumn<String>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mrpPaiseMeta = const VerificationMeta(
    'mrpPaise',
  );
  @override
  late final GeneratedColumn<int> mrpPaise = GeneratedColumn<int>(
    'mrp_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(mrpPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _markdownPaiseMeta = const VerificationMeta(
    'markdownPaise',
  );
  @override
  late final GeneratedColumn<int> markdownPaise = GeneratedColumn<int>(
    'markdown_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(markdownPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountPaiseMeta = const VerificationMeta(
    'discountPaise',
  );
  @override
  late final GeneratedColumn<int> discountPaise = GeneratedColumn<int>(
    'discount_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(discountPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalPaiseMeta = const VerificationMeta(
    'finalPaise',
  );
  @override
  late final GeneratedColumn<int> finalPaise = GeneratedColumn<int>(
    'final_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(finalPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gstBpMeta = const VerificationMeta('gstBp');
  @override
  late final GeneratedColumn<int> gstBp = GeneratedColumn<int>(
    'gst_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxablePaiseMeta = const VerificationMeta(
    'taxablePaise',
  );
  @override
  late final GeneratedColumn<int> taxablePaise = GeneratedColumn<int>(
    'taxable_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxPaiseMeta = const VerificationMeta(
    'taxPaise',
  );
  @override
  late final GeneratedColumn<int> taxPaise = GeneratedColumn<int>(
    'tax_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _extraTaxPaiseMeta = const VerificationMeta(
    'extraTaxPaise',
  );
  @override
  late final GeneratedColumn<int> extraTaxPaise = GeneratedColumn<int>(
    'extra_tax_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    billId,
    articleId,
    barcodeValue,
    productName,
    size,
    color,
    mrpPaise,
    markdownPaise,
    discountPaise,
    finalPaise,
    gstBp,
    taxablePaise,
    taxPaise,
    extraTaxPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('article_id')) {
      context.handle(
        _articleIdMeta,
        articleId.isAcceptableOrUnknown(data['article_id']!, _articleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdMeta);
    }
    if (data.containsKey('barcode_value')) {
      context.handle(
        _barcodeValueMeta,
        barcodeValue.isAcceptableOrUnknown(
          data['barcode_value']!,
          _barcodeValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_barcodeValueMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('mrp_paise')) {
      context.handle(
        _mrpPaiseMeta,
        mrpPaise.isAcceptableOrUnknown(data['mrp_paise']!, _mrpPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_mrpPaiseMeta);
    }
    if (data.containsKey('markdown_paise')) {
      context.handle(
        _markdownPaiseMeta,
        markdownPaise.isAcceptableOrUnknown(
          data['markdown_paise']!,
          _markdownPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_markdownPaiseMeta);
    }
    if (data.containsKey('discount_paise')) {
      context.handle(
        _discountPaiseMeta,
        discountPaise.isAcceptableOrUnknown(
          data['discount_paise']!,
          _discountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountPaiseMeta);
    }
    if (data.containsKey('final_paise')) {
      context.handle(
        _finalPaiseMeta,
        finalPaise.isAcceptableOrUnknown(data['final_paise']!, _finalPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_finalPaiseMeta);
    }
    if (data.containsKey('gst_bp')) {
      context.handle(
        _gstBpMeta,
        gstBp.isAcceptableOrUnknown(data['gst_bp']!, _gstBpMeta),
      );
    }
    if (data.containsKey('taxable_paise')) {
      context.handle(
        _taxablePaiseMeta,
        taxablePaise.isAcceptableOrUnknown(
          data['taxable_paise']!,
          _taxablePaiseMeta,
        ),
      );
    }
    if (data.containsKey('tax_paise')) {
      context.handle(
        _taxPaiseMeta,
        taxPaise.isAcceptableOrUnknown(data['tax_paise']!, _taxPaiseMeta),
      );
    }
    if (data.containsKey('extra_tax_paise')) {
      context.handle(
        _extraTaxPaiseMeta,
        extraTaxPaise.isAcceptableOrUnknown(
          data['extra_tax_paise']!,
          _extraTaxPaiseMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      articleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article_id'],
      )!,
      barcodeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_value'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      mrpPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mrp_paise'],
      )!,
      markdownPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}markdown_paise'],
      )!,
      discountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_paise'],
      )!,
      finalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_paise'],
      )!,
      gstBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gst_bp'],
      )!,
      taxablePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taxable_paise'],
      )!,
      taxPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_paise'],
      )!,
      extraTaxPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extra_tax_paise'],
      )!,
    );
  }

  @override
  $BillLinesTable createAlias(String alias) {
    return $BillLinesTable(attachedDatabase, alias);
  }
}

class BillLineRow extends DataClass implements Insertable<BillLineRow> {
  final String id;
  final String billId;
  final String articleId;
  final String barcodeValue;
  final String productName;
  final String size;
  final String color;
  final int mrpPaise;
  final int markdownPaise;
  final int discountPaise;
  final int finalPaise;

  /// The rate used, in basis points (500 is 5%); 0 when GST was off.
  final int gstBp;

  /// The value the tax was charged on.
  final int taxablePaise;

  /// The tax (CGST plus SGST).
  final int taxPaise;

  /// Tax added on top of the price (exclusive billing); 0 when the price
  /// included it.
  final int extraTaxPaise;
  const BillLineRow({
    required this.id,
    required this.billId,
    required this.articleId,
    required this.barcodeValue,
    required this.productName,
    required this.size,
    required this.color,
    required this.mrpPaise,
    required this.markdownPaise,
    required this.discountPaise,
    required this.finalPaise,
    required this.gstBp,
    required this.taxablePaise,
    required this.taxPaise,
    required this.extraTaxPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_id'] = Variable<String>(billId);
    map['article_id'] = Variable<String>(articleId);
    map['barcode_value'] = Variable<String>(barcodeValue);
    map['product_name'] = Variable<String>(productName);
    map['size'] = Variable<String>(size);
    map['color'] = Variable<String>(color);
    map['mrp_paise'] = Variable<int>(mrpPaise);
    map['markdown_paise'] = Variable<int>(markdownPaise);
    map['discount_paise'] = Variable<int>(discountPaise);
    map['final_paise'] = Variable<int>(finalPaise);
    map['gst_bp'] = Variable<int>(gstBp);
    map['taxable_paise'] = Variable<int>(taxablePaise);
    map['tax_paise'] = Variable<int>(taxPaise);
    map['extra_tax_paise'] = Variable<int>(extraTaxPaise);
    return map;
  }

  BillLinesCompanion toCompanion(bool nullToAbsent) {
    return BillLinesCompanion(
      id: Value(id),
      billId: Value(billId),
      articleId: Value(articleId),
      barcodeValue: Value(barcodeValue),
      productName: Value(productName),
      size: Value(size),
      color: Value(color),
      mrpPaise: Value(mrpPaise),
      markdownPaise: Value(markdownPaise),
      discountPaise: Value(discountPaise),
      finalPaise: Value(finalPaise),
      gstBp: Value(gstBp),
      taxablePaise: Value(taxablePaise),
      taxPaise: Value(taxPaise),
      extraTaxPaise: Value(extraTaxPaise),
    );
  }

  factory BillLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillLineRow(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String>(json['billId']),
      articleId: serializer.fromJson<String>(json['articleId']),
      barcodeValue: serializer.fromJson<String>(json['barcodeValue']),
      productName: serializer.fromJson<String>(json['productName']),
      size: serializer.fromJson<String>(json['size']),
      color: serializer.fromJson<String>(json['color']),
      mrpPaise: serializer.fromJson<int>(json['mrpPaise']),
      markdownPaise: serializer.fromJson<int>(json['markdownPaise']),
      discountPaise: serializer.fromJson<int>(json['discountPaise']),
      finalPaise: serializer.fromJson<int>(json['finalPaise']),
      gstBp: serializer.fromJson<int>(json['gstBp']),
      taxablePaise: serializer.fromJson<int>(json['taxablePaise']),
      taxPaise: serializer.fromJson<int>(json['taxPaise']),
      extraTaxPaise: serializer.fromJson<int>(json['extraTaxPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String>(billId),
      'articleId': serializer.toJson<String>(articleId),
      'barcodeValue': serializer.toJson<String>(barcodeValue),
      'productName': serializer.toJson<String>(productName),
      'size': serializer.toJson<String>(size),
      'color': serializer.toJson<String>(color),
      'mrpPaise': serializer.toJson<int>(mrpPaise),
      'markdownPaise': serializer.toJson<int>(markdownPaise),
      'discountPaise': serializer.toJson<int>(discountPaise),
      'finalPaise': serializer.toJson<int>(finalPaise),
      'gstBp': serializer.toJson<int>(gstBp),
      'taxablePaise': serializer.toJson<int>(taxablePaise),
      'taxPaise': serializer.toJson<int>(taxPaise),
      'extraTaxPaise': serializer.toJson<int>(extraTaxPaise),
    };
  }

  BillLineRow copyWith({
    String? id,
    String? billId,
    String? articleId,
    String? barcodeValue,
    String? productName,
    String? size,
    String? color,
    int? mrpPaise,
    int? markdownPaise,
    int? discountPaise,
    int? finalPaise,
    int? gstBp,
    int? taxablePaise,
    int? taxPaise,
    int? extraTaxPaise,
  }) => BillLineRow(
    id: id ?? this.id,
    billId: billId ?? this.billId,
    articleId: articleId ?? this.articleId,
    barcodeValue: barcodeValue ?? this.barcodeValue,
    productName: productName ?? this.productName,
    size: size ?? this.size,
    color: color ?? this.color,
    mrpPaise: mrpPaise ?? this.mrpPaise,
    markdownPaise: markdownPaise ?? this.markdownPaise,
    discountPaise: discountPaise ?? this.discountPaise,
    finalPaise: finalPaise ?? this.finalPaise,
    gstBp: gstBp ?? this.gstBp,
    taxablePaise: taxablePaise ?? this.taxablePaise,
    taxPaise: taxPaise ?? this.taxPaise,
    extraTaxPaise: extraTaxPaise ?? this.extraTaxPaise,
  );
  BillLineRow copyWithCompanion(BillLinesCompanion data) {
    return BillLineRow(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      articleId: data.articleId.present ? data.articleId.value : this.articleId,
      barcodeValue: data.barcodeValue.present
          ? data.barcodeValue.value
          : this.barcodeValue,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      size: data.size.present ? data.size.value : this.size,
      color: data.color.present ? data.color.value : this.color,
      mrpPaise: data.mrpPaise.present ? data.mrpPaise.value : this.mrpPaise,
      markdownPaise: data.markdownPaise.present
          ? data.markdownPaise.value
          : this.markdownPaise,
      discountPaise: data.discountPaise.present
          ? data.discountPaise.value
          : this.discountPaise,
      finalPaise: data.finalPaise.present
          ? data.finalPaise.value
          : this.finalPaise,
      gstBp: data.gstBp.present ? data.gstBp.value : this.gstBp,
      taxablePaise: data.taxablePaise.present
          ? data.taxablePaise.value
          : this.taxablePaise,
      taxPaise: data.taxPaise.present ? data.taxPaise.value : this.taxPaise,
      extraTaxPaise: data.extraTaxPaise.present
          ? data.extraTaxPaise.value
          : this.extraTaxPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillLineRow(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('articleId: $articleId, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('productName: $productName, ')
          ..write('size: $size, ')
          ..write('color: $color, ')
          ..write('mrpPaise: $mrpPaise, ')
          ..write('markdownPaise: $markdownPaise, ')
          ..write('discountPaise: $discountPaise, ')
          ..write('finalPaise: $finalPaise, ')
          ..write('gstBp: $gstBp, ')
          ..write('taxablePaise: $taxablePaise, ')
          ..write('taxPaise: $taxPaise, ')
          ..write('extraTaxPaise: $extraTaxPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    billId,
    articleId,
    barcodeValue,
    productName,
    size,
    color,
    mrpPaise,
    markdownPaise,
    discountPaise,
    finalPaise,
    gstBp,
    taxablePaise,
    taxPaise,
    extraTaxPaise,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillLineRow &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.articleId == this.articleId &&
          other.barcodeValue == this.barcodeValue &&
          other.productName == this.productName &&
          other.size == this.size &&
          other.color == this.color &&
          other.mrpPaise == this.mrpPaise &&
          other.markdownPaise == this.markdownPaise &&
          other.discountPaise == this.discountPaise &&
          other.finalPaise == this.finalPaise &&
          other.gstBp == this.gstBp &&
          other.taxablePaise == this.taxablePaise &&
          other.taxPaise == this.taxPaise &&
          other.extraTaxPaise == this.extraTaxPaise);
}

class BillLinesCompanion extends UpdateCompanion<BillLineRow> {
  final Value<String> id;
  final Value<String> billId;
  final Value<String> articleId;
  final Value<String> barcodeValue;
  final Value<String> productName;
  final Value<String> size;
  final Value<String> color;
  final Value<int> mrpPaise;
  final Value<int> markdownPaise;
  final Value<int> discountPaise;
  final Value<int> finalPaise;
  final Value<int> gstBp;
  final Value<int> taxablePaise;
  final Value<int> taxPaise;
  final Value<int> extraTaxPaise;
  final Value<int> rowid;
  const BillLinesCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.articleId = const Value.absent(),
    this.barcodeValue = const Value.absent(),
    this.productName = const Value.absent(),
    this.size = const Value.absent(),
    this.color = const Value.absent(),
    this.mrpPaise = const Value.absent(),
    this.markdownPaise = const Value.absent(),
    this.discountPaise = const Value.absent(),
    this.finalPaise = const Value.absent(),
    this.gstBp = const Value.absent(),
    this.taxablePaise = const Value.absent(),
    this.taxPaise = const Value.absent(),
    this.extraTaxPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillLinesCompanion.insert({
    required String id,
    required String billId,
    required String articleId,
    required String barcodeValue,
    required String productName,
    required String size,
    required String color,
    required int mrpPaise,
    required int markdownPaise,
    required int discountPaise,
    required int finalPaise,
    this.gstBp = const Value.absent(),
    this.taxablePaise = const Value.absent(),
    this.taxPaise = const Value.absent(),
    this.extraTaxPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       billId = Value(billId),
       articleId = Value(articleId),
       barcodeValue = Value(barcodeValue),
       productName = Value(productName),
       size = Value(size),
       color = Value(color),
       mrpPaise = Value(mrpPaise),
       markdownPaise = Value(markdownPaise),
       discountPaise = Value(discountPaise),
       finalPaise = Value(finalPaise);
  static Insertable<BillLineRow> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<String>? articleId,
    Expression<String>? barcodeValue,
    Expression<String>? productName,
    Expression<String>? size,
    Expression<String>? color,
    Expression<int>? mrpPaise,
    Expression<int>? markdownPaise,
    Expression<int>? discountPaise,
    Expression<int>? finalPaise,
    Expression<int>? gstBp,
    Expression<int>? taxablePaise,
    Expression<int>? taxPaise,
    Expression<int>? extraTaxPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (articleId != null) 'article_id': articleId,
      if (barcodeValue != null) 'barcode_value': barcodeValue,
      if (productName != null) 'product_name': productName,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (mrpPaise != null) 'mrp_paise': mrpPaise,
      if (markdownPaise != null) 'markdown_paise': markdownPaise,
      if (discountPaise != null) 'discount_paise': discountPaise,
      if (finalPaise != null) 'final_paise': finalPaise,
      if (gstBp != null) 'gst_bp': gstBp,
      if (taxablePaise != null) 'taxable_paise': taxablePaise,
      if (taxPaise != null) 'tax_paise': taxPaise,
      if (extraTaxPaise != null) 'extra_tax_paise': extraTaxPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? billId,
    Value<String>? articleId,
    Value<String>? barcodeValue,
    Value<String>? productName,
    Value<String>? size,
    Value<String>? color,
    Value<int>? mrpPaise,
    Value<int>? markdownPaise,
    Value<int>? discountPaise,
    Value<int>? finalPaise,
    Value<int>? gstBp,
    Value<int>? taxablePaise,
    Value<int>? taxPaise,
    Value<int>? extraTaxPaise,
    Value<int>? rowid,
  }) {
    return BillLinesCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      articleId: articleId ?? this.articleId,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      productName: productName ?? this.productName,
      size: size ?? this.size,
      color: color ?? this.color,
      mrpPaise: mrpPaise ?? this.mrpPaise,
      markdownPaise: markdownPaise ?? this.markdownPaise,
      discountPaise: discountPaise ?? this.discountPaise,
      finalPaise: finalPaise ?? this.finalPaise,
      gstBp: gstBp ?? this.gstBp,
      taxablePaise: taxablePaise ?? this.taxablePaise,
      taxPaise: taxPaise ?? this.taxPaise,
      extraTaxPaise: extraTaxPaise ?? this.extraTaxPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (articleId.present) {
      map['article_id'] = Variable<String>(articleId.value);
    }
    if (barcodeValue.present) {
      map['barcode_value'] = Variable<String>(barcodeValue.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (size.present) {
      map['size'] = Variable<String>(size.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (mrpPaise.present) {
      map['mrp_paise'] = Variable<int>(mrpPaise.value);
    }
    if (markdownPaise.present) {
      map['markdown_paise'] = Variable<int>(markdownPaise.value);
    }
    if (discountPaise.present) {
      map['discount_paise'] = Variable<int>(discountPaise.value);
    }
    if (finalPaise.present) {
      map['final_paise'] = Variable<int>(finalPaise.value);
    }
    if (gstBp.present) {
      map['gst_bp'] = Variable<int>(gstBp.value);
    }
    if (taxablePaise.present) {
      map['taxable_paise'] = Variable<int>(taxablePaise.value);
    }
    if (taxPaise.present) {
      map['tax_paise'] = Variable<int>(taxPaise.value);
    }
    if (extraTaxPaise.present) {
      map['extra_tax_paise'] = Variable<int>(extraTaxPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillLinesCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('articleId: $articleId, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('productName: $productName, ')
          ..write('size: $size, ')
          ..write('color: $color, ')
          ..write('mrpPaise: $mrpPaise, ')
          ..write('markdownPaise: $markdownPaise, ')
          ..write('discountPaise: $discountPaise, ')
          ..write('finalPaise: $finalPaise, ')
          ..write('gstBp: $gstBp, ')
          ..write('taxablePaise: $taxablePaise, ')
          ..write('taxPaise: $taxPaise, ')
          ..write('extraTaxPaise: $extraTaxPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillPaymentsTable extends BillPayments
    with TableInfo<$BillPaymentsTable, BillPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bills (id)',
    ),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (mode IN (\'cash\', \'upi\', \'card\', \'credit_note\'))',
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(amountPaise).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, billId, mode, amountPaise];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillPaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
    );
  }

  @override
  $BillPaymentsTable createAlias(String alias) {
    return $BillPaymentsTable(attachedDatabase, alias);
  }
}

class BillPaymentRow extends DataClass implements Insertable<BillPaymentRow> {
  final String id;
  final String billId;
  final String mode;
  final int amountPaise;
  const BillPaymentRow({
    required this.id,
    required this.billId,
    required this.mode,
    required this.amountPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_id'] = Variable<String>(billId);
    map['mode'] = Variable<String>(mode);
    map['amount_paise'] = Variable<int>(amountPaise);
    return map;
  }

  BillPaymentsCompanion toCompanion(bool nullToAbsent) {
    return BillPaymentsCompanion(
      id: Value(id),
      billId: Value(billId),
      mode: Value(mode),
      amountPaise: Value(amountPaise),
    );
  }

  factory BillPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String>(json['billId']),
      mode: serializer.fromJson<String>(json['mode']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String>(billId),
      'mode': serializer.toJson<String>(mode),
      'amountPaise': serializer.toJson<int>(amountPaise),
    };
  }

  BillPaymentRow copyWith({
    String? id,
    String? billId,
    String? mode,
    int? amountPaise,
  }) => BillPaymentRow(
    id: id ?? this.id,
    billId: billId ?? this.billId,
    mode: mode ?? this.mode,
    amountPaise: amountPaise ?? this.amountPaise,
  );
  BillPaymentRow copyWithCompanion(BillPaymentsCompanion data) {
    return BillPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      mode: data.mode.present ? data.mode.value : this.mode,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillPaymentRow(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('mode: $mode, ')
          ..write('amountPaise: $amountPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, billId, mode, amountPaise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillPaymentRow &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.mode == this.mode &&
          other.amountPaise == this.amountPaise);
}

class BillPaymentsCompanion extends UpdateCompanion<BillPaymentRow> {
  final Value<String> id;
  final Value<String> billId;
  final Value<String> mode;
  final Value<int> amountPaise;
  final Value<int> rowid;
  const BillPaymentsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.mode = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillPaymentsCompanion.insert({
    required String id,
    required String billId,
    required String mode,
    required int amountPaise,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       billId = Value(billId),
       mode = Value(mode),
       amountPaise = Value(amountPaise);
  static Insertable<BillPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<String>? mode,
    Expression<int>? amountPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (mode != null) 'mode': mode,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? billId,
    Value<String>? mode,
    Value<int>? amountPaise,
    Value<int>? rowid,
  }) {
    return BillPaymentsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      mode: mode ?? this.mode,
      amountPaise: amountPaise ?? this.amountPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('mode: $mode, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillSequencesTable extends BillSequences
    with TableInfo<$BillSequencesTable, BillSequenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillSequencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _counterIdMeta = const VerificationMeta(
    'counterId',
  );
  @override
  late final GeneratedColumn<String> counterId = GeneratedColumn<String>(
    'counter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counters (id)',
    ),
  );
  static const VerificationMeta _yearLabelMeta = const VerificationMeta(
    'yearLabel',
  );
  @override
  late final GeneratedColumn<String> yearLabel = GeneratedColumn<String>(
    'year_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSerialMeta = const VerificationMeta(
    'lastSerial',
  );
  @override
  late final GeneratedColumn<int> lastSerial = GeneratedColumn<int>(
    'last_serial',
    aliasedName,
    false,
    check: () => ComparableExpr(lastSerial).isBetweenValues(0, 999999),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [counterId, yearLabel, lastSerial];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_sequences';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillSequenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('counter_id')) {
      context.handle(
        _counterIdMeta,
        counterId.isAcceptableOrUnknown(data['counter_id']!, _counterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_counterIdMeta);
    }
    if (data.containsKey('year_label')) {
      context.handle(
        _yearLabelMeta,
        yearLabel.isAcceptableOrUnknown(data['year_label']!, _yearLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_yearLabelMeta);
    }
    if (data.containsKey('last_serial')) {
      context.handle(
        _lastSerialMeta,
        lastSerial.isAcceptableOrUnknown(data['last_serial']!, _lastSerialMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSerialMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {counterId, yearLabel};
  @override
  BillSequenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillSequenceRow(
      counterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_id'],
      )!,
      yearLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_label'],
      )!,
      lastSerial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_serial'],
      )!,
    );
  }

  @override
  $BillSequencesTable createAlias(String alias) {
    return $BillSequencesTable(attachedDatabase, alias);
  }
}

class BillSequenceRow extends DataClass implements Insertable<BillSequenceRow> {
  final String counterId;
  final String yearLabel;
  final int lastSerial;
  const BillSequenceRow({
    required this.counterId,
    required this.yearLabel,
    required this.lastSerial,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['counter_id'] = Variable<String>(counterId);
    map['year_label'] = Variable<String>(yearLabel);
    map['last_serial'] = Variable<int>(lastSerial);
    return map;
  }

  BillSequencesCompanion toCompanion(bool nullToAbsent) {
    return BillSequencesCompanion(
      counterId: Value(counterId),
      yearLabel: Value(yearLabel),
      lastSerial: Value(lastSerial),
    );
  }

  factory BillSequenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillSequenceRow(
      counterId: serializer.fromJson<String>(json['counterId']),
      yearLabel: serializer.fromJson<String>(json['yearLabel']),
      lastSerial: serializer.fromJson<int>(json['lastSerial']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'counterId': serializer.toJson<String>(counterId),
      'yearLabel': serializer.toJson<String>(yearLabel),
      'lastSerial': serializer.toJson<int>(lastSerial),
    };
  }

  BillSequenceRow copyWith({
    String? counterId,
    String? yearLabel,
    int? lastSerial,
  }) => BillSequenceRow(
    counterId: counterId ?? this.counterId,
    yearLabel: yearLabel ?? this.yearLabel,
    lastSerial: lastSerial ?? this.lastSerial,
  );
  BillSequenceRow copyWithCompanion(BillSequencesCompanion data) {
    return BillSequenceRow(
      counterId: data.counterId.present ? data.counterId.value : this.counterId,
      yearLabel: data.yearLabel.present ? data.yearLabel.value : this.yearLabel,
      lastSerial: data.lastSerial.present
          ? data.lastSerial.value
          : this.lastSerial,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillSequenceRow(')
          ..write('counterId: $counterId, ')
          ..write('yearLabel: $yearLabel, ')
          ..write('lastSerial: $lastSerial')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(counterId, yearLabel, lastSerial);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillSequenceRow &&
          other.counterId == this.counterId &&
          other.yearLabel == this.yearLabel &&
          other.lastSerial == this.lastSerial);
}

class BillSequencesCompanion extends UpdateCompanion<BillSequenceRow> {
  final Value<String> counterId;
  final Value<String> yearLabel;
  final Value<int> lastSerial;
  final Value<int> rowid;
  const BillSequencesCompanion({
    this.counterId = const Value.absent(),
    this.yearLabel = const Value.absent(),
    this.lastSerial = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillSequencesCompanion.insert({
    required String counterId,
    required String yearLabel,
    required int lastSerial,
    this.rowid = const Value.absent(),
  }) : counterId = Value(counterId),
       yearLabel = Value(yearLabel),
       lastSerial = Value(lastSerial);
  static Insertable<BillSequenceRow> custom({
    Expression<String>? counterId,
    Expression<String>? yearLabel,
    Expression<int>? lastSerial,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (counterId != null) 'counter_id': counterId,
      if (yearLabel != null) 'year_label': yearLabel,
      if (lastSerial != null) 'last_serial': lastSerial,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillSequencesCompanion copyWith({
    Value<String>? counterId,
    Value<String>? yearLabel,
    Value<int>? lastSerial,
    Value<int>? rowid,
  }) {
    return BillSequencesCompanion(
      counterId: counterId ?? this.counterId,
      yearLabel: yearLabel ?? this.yearLabel,
      lastSerial: lastSerial ?? this.lastSerial,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (counterId.present) {
      map['counter_id'] = Variable<String>(counterId.value);
    }
    if (yearLabel.present) {
      map['year_label'] = Variable<String>(yearLabel.value);
    }
    if (lastSerial.present) {
      map['last_serial'] = Variable<int>(lastSerial.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillSequencesCompanion(')
          ..write('counterId: $counterId, ')
          ..write('yearLabel: $yearLabel, ')
          ..write('lastSerial: $lastSerial, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditNoteUsesTable extends CreditNoteUses
    with TableInfo<$CreditNoteUsesTable, CreditNoteUseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditNoteUsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creditNoteIdMeta = const VerificationMeta(
    'creditNoteId',
  );
  @override
  late final GeneratedColumn<String> creditNoteId = GeneratedColumn<String>(
    'credit_note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES credit_notes (id)',
    ),
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bills (id)',
    ),
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(amountPaise).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, creditNoteId, billId, amountPaise];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_note_uses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditNoteUseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('credit_note_id')) {
      context.handle(
        _creditNoteIdMeta,
        creditNoteId.isAcceptableOrUnknown(
          data['credit_note_id']!,
          _creditNoteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creditNoteIdMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditNoteUseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditNoteUseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      creditNoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_note_id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
    );
  }

  @override
  $CreditNoteUsesTable createAlias(String alias) {
    return $CreditNoteUsesTable(attachedDatabase, alias);
  }
}

class CreditNoteUseRow extends DataClass
    implements Insertable<CreditNoteUseRow> {
  final String id;
  final String creditNoteId;
  final String billId;
  final int amountPaise;
  const CreditNoteUseRow({
    required this.id,
    required this.creditNoteId,
    required this.billId,
    required this.amountPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['credit_note_id'] = Variable<String>(creditNoteId);
    map['bill_id'] = Variable<String>(billId);
    map['amount_paise'] = Variable<int>(amountPaise);
    return map;
  }

  CreditNoteUsesCompanion toCompanion(bool nullToAbsent) {
    return CreditNoteUsesCompanion(
      id: Value(id),
      creditNoteId: Value(creditNoteId),
      billId: Value(billId),
      amountPaise: Value(amountPaise),
    );
  }

  factory CreditNoteUseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditNoteUseRow(
      id: serializer.fromJson<String>(json['id']),
      creditNoteId: serializer.fromJson<String>(json['creditNoteId']),
      billId: serializer.fromJson<String>(json['billId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'creditNoteId': serializer.toJson<String>(creditNoteId),
      'billId': serializer.toJson<String>(billId),
      'amountPaise': serializer.toJson<int>(amountPaise),
    };
  }

  CreditNoteUseRow copyWith({
    String? id,
    String? creditNoteId,
    String? billId,
    int? amountPaise,
  }) => CreditNoteUseRow(
    id: id ?? this.id,
    creditNoteId: creditNoteId ?? this.creditNoteId,
    billId: billId ?? this.billId,
    amountPaise: amountPaise ?? this.amountPaise,
  );
  CreditNoteUseRow copyWithCompanion(CreditNoteUsesCompanion data) {
    return CreditNoteUseRow(
      id: data.id.present ? data.id.value : this.id,
      creditNoteId: data.creditNoteId.present
          ? data.creditNoteId.value
          : this.creditNoteId,
      billId: data.billId.present ? data.billId.value : this.billId,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditNoteUseRow(')
          ..write('id: $id, ')
          ..write('creditNoteId: $creditNoteId, ')
          ..write('billId: $billId, ')
          ..write('amountPaise: $amountPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, creditNoteId, billId, amountPaise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditNoteUseRow &&
          other.id == this.id &&
          other.creditNoteId == this.creditNoteId &&
          other.billId == this.billId &&
          other.amountPaise == this.amountPaise);
}

class CreditNoteUsesCompanion extends UpdateCompanion<CreditNoteUseRow> {
  final Value<String> id;
  final Value<String> creditNoteId;
  final Value<String> billId;
  final Value<int> amountPaise;
  final Value<int> rowid;
  const CreditNoteUsesCompanion({
    this.id = const Value.absent(),
    this.creditNoteId = const Value.absent(),
    this.billId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditNoteUsesCompanion.insert({
    required String id,
    required String creditNoteId,
    required String billId,
    required int amountPaise,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       creditNoteId = Value(creditNoteId),
       billId = Value(billId),
       amountPaise = Value(amountPaise);
  static Insertable<CreditNoteUseRow> custom({
    Expression<String>? id,
    Expression<String>? creditNoteId,
    Expression<String>? billId,
    Expression<int>? amountPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (creditNoteId != null) 'credit_note_id': creditNoteId,
      if (billId != null) 'bill_id': billId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditNoteUsesCompanion copyWith({
    Value<String>? id,
    Value<String>? creditNoteId,
    Value<String>? billId,
    Value<int>? amountPaise,
    Value<int>? rowid,
  }) {
    return CreditNoteUsesCompanion(
      id: id ?? this.id,
      creditNoteId: creditNoteId ?? this.creditNoteId,
      billId: billId ?? this.billId,
      amountPaise: amountPaise ?? this.amountPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (creditNoteId.present) {
      map['credit_note_id'] = Variable<String>(creditNoteId.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditNoteUsesCompanion(')
          ..write('id: $id, ')
          ..write('creditNoteId: $creditNoteId, ')
          ..write('billId: $billId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReturnLinesTable extends ReturnLines
    with TableInfo<$ReturnLinesTable, ReturnLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReturnLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _returnIdMeta = const VerificationMeta(
    'returnId',
  );
  @override
  late final GeneratedColumn<String> returnId = GeneratedColumn<String>(
    'return_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES returns (id)',
    ),
  );
  static const VerificationMeta _billLineIdMeta = const VerificationMeta(
    'billLineId',
  );
  @override
  late final GeneratedColumn<String> billLineId = GeneratedColumn<String>(
    'bill_line_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE REFERENCES bill_lines (id)',
  );
  static const VerificationMeta _articleIdMeta = const VerificationMeta(
    'articleId',
  );
  @override
  late final GeneratedColumn<String> articleId = GeneratedColumn<String>(
    'article_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES articles (id)',
    ),
  );
  static const VerificationMeta _refundPaiseMeta = const VerificationMeta(
    'refundPaise',
  );
  @override
  late final GeneratedColumn<int> refundPaise = GeneratedColumn<int>(
    'refund_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(refundPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (outcome IN (\'RESTOCK\', \'DAMAGED\'))',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    returnId,
    billLineId,
    articleId,
    refundPaise,
    outcome,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'return_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReturnLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('return_id')) {
      context.handle(
        _returnIdMeta,
        returnId.isAcceptableOrUnknown(data['return_id']!, _returnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_returnIdMeta);
    }
    if (data.containsKey('bill_line_id')) {
      context.handle(
        _billLineIdMeta,
        billLineId.isAcceptableOrUnknown(
          data['bill_line_id']!,
          _billLineIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billLineIdMeta);
    }
    if (data.containsKey('article_id')) {
      context.handle(
        _articleIdMeta,
        articleId.isAcceptableOrUnknown(data['article_id']!, _articleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_articleIdMeta);
    }
    if (data.containsKey('refund_paise')) {
      context.handle(
        _refundPaiseMeta,
        refundPaise.isAcceptableOrUnknown(
          data['refund_paise']!,
          _refundPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refundPaiseMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReturnLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReturnLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      returnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}return_id'],
      )!,
      billLineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_line_id'],
      )!,
      articleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article_id'],
      )!,
      refundPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}refund_paise'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $ReturnLinesTable createAlias(String alias) {
    return $ReturnLinesTable(attachedDatabase, alias);
  }
}

class ReturnLineRow extends DataClass implements Insertable<ReturnLineRow> {
  final String id;
  final String returnId;
  final String billLineId;
  final String articleId;
  final int refundPaise;
  final String outcome;
  final String? note;
  const ReturnLineRow({
    required this.id,
    required this.returnId,
    required this.billLineId,
    required this.articleId,
    required this.refundPaise,
    required this.outcome,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['return_id'] = Variable<String>(returnId);
    map['bill_line_id'] = Variable<String>(billLineId);
    map['article_id'] = Variable<String>(articleId);
    map['refund_paise'] = Variable<int>(refundPaise);
    map['outcome'] = Variable<String>(outcome);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  ReturnLinesCompanion toCompanion(bool nullToAbsent) {
    return ReturnLinesCompanion(
      id: Value(id),
      returnId: Value(returnId),
      billLineId: Value(billLineId),
      articleId: Value(articleId),
      refundPaise: Value(refundPaise),
      outcome: Value(outcome),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory ReturnLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReturnLineRow(
      id: serializer.fromJson<String>(json['id']),
      returnId: serializer.fromJson<String>(json['returnId']),
      billLineId: serializer.fromJson<String>(json['billLineId']),
      articleId: serializer.fromJson<String>(json['articleId']),
      refundPaise: serializer.fromJson<int>(json['refundPaise']),
      outcome: serializer.fromJson<String>(json['outcome']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'returnId': serializer.toJson<String>(returnId),
      'billLineId': serializer.toJson<String>(billLineId),
      'articleId': serializer.toJson<String>(articleId),
      'refundPaise': serializer.toJson<int>(refundPaise),
      'outcome': serializer.toJson<String>(outcome),
      'note': serializer.toJson<String?>(note),
    };
  }

  ReturnLineRow copyWith({
    String? id,
    String? returnId,
    String? billLineId,
    String? articleId,
    int? refundPaise,
    String? outcome,
    Value<String?> note = const Value.absent(),
  }) => ReturnLineRow(
    id: id ?? this.id,
    returnId: returnId ?? this.returnId,
    billLineId: billLineId ?? this.billLineId,
    articleId: articleId ?? this.articleId,
    refundPaise: refundPaise ?? this.refundPaise,
    outcome: outcome ?? this.outcome,
    note: note.present ? note.value : this.note,
  );
  ReturnLineRow copyWithCompanion(ReturnLinesCompanion data) {
    return ReturnLineRow(
      id: data.id.present ? data.id.value : this.id,
      returnId: data.returnId.present ? data.returnId.value : this.returnId,
      billLineId: data.billLineId.present
          ? data.billLineId.value
          : this.billLineId,
      articleId: data.articleId.present ? data.articleId.value : this.articleId,
      refundPaise: data.refundPaise.present
          ? data.refundPaise.value
          : this.refundPaise,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReturnLineRow(')
          ..write('id: $id, ')
          ..write('returnId: $returnId, ')
          ..write('billLineId: $billLineId, ')
          ..write('articleId: $articleId, ')
          ..write('refundPaise: $refundPaise, ')
          ..write('outcome: $outcome, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    returnId,
    billLineId,
    articleId,
    refundPaise,
    outcome,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReturnLineRow &&
          other.id == this.id &&
          other.returnId == this.returnId &&
          other.billLineId == this.billLineId &&
          other.articleId == this.articleId &&
          other.refundPaise == this.refundPaise &&
          other.outcome == this.outcome &&
          other.note == this.note);
}

class ReturnLinesCompanion extends UpdateCompanion<ReturnLineRow> {
  final Value<String> id;
  final Value<String> returnId;
  final Value<String> billLineId;
  final Value<String> articleId;
  final Value<int> refundPaise;
  final Value<String> outcome;
  final Value<String?> note;
  final Value<int> rowid;
  const ReturnLinesCompanion({
    this.id = const Value.absent(),
    this.returnId = const Value.absent(),
    this.billLineId = const Value.absent(),
    this.articleId = const Value.absent(),
    this.refundPaise = const Value.absent(),
    this.outcome = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReturnLinesCompanion.insert({
    required String id,
    required String returnId,
    required String billLineId,
    required String articleId,
    required int refundPaise,
    required String outcome,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       returnId = Value(returnId),
       billLineId = Value(billLineId),
       articleId = Value(articleId),
       refundPaise = Value(refundPaise),
       outcome = Value(outcome);
  static Insertable<ReturnLineRow> custom({
    Expression<String>? id,
    Expression<String>? returnId,
    Expression<String>? billLineId,
    Expression<String>? articleId,
    Expression<int>? refundPaise,
    Expression<String>? outcome,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (returnId != null) 'return_id': returnId,
      if (billLineId != null) 'bill_line_id': billLineId,
      if (articleId != null) 'article_id': articleId,
      if (refundPaise != null) 'refund_paise': refundPaise,
      if (outcome != null) 'outcome': outcome,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReturnLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? returnId,
    Value<String>? billLineId,
    Value<String>? articleId,
    Value<int>? refundPaise,
    Value<String>? outcome,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return ReturnLinesCompanion(
      id: id ?? this.id,
      returnId: returnId ?? this.returnId,
      billLineId: billLineId ?? this.billLineId,
      articleId: articleId ?? this.articleId,
      refundPaise: refundPaise ?? this.refundPaise,
      outcome: outcome ?? this.outcome,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (returnId.present) {
      map['return_id'] = Variable<String>(returnId.value);
    }
    if (billLineId.present) {
      map['bill_line_id'] = Variable<String>(billLineId.value);
    }
    if (articleId.present) {
      map['article_id'] = Variable<String>(articleId.value);
    }
    if (refundPaise.present) {
      map['refund_paise'] = Variable<int>(refundPaise.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReturnLinesCompanion(')
          ..write('id: $id, ')
          ..write('returnId: $returnId, ')
          ..write('billLineId: $billLineId, ')
          ..write('articleId: $articleId, ')
          ..write('refundPaise: $refundPaise, ')
          ..write('outcome: $outcome, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftClosesTable extends ShiftCloses
    with TableInfo<$ShiftClosesTable, ShiftCloseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftClosesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE REFERENCES shifts (id)',
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countedPaiseMeta = const VerificationMeta(
    'countedPaise',
  );
  @override
  late final GeneratedColumn<int> countedPaise = GeneratedColumn<int>(
    'counted_paise',
    aliasedName,
    false,
    check: () => ComparableExpr(countedPaise).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedPaiseMeta = const VerificationMeta(
    'expectedPaise',
  );
  @override
  late final GeneratedColumn<int> expectedPaise = GeneratedColumn<int>(
    'expected_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variancePaiseMeta = const VerificationMeta(
    'variancePaise',
  );
  @override
  late final GeneratedColumn<int> variancePaise = GeneratedColumn<int>(
    'variance_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countDetailMeta = const VerificationMeta(
    'countDetail',
  );
  @override
  late final GeneratedColumn<String> countDetail = GeneratedColumn<String>(
    'count_detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shiftId,
    closedAt,
    countedPaise,
    expectedPaise,
    variancePaise,
    countDetail,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_closes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftCloseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_closedAtMeta);
    }
    if (data.containsKey('counted_paise')) {
      context.handle(
        _countedPaiseMeta,
        countedPaise.isAcceptableOrUnknown(
          data['counted_paise']!,
          _countedPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countedPaiseMeta);
    }
    if (data.containsKey('expected_paise')) {
      context.handle(
        _expectedPaiseMeta,
        expectedPaise.isAcceptableOrUnknown(
          data['expected_paise']!,
          _expectedPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedPaiseMeta);
    }
    if (data.containsKey('variance_paise')) {
      context.handle(
        _variancePaiseMeta,
        variancePaise.isAcceptableOrUnknown(
          data['variance_paise']!,
          _variancePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_variancePaiseMeta);
    }
    if (data.containsKey('count_detail')) {
      context.handle(
        _countDetailMeta,
        countDetail.isAcceptableOrUnknown(
          data['count_detail']!,
          _countDetailMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countDetailMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftCloseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftCloseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      )!,
      countedPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counted_paise'],
      )!,
      expectedPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_paise'],
      )!,
      variancePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}variance_paise'],
      )!,
      countDetail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}count_detail'],
      )!,
    );
  }

  @override
  $ShiftClosesTable createAlias(String alias) {
    return $ShiftClosesTable(attachedDatabase, alias);
  }
}

class ShiftCloseRow extends DataClass implements Insertable<ShiftCloseRow> {
  final String id;
  final String shiftId;
  final DateTime closedAt;
  final int countedPaise;
  final int expectedPaise;
  final int variancePaise;

  /// The closing count as JSON: denomination name to how many.
  final String countDetail;
  const ShiftCloseRow({
    required this.id,
    required this.shiftId,
    required this.closedAt,
    required this.countedPaise,
    required this.expectedPaise,
    required this.variancePaise,
    required this.countDetail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shift_id'] = Variable<String>(shiftId);
    map['closed_at'] = Variable<DateTime>(closedAt);
    map['counted_paise'] = Variable<int>(countedPaise);
    map['expected_paise'] = Variable<int>(expectedPaise);
    map['variance_paise'] = Variable<int>(variancePaise);
    map['count_detail'] = Variable<String>(countDetail);
    return map;
  }

  ShiftClosesCompanion toCompanion(bool nullToAbsent) {
    return ShiftClosesCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      closedAt: Value(closedAt),
      countedPaise: Value(countedPaise),
      expectedPaise: Value(expectedPaise),
      variancePaise: Value(variancePaise),
      countDetail: Value(countDetail),
    );
  }

  factory ShiftCloseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftCloseRow(
      id: serializer.fromJson<String>(json['id']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      closedAt: serializer.fromJson<DateTime>(json['closedAt']),
      countedPaise: serializer.fromJson<int>(json['countedPaise']),
      expectedPaise: serializer.fromJson<int>(json['expectedPaise']),
      variancePaise: serializer.fromJson<int>(json['variancePaise']),
      countDetail: serializer.fromJson<String>(json['countDetail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shiftId': serializer.toJson<String>(shiftId),
      'closedAt': serializer.toJson<DateTime>(closedAt),
      'countedPaise': serializer.toJson<int>(countedPaise),
      'expectedPaise': serializer.toJson<int>(expectedPaise),
      'variancePaise': serializer.toJson<int>(variancePaise),
      'countDetail': serializer.toJson<String>(countDetail),
    };
  }

  ShiftCloseRow copyWith({
    String? id,
    String? shiftId,
    DateTime? closedAt,
    int? countedPaise,
    int? expectedPaise,
    int? variancePaise,
    String? countDetail,
  }) => ShiftCloseRow(
    id: id ?? this.id,
    shiftId: shiftId ?? this.shiftId,
    closedAt: closedAt ?? this.closedAt,
    countedPaise: countedPaise ?? this.countedPaise,
    expectedPaise: expectedPaise ?? this.expectedPaise,
    variancePaise: variancePaise ?? this.variancePaise,
    countDetail: countDetail ?? this.countDetail,
  );
  ShiftCloseRow copyWithCompanion(ShiftClosesCompanion data) {
    return ShiftCloseRow(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      countedPaise: data.countedPaise.present
          ? data.countedPaise.value
          : this.countedPaise,
      expectedPaise: data.expectedPaise.present
          ? data.expectedPaise.value
          : this.expectedPaise,
      variancePaise: data.variancePaise.present
          ? data.variancePaise.value
          : this.variancePaise,
      countDetail: data.countDetail.present
          ? data.countDetail.value
          : this.countDetail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftCloseRow(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('closedAt: $closedAt, ')
          ..write('countedPaise: $countedPaise, ')
          ..write('expectedPaise: $expectedPaise, ')
          ..write('variancePaise: $variancePaise, ')
          ..write('countDetail: $countDetail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shiftId,
    closedAt,
    countedPaise,
    expectedPaise,
    variancePaise,
    countDetail,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftCloseRow &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.closedAt == this.closedAt &&
          other.countedPaise == this.countedPaise &&
          other.expectedPaise == this.expectedPaise &&
          other.variancePaise == this.variancePaise &&
          other.countDetail == this.countDetail);
}

class ShiftClosesCompanion extends UpdateCompanion<ShiftCloseRow> {
  final Value<String> id;
  final Value<String> shiftId;
  final Value<DateTime> closedAt;
  final Value<int> countedPaise;
  final Value<int> expectedPaise;
  final Value<int> variancePaise;
  final Value<String> countDetail;
  final Value<int> rowid;
  const ShiftClosesCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.countedPaise = const Value.absent(),
    this.expectedPaise = const Value.absent(),
    this.variancePaise = const Value.absent(),
    this.countDetail = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftClosesCompanion.insert({
    required String id,
    required String shiftId,
    required DateTime closedAt,
    required int countedPaise,
    required int expectedPaise,
    required int variancePaise,
    required String countDetail,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shiftId = Value(shiftId),
       closedAt = Value(closedAt),
       countedPaise = Value(countedPaise),
       expectedPaise = Value(expectedPaise),
       variancePaise = Value(variancePaise),
       countDetail = Value(countDetail);
  static Insertable<ShiftCloseRow> custom({
    Expression<String>? id,
    Expression<String>? shiftId,
    Expression<DateTime>? closedAt,
    Expression<int>? countedPaise,
    Expression<int>? expectedPaise,
    Expression<int>? variancePaise,
    Expression<String>? countDetail,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (closedAt != null) 'closed_at': closedAt,
      if (countedPaise != null) 'counted_paise': countedPaise,
      if (expectedPaise != null) 'expected_paise': expectedPaise,
      if (variancePaise != null) 'variance_paise': variancePaise,
      if (countDetail != null) 'count_detail': countDetail,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftClosesCompanion copyWith({
    Value<String>? id,
    Value<String>? shiftId,
    Value<DateTime>? closedAt,
    Value<int>? countedPaise,
    Value<int>? expectedPaise,
    Value<int>? variancePaise,
    Value<String>? countDetail,
    Value<int>? rowid,
  }) {
    return ShiftClosesCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      closedAt: closedAt ?? this.closedAt,
      countedPaise: countedPaise ?? this.countedPaise,
      expectedPaise: expectedPaise ?? this.expectedPaise,
      variancePaise: variancePaise ?? this.variancePaise,
      countDetail: countDetail ?? this.countDetail,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (countedPaise.present) {
      map['counted_paise'] = Variable<int>(countedPaise.value);
    }
    if (expectedPaise.present) {
      map['expected_paise'] = Variable<int>(expectedPaise.value);
    }
    if (variancePaise.present) {
      map['variance_paise'] = Variable<int>(variancePaise.value);
    }
    if (countDetail.present) {
      map['count_detail'] = Variable<String>(countDetail.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftClosesCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('closedAt: $closedAt, ')
          ..write('countedPaise: $countedPaise, ')
          ..write('expectedPaise: $expectedPaise, ')
          ..write('variancePaise: $variancePaise, ')
          ..write('countDetail: $countDetail, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftBreaksTable extends ShiftBreaks
    with TableInfo<$ShiftBreaksTable, ShiftBreakRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftBreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, shiftId, startedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_breaks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftBreakRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftBreakRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftBreakRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
    );
  }

  @override
  $ShiftBreaksTable createAlias(String alias) {
    return $ShiftBreaksTable(attachedDatabase, alias);
  }
}

class ShiftBreakRow extends DataClass implements Insertable<ShiftBreakRow> {
  final String id;
  final String shiftId;
  final DateTime startedAt;
  const ShiftBreakRow({
    required this.id,
    required this.shiftId,
    required this.startedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shift_id'] = Variable<String>(shiftId);
    map['started_at'] = Variable<DateTime>(startedAt);
    return map;
  }

  ShiftBreaksCompanion toCompanion(bool nullToAbsent) {
    return ShiftBreaksCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      startedAt: Value(startedAt),
    );
  }

  factory ShiftBreakRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftBreakRow(
      id: serializer.fromJson<String>(json['id']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shiftId': serializer.toJson<String>(shiftId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
    };
  }

  ShiftBreakRow copyWith({String? id, String? shiftId, DateTime? startedAt}) =>
      ShiftBreakRow(
        id: id ?? this.id,
        shiftId: shiftId ?? this.shiftId,
        startedAt: startedAt ?? this.startedAt,
      );
  ShiftBreakRow copyWithCompanion(ShiftBreaksCompanion data) {
    return ShiftBreakRow(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftBreakRow(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shiftId, startedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftBreakRow &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.startedAt == this.startedAt);
}

class ShiftBreaksCompanion extends UpdateCompanion<ShiftBreakRow> {
  final Value<String> id;
  final Value<String> shiftId;
  final Value<DateTime> startedAt;
  final Value<int> rowid;
  const ShiftBreaksCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftBreaksCompanion.insert({
    required String id,
    required String shiftId,
    required DateTime startedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shiftId = Value(shiftId),
       startedAt = Value(startedAt);
  static Insertable<ShiftBreakRow> custom({
    Expression<String>? id,
    Expression<String>? shiftId,
    Expression<DateTime>? startedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (startedAt != null) 'started_at': startedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftBreaksCompanion copyWith({
    Value<String>? id,
    Value<String>? shiftId,
    Value<DateTime>? startedAt,
    Value<int>? rowid,
  }) {
    return ShiftBreaksCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      startedAt: startedAt ?? this.startedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftBreaksCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('startedAt: $startedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftBreakEndsTable extends ShiftBreakEnds
    with TableInfo<$ShiftBreakEndsTable, ShiftBreakEndRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftBreakEndsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breakIdMeta = const VerificationMeta(
    'breakId',
  );
  @override
  late final GeneratedColumn<String> breakId = GeneratedColumn<String>(
    'break_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE REFERENCES shift_breaks (id)',
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, breakId, endedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shift_break_ends';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftBreakEndRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('break_id')) {
      context.handle(
        _breakIdMeta,
        breakId.isAcceptableOrUnknown(data['break_id']!, _breakIdMeta),
      );
    } else if (isInserting) {
      context.missing(_breakIdMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftBreakEndRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftBreakEndRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      breakId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}break_id'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
    );
  }

  @override
  $ShiftBreakEndsTable createAlias(String alias) {
    return $ShiftBreakEndsTable(attachedDatabase, alias);
  }
}

class ShiftBreakEndRow extends DataClass
    implements Insertable<ShiftBreakEndRow> {
  final String id;
  final String breakId;
  final DateTime endedAt;
  const ShiftBreakEndRow({
    required this.id,
    required this.breakId,
    required this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['break_id'] = Variable<String>(breakId);
    map['ended_at'] = Variable<DateTime>(endedAt);
    return map;
  }

  ShiftBreakEndsCompanion toCompanion(bool nullToAbsent) {
    return ShiftBreakEndsCompanion(
      id: Value(id),
      breakId: Value(breakId),
      endedAt: Value(endedAt),
    );
  }

  factory ShiftBreakEndRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftBreakEndRow(
      id: serializer.fromJson<String>(json['id']),
      breakId: serializer.fromJson<String>(json['breakId']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'breakId': serializer.toJson<String>(breakId),
      'endedAt': serializer.toJson<DateTime>(endedAt),
    };
  }

  ShiftBreakEndRow copyWith({String? id, String? breakId, DateTime? endedAt}) =>
      ShiftBreakEndRow(
        id: id ?? this.id,
        breakId: breakId ?? this.breakId,
        endedAt: endedAt ?? this.endedAt,
      );
  ShiftBreakEndRow copyWithCompanion(ShiftBreakEndsCompanion data) {
    return ShiftBreakEndRow(
      id: data.id.present ? data.id.value : this.id,
      breakId: data.breakId.present ? data.breakId.value : this.breakId,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftBreakEndRow(')
          ..write('id: $id, ')
          ..write('breakId: $breakId, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, breakId, endedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftBreakEndRow &&
          other.id == this.id &&
          other.breakId == this.breakId &&
          other.endedAt == this.endedAt);
}

class ShiftBreakEndsCompanion extends UpdateCompanion<ShiftBreakEndRow> {
  final Value<String> id;
  final Value<String> breakId;
  final Value<DateTime> endedAt;
  final Value<int> rowid;
  const ShiftBreakEndsCompanion({
    this.id = const Value.absent(),
    this.breakId = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftBreakEndsCompanion.insert({
    required String id,
    required String breakId,
    required DateTime endedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       breakId = Value(breakId),
       endedAt = Value(endedAt);
  static Insertable<ShiftBreakEndRow> custom({
    Expression<String>? id,
    Expression<String>? breakId,
    Expression<DateTime>? endedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (breakId != null) 'break_id': breakId,
      if (endedAt != null) 'ended_at': endedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftBreakEndsCompanion copyWith({
    Value<String>? id,
    Value<String>? breakId,
    Value<DateTime>? endedAt,
    Value<int>? rowid,
  }) {
    return ShiftBreakEndsCompanion(
      id: id ?? this.id,
      breakId: breakId ?? this.breakId,
      endedAt: endedAt ?? this.endedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (breakId.present) {
      map['break_id'] = Variable<String>(breakId.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftBreakEndsCompanion(')
          ..write('id: $id, ')
          ..write('breakId: $breakId, ')
          ..write('endedAt: $endedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DaybookTable extends Daybook with TableInfo<$DaybookTable, DaybookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaybookTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'SALE_CASH\', \'SALE_UPI\', \'SALE_CARD\', \'SALE_CREDIT_NOTE\', \'REFUND_CASH\', \'REFUND_UPI\', \'REFUND_CARD\', \'REFUND_CREDIT_NOTE\', \'DUES_CASH\', \'DUES_UPI\', \'DUES_CARD\'))',
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    check: () => BooleanExpressionOperators(amountPaise.equals(0)).not(),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refTypeMeta = const VerificationMeta(
    'refType',
  );
  @override
  late final GeneratedColumn<String> refType = GeneratedColumn<String>(
    'ref_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (ref_type IN (\'bill\', \'return\', \'dues\'))',
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    shiftId,
    kind,
    amountPaise,
    refType,
    refId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daybook';
  @override
  VerificationContext validateIntegrity(
    Insertable<DaybookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('ref_type')) {
      context.handle(
        _refTypeMeta,
        refType.isAcceptableOrUnknown(data['ref_type']!, _refTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_refTypeMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DaybookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DaybookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      refType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_type'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
    );
  }

  @override
  $DaybookTable createAlias(String alias) {
    return $DaybookTable(attachedDatabase, alias);
  }
}

class DaybookRow extends DataClass implements Insertable<DaybookRow> {
  final String id;
  final DateTime at;
  final String shiftId;
  final String kind;
  final int amountPaise;
  final String refType;
  final String refId;
  const DaybookRow({
    required this.id,
    required this.at,
    required this.shiftId,
    required this.kind,
    required this.amountPaise,
    required this.refType,
    required this.refId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['at'] = Variable<DateTime>(at);
    map['shift_id'] = Variable<String>(shiftId);
    map['kind'] = Variable<String>(kind);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['ref_type'] = Variable<String>(refType);
    map['ref_id'] = Variable<String>(refId);
    return map;
  }

  DaybookCompanion toCompanion(bool nullToAbsent) {
    return DaybookCompanion(
      id: Value(id),
      at: Value(at),
      shiftId: Value(shiftId),
      kind: Value(kind),
      amountPaise: Value(amountPaise),
      refType: Value(refType),
      refId: Value(refId),
    );
  }

  factory DaybookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DaybookRow(
      id: serializer.fromJson<String>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      kind: serializer.fromJson<String>(json['kind']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      refType: serializer.fromJson<String>(json['refType']),
      refId: serializer.fromJson<String>(json['refId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'at': serializer.toJson<DateTime>(at),
      'shiftId': serializer.toJson<String>(shiftId),
      'kind': serializer.toJson<String>(kind),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'refType': serializer.toJson<String>(refType),
      'refId': serializer.toJson<String>(refId),
    };
  }

  DaybookRow copyWith({
    String? id,
    DateTime? at,
    String? shiftId,
    String? kind,
    int? amountPaise,
    String? refType,
    String? refId,
  }) => DaybookRow(
    id: id ?? this.id,
    at: at ?? this.at,
    shiftId: shiftId ?? this.shiftId,
    kind: kind ?? this.kind,
    amountPaise: amountPaise ?? this.amountPaise,
    refType: refType ?? this.refType,
    refId: refId ?? this.refId,
  );
  DaybookRow copyWithCompanion(DaybookCompanion data) {
    return DaybookRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      refType: data.refType.present ? data.refType.value : this.refType,
      refId: data.refId.present ? data.refId.value : this.refId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DaybookRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('shiftId: $shiftId, ')
          ..write('kind: $kind, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, at, shiftId, kind, amountPaise, refType, refId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DaybookRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.shiftId == this.shiftId &&
          other.kind == this.kind &&
          other.amountPaise == this.amountPaise &&
          other.refType == this.refType &&
          other.refId == this.refId);
}

class DaybookCompanion extends UpdateCompanion<DaybookRow> {
  final Value<String> id;
  final Value<DateTime> at;
  final Value<String> shiftId;
  final Value<String> kind;
  final Value<int> amountPaise;
  final Value<String> refType;
  final Value<String> refId;
  final Value<int> rowid;
  const DaybookCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.refType = const Value.absent(),
    this.refId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DaybookCompanion.insert({
    required String id,
    required DateTime at,
    required String shiftId,
    required String kind,
    required int amountPaise,
    required String refType,
    required String refId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       at = Value(at),
       shiftId = Value(shiftId),
       kind = Value(kind),
       amountPaise = Value(amountPaise),
       refType = Value(refType),
       refId = Value(refId);
  static Insertable<DaybookRow> custom({
    Expression<String>? id,
    Expression<DateTime>? at,
    Expression<String>? shiftId,
    Expression<String>? kind,
    Expression<int>? amountPaise,
    Expression<String>? refType,
    Expression<String>? refId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (shiftId != null) 'shift_id': shiftId,
      if (kind != null) 'kind': kind,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (refType != null) 'ref_type': refType,
      if (refId != null) 'ref_id': refId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DaybookCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? at,
    Value<String>? shiftId,
    Value<String>? kind,
    Value<int>? amountPaise,
    Value<String>? refType,
    Value<String>? refId,
    Value<int>? rowid,
  }) {
    return DaybookCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      shiftId: shiftId ?? this.shiftId,
      kind: kind ?? this.kind,
      amountPaise: amountPaise ?? this.amountPaise,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (refType.present) {
      map['ref_type'] = Variable<String>(refType.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaybookCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('shiftId: $shiftId, ')
          ..write('kind: $kind, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SizeOptionsTable sizeOptions = $SizeOptionsTable(this);
  late final $ColorOptionsTable colorOptions = $ColorOptionsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $CountersTable counters = $CountersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $StyleMarkdownsTable styleMarkdowns = $StyleMarkdownsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  late final $DuesReceiptsTable duesReceipts = $DuesReceiptsTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $CreditNotesTable creditNotes = $CreditNotesTable(this);
  late final $ReturnsTable returns = $ReturnsTable(this);
  late final $DuesLedgerTable duesLedger = $DuesLedgerTable(this);
  late final $VariantsTable variants = $VariantsTable(this);
  late final $BatchesTable batches = $BatchesTable(this);
  late final $BatchLinesTable batchLines = $BatchLinesTable(this);
  late final $ArticlesTable articles = $ArticlesTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $BillLinesTable billLines = $BillLinesTable(this);
  late final $BillPaymentsTable billPayments = $BillPaymentsTable(this);
  late final $BillSequencesTable billSequences = $BillSequencesTable(this);
  late final $CreditNoteUsesTable creditNoteUses = $CreditNoteUsesTable(this);
  late final $ReturnLinesTable returnLines = $ReturnLinesTable(this);
  late final $ShiftClosesTable shiftCloses = $ShiftClosesTable(this);
  late final $ShiftBreaksTable shiftBreaks = $ShiftBreaksTable(this);
  late final $ShiftBreakEndsTable shiftBreakEnds = $ShiftBreakEndsTable(this);
  late final $DaybookTable daybook = $DaybookTable(this);
  late final Index usersStaffNumber = Index(
    'users_staff_number',
    'CREATE UNIQUE INDEX users_staff_number ON users (staff_number)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    sizeOptions,
    colorOptions,
    users,
    counters,
    categories,
    products,
    styleMarkdowns,
    customers,
    shifts,
    duesReceipts,
    bills,
    creditNotes,
    returns,
    duesLedger,
    variants,
    batches,
    batchLines,
    articles,
    auditLog,
    outbox,
    billLines,
    billPayments,
    billSequences,
    creditNoteUses,
    returnLines,
    shiftCloses,
    shiftBreaks,
    shiftBreakEnds,
    daybook,
    usersStaffNumber,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String name,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> name,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          SettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      SettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$SizeOptionsTableCreateCompanionBuilder =
    SizeOptionsCompanion Function({
      required String id,
      required String name,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$SizeOptionsTableUpdateCompanionBuilder =
    SizeOptionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$SizeOptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SizeOptionsTable> {
  $$SizeOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SizeOptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SizeOptionsTable> {
  $$SizeOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SizeOptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SizeOptionsTable> {
  $$SizeOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$SizeOptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SizeOptionsTable,
          SizeOptionRow,
          $$SizeOptionsTableFilterComposer,
          $$SizeOptionsTableOrderingComposer,
          $$SizeOptionsTableAnnotationComposer,
          $$SizeOptionsTableCreateCompanionBuilder,
          $$SizeOptionsTableUpdateCompanionBuilder,
          (
            SizeOptionRow,
            BaseReferences<_$AppDatabase, $SizeOptionsTable, SizeOptionRow>,
          ),
          SizeOptionRow,
          PrefetchHooks Function()
        > {
  $$SizeOptionsTableTableManager(_$AppDatabase db, $SizeOptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SizeOptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SizeOptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SizeOptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SizeOptionsCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => SizeOptionsCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SizeOptionsTable, SizeOptionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SizeOptionsTable,
                    SizeOptionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SizeOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SizeOptionsTable,
      SizeOptionRow,
      $$SizeOptionsTableFilterComposer,
      $$SizeOptionsTableOrderingComposer,
      $$SizeOptionsTableAnnotationComposer,
      $$SizeOptionsTableCreateCompanionBuilder,
      $$SizeOptionsTableUpdateCompanionBuilder,
      (
        SizeOptionRow,
        BaseReferences<_$AppDatabase, $SizeOptionsTable, SizeOptionRow>,
      ),
      SizeOptionRow,
      PrefetchHooks Function()
    >;
typedef $$ColorOptionsTableCreateCompanionBuilder =
    ColorOptionsCompanion Function({
      required String id,
      required String name,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$ColorOptionsTableUpdateCompanionBuilder =
    ColorOptionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$ColorOptionsTableFilterComposer
    extends Composer<_$AppDatabase, $ColorOptionsTable> {
  $$ColorOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ColorOptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ColorOptionsTable> {
  $$ColorOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ColorOptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ColorOptionsTable> {
  $$ColorOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ColorOptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ColorOptionsTable,
          ColorOptionRow,
          $$ColorOptionsTableFilterComposer,
          $$ColorOptionsTableOrderingComposer,
          $$ColorOptionsTableAnnotationComposer,
          $$ColorOptionsTableCreateCompanionBuilder,
          $$ColorOptionsTableUpdateCompanionBuilder,
          (
            ColorOptionRow,
            BaseReferences<_$AppDatabase, $ColorOptionsTable, ColorOptionRow>,
          ),
          ColorOptionRow,
          PrefetchHooks Function()
        > {
  $$ColorOptionsTableTableManager(_$AppDatabase db, $ColorOptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ColorOptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ColorOptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ColorOptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ColorOptionsCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => ColorOptionsCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ColorOptionsTable, ColorOptionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ColorOptionsTable,
                    ColorOptionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ColorOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ColorOptionsTable,
      ColorOptionRow,
      $$ColorOptionsTableFilterComposer,
      $$ColorOptionsTableOrderingComposer,
      $$ColorOptionsTableAnnotationComposer,
      $$ColorOptionsTableCreateCompanionBuilder,
      $$ColorOptionsTableUpdateCompanionBuilder,
      (
        ColorOptionRow,
        BaseReferences<_$AppDatabase, $ColorOptionsTable, ColorOptionRow>,
      ),
      ColorOptionRow,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String name,
  required String role,
  required String credentialHash,
  Value<bool> active,
  Value<int?> staffNumber,
  Value<int> failures,
  Value<int> lockCount,
  Value<DateTime?> lockedUntil,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> role,
  Value<String> credentialHash,
  Value<bool> active,
  Value<int?> staffNumber,
  Value<int> failures,
  Value<int> lockCount,
  Value<DateTime?> lockedUntil,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, UserRow> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShiftsTable, List<ShiftRow>> _shiftsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shifts,
    aliasName: 'users__id__shifts__cashier_id',
  );

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.cashierId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillsTable, List<BillRow>> _billsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.bills,
    aliasName: 'users__id__bills__cashier_id',
  );

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.cashierId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CreditNotesTable, List<CreditNoteRow>>
  _creditNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.creditNotes,
    aliasName: 'users__id__credit_notes__issued_by',
  );

  $$CreditNotesTableProcessedTableManager get creditNotesRefs {
    final manager = $$CreditNotesTableTableManager(
      $_db,
      $_db.creditNotes,
    ).filter((f) => f.issuedBy.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_creditNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialHash => $composableBuilder(
    column: $table.credentialHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get staffNumber => $composableBuilder(
    column: $table.staffNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failures => $composableBuilder(
    column: $table.failures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lockCount => $composableBuilder(
    column: $table.lockCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shiftsRefs(
    Expression<bool> Function($$ShiftsTableFilterComposer f) f,
  ) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.cashierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billsRefs(
    Expression<bool> Function($$BillsTableFilterComposer f) f,
  ) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.cashierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> creditNotesRefs(
    Expression<bool> Function($$CreditNotesTableFilterComposer f) f,
  ) {
    final $$CreditNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.issuedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableFilterComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialHash => $composableBuilder(
    column: $table.credentialHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get staffNumber => $composableBuilder(
    column: $table.staffNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failures => $composableBuilder(
    column: $table.failures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lockCount => $composableBuilder(
    column: $table.lockCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get credentialHash => $composableBuilder(
    column: $table.credentialHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get staffNumber => $composableBuilder(
    column: $table.staffNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failures =>
      $composableBuilder(column: $table.failures, builder: (column) => column);

  GeneratedColumn<int> get lockCount =>
      $composableBuilder(column: $table.lockCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> shiftsRefs<T extends Object>(
    Expression<T> Function($$ShiftsTableAnnotationComposer a) f,
  ) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.cashierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billsRefs<T extends Object>(
    Expression<T> Function($$BillsTableAnnotationComposer a) f,
  ) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.cashierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> creditNotesRefs<T extends Object>(
    Expression<T> Function($$CreditNotesTableAnnotationComposer a) f,
  ) {
    final $$CreditNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.issuedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserRow,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserRow, $$UsersTableReferences),
          UserRow,
          PrefetchHooks Function({
            bool shiftsRefs,
            bool billsRefs,
            bool creditNotesRefs,
          })
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> credentialHash = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int?> staffNumber = const Value.absent(),
                Value<int> failures = const Value.absent(),
                Value<int> lockCount = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                role: role,
                credentialHash: credentialHash,
                active: active,
                staffNumber: staffNumber,
                failures: failures,
                lockCount: lockCount,
                lockedUntil: lockedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String role,
                required String credentialHash,
                Value<bool> active = const Value.absent(),
                Value<int?> staffNumber = const Value.absent(),
                Value<int> failures = const Value.absent(),
                Value<int> lockCount = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                role: role,
                credentialHash: credentialHash,
                active: active,
                staffNumber: staffNumber,
                failures: failures,
                lockCount: lockCount,
                lockedUntil: lockedUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsersTable, UserRow>(table),
                  $$UsersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                shiftsRefs = false,
                billsRefs = false,
                creditNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shiftsRefs) db.shifts,
                    if (billsRefs) db.bills,
                    if (creditNotesRefs) db.creditNotes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shiftsRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          ShiftRow,
                          $ShiftsTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._shiftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(db, table, p0).shiftsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'cashier_id',
                          typedResults: items,
                        ),
                      if (billsRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          BillRow,
                          $BillsTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._billsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(db, table, p0).billsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'cashier_id',
                          typedResults: items,
                        ),
                      if (creditNotesRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          CreditNoteRow,
                          $CreditNotesTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._creditNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).creditNotesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'issued_by',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserRow,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserRow, $$UsersTableReferences),
      UserRow,
      PrefetchHooks Function({
        bool shiftsRefs,
        bool billsRefs,
        bool creditNotesRefs,
      })
    >;
typedef $$CountersTableCreateCompanionBuilder = CountersCompanion Function({
  required String id,
  required String name,
  required int lotFirst,
  required int lotLast,
  required int currentLot,
  required int nextSerial,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CountersTableUpdateCompanionBuilder = CountersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> lotFirst,
  Value<int> lotLast,
  Value<int> currentLot,
  Value<int> nextSerial,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$CountersTableReferences
    extends BaseReferences<_$AppDatabase, $CountersTable, CounterRow> {
  $$CountersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShiftsTable, List<ShiftRow>> _shiftsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shifts,
    aliasName: 'counters__id__shifts__counter_id',
  );

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.counterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillsTable, List<BillRow>> _billsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.bills,
    aliasName: 'counters__id__bills__counter_id',
  );

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.counterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CreditNotesTable, List<CreditNoteRow>>
  _creditNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.creditNotes,
    aliasName: 'counters__id__credit_notes__counter_id',
  );

  $$CreditNotesTableProcessedTableManager get creditNotesRefs {
    final manager = $$CreditNotesTableTableManager(
      $_db,
      $_db.creditNotes,
    ).filter((f) => f.counterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_creditNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillSequencesTable, List<BillSequenceRow>>
  _billSequencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.billSequences,
    aliasName: 'counters__id__bill_sequences__counter_id',
  );

  $$BillSequencesTableProcessedTableManager get billSequencesRefs {
    final manager = $$BillSequencesTableTableManager(
      $_db,
      $_db.billSequences,
    ).filter((f) => f.counterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billSequencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CountersTableFilterComposer
    extends Composer<_$AppDatabase, $CountersTable> {
  $$CountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lotFirst => $composableBuilder(
    column: $table.lotFirst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lotLast => $composableBuilder(
    column: $table.lotLast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentLot => $composableBuilder(
    column: $table.currentLot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextSerial => $composableBuilder(
    column: $table.nextSerial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shiftsRefs(
    Expression<bool> Function($$ShiftsTableFilterComposer f) f,
  ) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billsRefs(
    Expression<bool> Function($$BillsTableFilterComposer f) f,
  ) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> creditNotesRefs(
    Expression<bool> Function($$CreditNotesTableFilterComposer f) f,
  ) {
    final $$CreditNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableFilterComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billSequencesRefs(
    Expression<bool> Function($$BillSequencesTableFilterComposer f) f,
  ) {
    final $$BillSequencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billSequences,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillSequencesTableFilterComposer(
            $db: $db,
            $table: $db.billSequences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CountersTableOrderingComposer
    extends Composer<_$AppDatabase, $CountersTable> {
  $$CountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lotFirst => $composableBuilder(
    column: $table.lotFirst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lotLast => $composableBuilder(
    column: $table.lotLast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentLot => $composableBuilder(
    column: $table.currentLot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextSerial => $composableBuilder(
    column: $table.nextSerial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CountersTable> {
  $$CountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get lotFirst =>
      $composableBuilder(column: $table.lotFirst, builder: (column) => column);

  GeneratedColumn<int> get lotLast =>
      $composableBuilder(column: $table.lotLast, builder: (column) => column);

  GeneratedColumn<int> get currentLot => $composableBuilder(
    column: $table.currentLot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextSerial => $composableBuilder(
    column: $table.nextSerial,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> shiftsRefs<T extends Object>(
    Expression<T> Function($$ShiftsTableAnnotationComposer a) f,
  ) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billsRefs<T extends Object>(
    Expression<T> Function($$BillsTableAnnotationComposer a) f,
  ) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> creditNotesRefs<T extends Object>(
    Expression<T> Function($$CreditNotesTableAnnotationComposer a) f,
  ) {
    final $$CreditNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billSequencesRefs<T extends Object>(
    Expression<T> Function($$BillSequencesTableAnnotationComposer a) f,
  ) {
    final $$BillSequencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billSequences,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillSequencesTableAnnotationComposer(
            $db: $db,
            $table: $db.billSequences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CountersTable,
          CounterRow,
          $$CountersTableFilterComposer,
          $$CountersTableOrderingComposer,
          $$CountersTableAnnotationComposer,
          $$CountersTableCreateCompanionBuilder,
          $$CountersTableUpdateCompanionBuilder,
          (CounterRow, $$CountersTableReferences),
          CounterRow,
          PrefetchHooks Function({
            bool shiftsRefs,
            bool billsRefs,
            bool creditNotesRefs,
            bool billSequencesRefs,
          })
        > {
  $$CountersTableTableManager(_$AppDatabase db, $CountersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> lotFirst = const Value.absent(),
                Value<int> lotLast = const Value.absent(),
                Value<int> currentLot = const Value.absent(),
                Value<int> nextSerial = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CountersCompanion(
                id: id,
                name: name,
                lotFirst: lotFirst,
                lotLast: lotLast,
                currentLot: currentLot,
                nextSerial: nextSerial,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int lotFirst,
                required int lotLast,
                required int currentLot,
                required int nextSerial,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CountersCompanion.insert(
                id: id,
                name: name,
                lotFirst: lotFirst,
                lotLast: lotLast,
                currentLot: currentLot,
                nextSerial: nextSerial,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CountersTable, CounterRow>(table),
                  $$CountersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                shiftsRefs = false,
                billsRefs = false,
                creditNotesRefs = false,
                billSequencesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shiftsRefs) db.shifts,
                    if (billsRefs) db.bills,
                    if (creditNotesRefs) db.creditNotes,
                    if (billSequencesRefs) db.billSequences,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shiftsRefs)
                        await $_getPrefetchedDataByColumns<
                          CounterRow,
                          $CountersTable,
                          ShiftRow,
                          $ShiftsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CountersTableReferences
                              ._shiftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CountersTableReferences(
                                db,
                                table,
                                p0,
                              ).shiftsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'counter_id',
                          typedResults: items,
                        ),
                      if (billsRefs)
                        await $_getPrefetchedDataByColumns<
                          CounterRow,
                          $CountersTable,
                          BillRow,
                          $BillsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CountersTableReferences
                              ._billsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CountersTableReferences(
                                db,
                                table,
                                p0,
                              ).billsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'counter_id',
                          typedResults: items,
                        ),
                      if (creditNotesRefs)
                        await $_getPrefetchedDataByColumns<
                          CounterRow,
                          $CountersTable,
                          CreditNoteRow,
                          $CreditNotesTable
                        >(
                          currentTable: table,
                          referencedTable: $$CountersTableReferences
                              ._creditNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CountersTableReferences(
                                db,
                                table,
                                p0,
                              ).creditNotesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'counter_id',
                          typedResults: items,
                        ),
                      if (billSequencesRefs)
                        await $_getPrefetchedDataByColumns<
                          CounterRow,
                          $CountersTable,
                          BillSequenceRow,
                          $BillSequencesTable
                        >(
                          currentTable: table,
                          referencedTable: $$CountersTableReferences
                              ._billSequencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CountersTableReferences(
                                db,
                                table,
                                p0,
                              ).billSequencesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'counter_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CountersTable,
      CounterRow,
      $$CountersTableFilterComposer,
      $$CountersTableOrderingComposer,
      $$CountersTableAnnotationComposer,
      $$CountersTableCreateCompanionBuilder,
      $$CountersTableUpdateCompanionBuilder,
      (CounterRow, $$CountersTableReferences),
      CounterRow,
      PrefetchHooks Function({
        bool shiftsRefs,
        bool billsRefs,
        bool creditNotesRefs,
        bool billSequencesRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  Value<String?> parentId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> parentId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias('categories__parent_id__categories__id');

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProductsTable, List<ProductRow>>
  _productsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.products,
    aliasName: 'categories__id__products__category_id',
  );

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> productsRefs(
    Expression<bool> Function($$ProductsTableFilterComposer f) f,
  ) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> productsRefs<T extends Object>(
    Expression<T> Function($$ProductsTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({bool parentId, bool productsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                parentId: parentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> parentId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false, productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parentId,
                        referencedTable: $$CategoriesTableReferences
                            ._parentIdTable(db),
                        referencedColumn: $$CategoriesTableReferences
                            ._parentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedDataByColumns<
                      CategoryRow,
                      $CategoriesTable,
                      ProductRow,
                      $ProductsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._productsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).productsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool parentId, bool productsRefs})
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String name,
  Value<String?> createdBy,
  Value<String?> categoryId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> createdBy,
  Value<String?> categoryId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductRow> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('products__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StyleMarkdownsTable, List<StyleMarkdownRow>>
  _styleMarkdownsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.styleMarkdowns,
    aliasName: 'products__id__style_markdowns__product_id',
  );

  $$StyleMarkdownsTableProcessedTableManager get styleMarkdownsRefs {
    final manager = $$StyleMarkdownsTableTableManager(
      $_db,
      $_db.styleMarkdowns,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_styleMarkdownsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VariantsTable, List<VariantRow>>
  _variantsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.variants,
    aliasName: 'products__id__variants__product_id',
  );

  $$VariantsTableProcessedTableManager get variantsRefs {
    final manager = $$VariantsTableTableManager(
      $_db,
      $_db.variants,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_variantsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> styleMarkdownsRefs(
    Expression<bool> Function($$StyleMarkdownsTableFilterComposer f) f,
  ) {
    final $$StyleMarkdownsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.styleMarkdowns,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StyleMarkdownsTableFilterComposer(
            $db: $db,
            $table: $db.styleMarkdowns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> variantsRefs(
    Expression<bool> Function($$VariantsTableFilterComposer f) f,
  ) {
    final $$VariantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.variants,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantsTableFilterComposer(
            $db: $db,
            $table: $db.variants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> styleMarkdownsRefs<T extends Object>(
    Expression<T> Function($$StyleMarkdownsTableAnnotationComposer a) f,
  ) {
    final $$StyleMarkdownsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.styleMarkdowns,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StyleMarkdownsTableAnnotationComposer(
            $db: $db,
            $table: $db.styleMarkdowns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> variantsRefs<T extends Object>(
    Expression<T> Function($$VariantsTableAnnotationComposer a) f,
  ) {
    final $$VariantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.variants,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantsTableAnnotationComposer(
            $db: $db,
            $table: $db.variants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ProductRow,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (ProductRow, $$ProductsTableReferences),
          ProductRow,
          PrefetchHooks Function({
            bool categoryId,
            bool styleMarkdownsRefs,
            bool variantsRefs,
          })
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                createdBy: createdBy,
                categoryId: categoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> createdBy = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                createdBy: createdBy,
                categoryId: categoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, ProductRow>(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                styleMarkdownsRefs = false,
                variantsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (styleMarkdownsRefs) db.styleMarkdowns,
                    if (variantsRefs) db.variants,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$ProductsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$ProductsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (styleMarkdownsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProductRow,
                          $ProductsTable,
                          StyleMarkdownRow,
                          $StyleMarkdownsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._styleMarkdownsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).styleMarkdownsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'product_id',
                          typedResults: items,
                        ),
                      if (variantsRefs)
                        await $_getPrefetchedDataByColumns<
                          ProductRow,
                          $ProductsTable,
                          VariantRow,
                          $VariantsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._variantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).variantsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'product_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ProductRow,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (ProductRow, $$ProductsTableReferences),
      ProductRow,
      PrefetchHooks Function({
        bool categoryId,
        bool styleMarkdownsRefs,
        bool variantsRefs,
      })
    >;
typedef $$StyleMarkdownsTableCreateCompanionBuilder =
    StyleMarkdownsCompanion Function({
      required String productId,
      Value<int?> percentBp,
      Value<int?> amountPaise,
      required DateTime endsBefore,
      required String setBy,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StyleMarkdownsTableUpdateCompanionBuilder =
    StyleMarkdownsCompanion Function({
      Value<String> productId,
      Value<int?> percentBp,
      Value<int?> amountPaise,
      Value<DateTime> endsBefore,
      Value<String> setBy,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$StyleMarkdownsTableReferences
    extends
        BaseReferences<_$AppDatabase, $StyleMarkdownsTable, StyleMarkdownRow> {
  $$StyleMarkdownsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('style_markdowns__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StyleMarkdownsTableFilterComposer
    extends Composer<_$AppDatabase, $StyleMarkdownsTable> {
  $$StyleMarkdownsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get percentBp => $composableBuilder(
    column: $table.percentBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsBefore => $composableBuilder(
    column: $table.endsBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setBy => $composableBuilder(
    column: $table.setBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StyleMarkdownsTableOrderingComposer
    extends Composer<_$AppDatabase, $StyleMarkdownsTable> {
  $$StyleMarkdownsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get percentBp => $composableBuilder(
    column: $table.percentBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsBefore => $composableBuilder(
    column: $table.endsBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setBy => $composableBuilder(
    column: $table.setBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StyleMarkdownsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StyleMarkdownsTable> {
  $$StyleMarkdownsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get percentBp =>
      $composableBuilder(column: $table.percentBp, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endsBefore => $composableBuilder(
    column: $table.endsBefore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get setBy =>
      $composableBuilder(column: $table.setBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StyleMarkdownsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StyleMarkdownsTable,
          StyleMarkdownRow,
          $$StyleMarkdownsTableFilterComposer,
          $$StyleMarkdownsTableOrderingComposer,
          $$StyleMarkdownsTableAnnotationComposer,
          $$StyleMarkdownsTableCreateCompanionBuilder,
          $$StyleMarkdownsTableUpdateCompanionBuilder,
          (StyleMarkdownRow, $$StyleMarkdownsTableReferences),
          StyleMarkdownRow,
          PrefetchHooks Function({bool productId})
        > {
  $$StyleMarkdownsTableTableManager(
    _$AppDatabase db,
    $StyleMarkdownsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StyleMarkdownsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StyleMarkdownsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StyleMarkdownsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<int?> percentBp = const Value.absent(),
                Value<int?> amountPaise = const Value.absent(),
                Value<DateTime> endsBefore = const Value.absent(),
                Value<String> setBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StyleMarkdownsCompanion(
                productId: productId,
                percentBp: percentBp,
                amountPaise: amountPaise,
                endsBefore: endsBefore,
                setBy: setBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                Value<int?> percentBp = const Value.absent(),
                Value<int?> amountPaise = const Value.absent(),
                required DateTime endsBefore,
                required String setBy,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StyleMarkdownsCompanion.insert(
                productId: productId,
                percentBp: percentBp,
                amountPaise: amountPaise,
                endsBefore: endsBefore,
                setBy: setBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StyleMarkdownsTable, StyleMarkdownRow>(table),
                  $$StyleMarkdownsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$StyleMarkdownsTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$StyleMarkdownsTableReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StyleMarkdownsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StyleMarkdownsTable,
      StyleMarkdownRow,
      $$StyleMarkdownsTableFilterComposer,
      $$StyleMarkdownsTableOrderingComposer,
      $$StyleMarkdownsTableAnnotationComposer,
      $$StyleMarkdownsTableCreateCompanionBuilder,
      $$StyleMarkdownsTableUpdateCompanionBuilder,
      (StyleMarkdownRow, $$StyleMarkdownsTableReferences),
      StyleMarkdownRow,
      PrefetchHooks Function({bool productId})
    >;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String name,
  required String phone,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$CustomersTableReferences
    extends BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow> {
  $$CustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DuesReceiptsTable, List<DuesReceiptRow>>
  _duesReceiptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.duesReceipts,
    aliasName: 'customers__id__dues_receipts__customer_id',
  );

  $$DuesReceiptsTableProcessedTableManager get duesReceiptsRefs {
    final manager = $$DuesReceiptsTableTableManager(
      $_db,
      $_db.duesReceipts,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_duesReceiptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DuesLedgerTable, List<DuesLedgerRow>>
  _duesLedgerRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.duesLedger,
    aliasName: 'customers__id__dues_ledger__customer_id',
  );

  $$DuesLedgerTableProcessedTableManager get duesLedgerRefs {
    final manager = $$DuesLedgerTableTableManager(
      $_db,
      $_db.duesLedger,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_duesLedgerRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> duesReceiptsRefs(
    Expression<bool> Function($$DuesReceiptsTableFilterComposer f) f,
  ) {
    final $$DuesReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesReceipts,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.duesReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> duesLedgerRefs(
    Expression<bool> Function($$DuesLedgerTableFilterComposer f) f,
  ) {
    final $$DuesLedgerTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesLedger,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesLedgerTableFilterComposer(
            $db: $db,
            $table: $db.duesLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> duesReceiptsRefs<T extends Object>(
    Expression<T> Function($$DuesReceiptsTableAnnotationComposer a) f,
  ) {
    final $$DuesReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesReceipts,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.duesReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> duesLedgerRefs<T extends Object>(
    Expression<T> Function($$DuesLedgerTableAnnotationComposer a) f,
  ) {
    final $$DuesLedgerTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesLedger,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesLedgerTableAnnotationComposer(
            $db: $db,
            $table: $db.duesLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          CustomerRow,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (CustomerRow, $$CustomersTableReferences),
          CustomerRow,
          PrefetchHooks Function({bool duesReceiptsRefs, bool duesLedgerRefs})
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                name: name,
                phone: phone,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String phone,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomersTable, CustomerRow>(table),
                  $$CustomersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({duesReceiptsRefs = false, duesLedgerRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (duesReceiptsRefs) db.duesReceipts,
                    if (duesLedgerRefs) db.duesLedger,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (duesReceiptsRefs)
                        await $_getPrefetchedDataByColumns<
                          CustomerRow,
                          $CustomersTable,
                          DuesReceiptRow,
                          $DuesReceiptsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CustomersTableReferences
                              ._duesReceiptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomersTableReferences(
                                db,
                                table,
                                p0,
                              ).duesReceiptsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'customer_id',
                          typedResults: items,
                        ),
                      if (duesLedgerRefs)
                        await $_getPrefetchedDataByColumns<
                          CustomerRow,
                          $CustomersTable,
                          DuesLedgerRow,
                          $DuesLedgerTable
                        >(
                          currentTable: table,
                          referencedTable: $$CustomersTableReferences
                              ._duesLedgerRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomersTableReferences(
                                db,
                                table,
                                p0,
                              ).duesLedgerRefs,
                          currentColumn: 'id',
                          referencedColumn: 'customer_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      CustomerRow,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (CustomerRow, $$CustomersTableReferences),
      CustomerRow,
      PrefetchHooks Function({bool duesReceiptsRefs, bool duesLedgerRefs})
    >;
typedef $$ShiftsTableCreateCompanionBuilder = ShiftsCompanion Function({
  required String id,
  required String cashierId,
  required String counterId,
  required DateTime openedAt,
  required int openingPaise,
  required String openingCount,
  Value<int> rowid,
});
typedef $$ShiftsTableUpdateCompanionBuilder = ShiftsCompanion Function({
  Value<String> id,
  Value<String> cashierId,
  Value<String> counterId,
  Value<DateTime> openedAt,
  Value<int> openingPaise,
  Value<String> openingCount,
  Value<int> rowid,
});

final class $$ShiftsTableReferences
    extends BaseReferences<_$AppDatabase, $ShiftsTable, ShiftRow> {
  $$ShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _cashierIdTable(_$AppDatabase db) =>
      db.users.createAlias('shifts__cashier_id__users__id');

  $$UsersTableProcessedTableManager get cashierId {
    final $_column = $_itemColumn<String>('cashier_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CountersTable _counterIdTable(_$AppDatabase db) =>
      db.counters.createAlias('shifts__counter_id__counters__id');

  $$CountersTableProcessedTableManager get counterId {
    final $_column = $_itemColumn<String>('counter_id')!;

    final manager = $$CountersTableTableManager(
      $_db,
      $_db.counters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DuesReceiptsTable, List<DuesReceiptRow>>
  _duesReceiptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.duesReceipts,
    aliasName: 'shifts__id__dues_receipts__shift_id',
  );

  $$DuesReceiptsTableProcessedTableManager get duesReceiptsRefs {
    final manager = $$DuesReceiptsTableTableManager(
      $_db,
      $_db.duesReceipts,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_duesReceiptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillsTable, List<BillRow>> _billsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.bills,
    aliasName: 'shifts__id__bills__shift_id',
  );

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReturnsTable, List<ReturnRow>> _returnsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.returns,
    aliasName: 'shifts__id__returns__shift_id',
  );

  $$ReturnsTableProcessedTableManager get returnsRefs {
    final manager = $$ReturnsTableTableManager(
      $_db,
      $_db.returns,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_returnsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShiftClosesTable, List<ShiftCloseRow>>
  _shiftClosesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shiftCloses,
    aliasName: 'shifts__id__shift_closes__shift_id',
  );

  $$ShiftClosesTableProcessedTableManager get shiftClosesRefs {
    final manager = $$ShiftClosesTableTableManager(
      $_db,
      $_db.shiftCloses,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftClosesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShiftBreaksTable, List<ShiftBreakRow>>
  _shiftBreaksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shiftBreaks,
    aliasName: 'shifts__id__shift_breaks__shift_id',
  );

  $$ShiftBreaksTableProcessedTableManager get shiftBreaksRefs {
    final manager = $$ShiftBreaksTableTableManager(
      $_db,
      $_db.shiftBreaks,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftBreaksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DaybookTable, List<DaybookRow>> _daybookRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.daybook,
    aliasName: 'shifts__id__daybook__shift_id',
  );

  $$DaybookTableProcessedTableManager get daybookRefs {
    final manager = $$DaybookTableTableManager(
      $_db,
      $_db.daybook,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_daybookRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShiftsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingPaise => $composableBuilder(
    column: $table.openingPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingCount => $composableBuilder(
    column: $table.openingCount,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get cashierId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CountersTableFilterComposer get counterId {
    final $$CountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableFilterComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> duesReceiptsRefs(
    Expression<bool> Function($$DuesReceiptsTableFilterComposer f) f,
  ) {
    final $$DuesReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesReceipts,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.duesReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billsRefs(
    Expression<bool> Function($$BillsTableFilterComposer f) f,
  ) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> returnsRefs(
    Expression<bool> Function($$ReturnsTableFilterComposer f) f,
  ) {
    final $$ReturnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableFilterComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shiftClosesRefs(
    Expression<bool> Function($$ShiftClosesTableFilterComposer f) f,
  ) {
    final $$ShiftClosesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shiftCloses,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftClosesTableFilterComposer(
            $db: $db,
            $table: $db.shiftCloses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shiftBreaksRefs(
    Expression<bool> Function($$ShiftBreaksTableFilterComposer f) f,
  ) {
    final $$ShiftBreaksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shiftBreaks,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftBreaksTableFilterComposer(
            $db: $db,
            $table: $db.shiftBreaks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> daybookRefs(
    Expression<bool> Function($$DaybookTableFilterComposer f) f,
  ) {
    final $$DaybookTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.daybook,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaybookTableFilterComposer(
            $db: $db,
            $table: $db.daybook,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingPaise => $composableBuilder(
    column: $table.openingPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingCount => $composableBuilder(
    column: $table.openingCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get cashierId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CountersTableOrderingComposer get counterId {
    final $$CountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableOrderingComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<int> get openingPaise => $composableBuilder(
    column: $table.openingPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openingCount => $composableBuilder(
    column: $table.openingCount,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get cashierId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CountersTableAnnotationComposer get counterId {
    final $$CountersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableAnnotationComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> duesReceiptsRefs<T extends Object>(
    Expression<T> Function($$DuesReceiptsTableAnnotationComposer a) f,
  ) {
    final $$DuesReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesReceipts,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.duesReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billsRefs<T extends Object>(
    Expression<T> Function($$BillsTableAnnotationComposer a) f,
  ) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> returnsRefs<T extends Object>(
    Expression<T> Function($$ReturnsTableAnnotationComposer a) f,
  ) {
    final $$ReturnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableAnnotationComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shiftClosesRefs<T extends Object>(
    Expression<T> Function($$ShiftClosesTableAnnotationComposer a) f,
  ) {
    final $$ShiftClosesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shiftCloses,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftClosesTableAnnotationComposer(
            $db: $db,
            $table: $db.shiftCloses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shiftBreaksRefs<T extends Object>(
    Expression<T> Function($$ShiftBreaksTableAnnotationComposer a) f,
  ) {
    final $$ShiftBreaksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shiftBreaks,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftBreaksTableAnnotationComposer(
            $db: $db,
            $table: $db.shiftBreaks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> daybookRefs<T extends Object>(
    Expression<T> Function($$DaybookTableAnnotationComposer a) f,
  ) {
    final $$DaybookTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.daybook,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaybookTableAnnotationComposer(
            $db: $db,
            $table: $db.daybook,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftsTable,
          ShiftRow,
          $$ShiftsTableFilterComposer,
          $$ShiftsTableOrderingComposer,
          $$ShiftsTableAnnotationComposer,
          $$ShiftsTableCreateCompanionBuilder,
          $$ShiftsTableUpdateCompanionBuilder,
          (ShiftRow, $$ShiftsTableReferences),
          ShiftRow,
          PrefetchHooks Function({
            bool cashierId,
            bool counterId,
            bool duesReceiptsRefs,
            bool billsRefs,
            bool returnsRefs,
            bool shiftClosesRefs,
            bool shiftBreaksRefs,
            bool daybookRefs,
          })
        > {
  $$ShiftsTableTableManager(_$AppDatabase db, $ShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String> counterId = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<int> openingPaise = const Value.absent(),
                Value<String> openingCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftsCompanion(
                id: id,
                cashierId: cashierId,
                counterId: counterId,
                openedAt: openedAt,
                openingPaise: openingPaise,
                openingCount: openingCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cashierId,
                required String counterId,
                required DateTime openedAt,
                required int openingPaise,
                required String openingCount,
                Value<int> rowid = const Value.absent(),
              }) => ShiftsCompanion.insert(
                id: id,
                cashierId: cashierId,
                counterId: counterId,
                openedAt: openedAt,
                openingPaise: openingPaise,
                openingCount: openingCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShiftsTable, ShiftRow>(table),
                  $$ShiftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cashierId = false,
                counterId = false,
                duesReceiptsRefs = false,
                billsRefs = false,
                returnsRefs = false,
                shiftClosesRefs = false,
                shiftBreaksRefs = false,
                daybookRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (duesReceiptsRefs) db.duesReceipts,
                    if (billsRefs) db.bills,
                    if (returnsRefs) db.returns,
                    if (shiftClosesRefs) db.shiftCloses,
                    if (shiftBreaksRefs) db.shiftBreaks,
                    if (daybookRefs) db.daybook,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cashierId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cashierId,
                            referencedTable: $$ShiftsTableReferences
                                ._cashierIdTable(db),
                            referencedColumn: $$ShiftsTableReferences
                                ._cashierIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (counterId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.counterId,
                            referencedTable: $$ShiftsTableReferences
                                ._counterIdTable(db),
                            referencedColumn: $$ShiftsTableReferences
                                ._counterIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (duesReceiptsRefs)
                        await $_getPrefetchedDataByColumns<
                          ShiftRow,
                          $ShiftsTable,
                          DuesReceiptRow,
                          $DuesReceiptsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._duesReceiptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(
                                db,
                                table,
                                p0,
                              ).duesReceiptsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'shift_id',
                          typedResults: items,
                        ),
                      if (billsRefs)
                        await $_getPrefetchedDataByColumns<
                          ShiftRow,
                          $ShiftsTable,
                          BillRow,
                          $BillsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._billsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(db, table, p0).billsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'shift_id',
                          typedResults: items,
                        ),
                      if (returnsRefs)
                        await $_getPrefetchedDataByColumns<
                          ShiftRow,
                          $ShiftsTable,
                          ReturnRow,
                          $ReturnsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._returnsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(
                                db,
                                table,
                                p0,
                              ).returnsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'shift_id',
                          typedResults: items,
                        ),
                      if (shiftClosesRefs)
                        await $_getPrefetchedDataByColumns<
                          ShiftRow,
                          $ShiftsTable,
                          ShiftCloseRow,
                          $ShiftClosesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._shiftClosesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(
                                db,
                                table,
                                p0,
                              ).shiftClosesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'shift_id',
                          typedResults: items,
                        ),
                      if (shiftBreaksRefs)
                        await $_getPrefetchedDataByColumns<
                          ShiftRow,
                          $ShiftsTable,
                          ShiftBreakRow,
                          $ShiftBreaksTable
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._shiftBreaksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(
                                db,
                                table,
                                p0,
                              ).shiftBreaksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'shift_id',
                          typedResults: items,
                        ),
                      if (daybookRefs)
                        await $_getPrefetchedDataByColumns<
                          ShiftRow,
                          $ShiftsTable,
                          DaybookRow,
                          $DaybookTable
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftsTableReferences
                              ._daybookRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftsTableReferences(
                                db,
                                table,
                                p0,
                              ).daybookRefs,
                          currentColumn: 'id',
                          referencedColumn: 'shift_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftsTable,
      ShiftRow,
      $$ShiftsTableFilterComposer,
      $$ShiftsTableOrderingComposer,
      $$ShiftsTableAnnotationComposer,
      $$ShiftsTableCreateCompanionBuilder,
      $$ShiftsTableUpdateCompanionBuilder,
      (ShiftRow, $$ShiftsTableReferences),
      ShiftRow,
      PrefetchHooks Function({
        bool cashierId,
        bool counterId,
        bool duesReceiptsRefs,
        bool billsRefs,
        bool returnsRefs,
        bool shiftClosesRefs,
        bool shiftBreaksRefs,
        bool daybookRefs,
      })
    >;
typedef $$DuesReceiptsTableCreateCompanionBuilder =
    DuesReceiptsCompanion Function({
      required String id,
      required String customerId,
      required DateTime at,
      required String shiftId,
      required String receivedBy,
      required int cashPaise,
      required int upiPaise,
      required int cardPaise,
      required int changePaise,
      required int appliedPaise,
      Value<int> rowid,
    });
typedef $$DuesReceiptsTableUpdateCompanionBuilder =
    DuesReceiptsCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<DateTime> at,
      Value<String> shiftId,
      Value<String> receivedBy,
      Value<int> cashPaise,
      Value<int> upiPaise,
      Value<int> cardPaise,
      Value<int> changePaise,
      Value<int> appliedPaise,
      Value<int> rowid,
    });

final class $$DuesReceiptsTableReferences
    extends BaseReferences<_$AppDatabase, $DuesReceiptsTable, DuesReceiptRow> {
  $$DuesReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomersTable _customerIdTable(_$AppDatabase db) =>
      db.customers.createAlias('dues_receipts__customer_id__customers__id');

  $$CustomersTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomersTableTableManager(
      $_db,
      $_db.customers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) =>
      db.shifts.createAlias('dues_receipts__shift_id__shifts__id');

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<String>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DuesLedgerTable, List<DuesLedgerRow>>
  _duesLedgerRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.duesLedger,
    aliasName: 'dues_receipts__id__dues_ledger__receipt_id',
  );

  $$DuesLedgerTableProcessedTableManager get duesLedgerRefs {
    final manager = $$DuesLedgerTableTableManager(
      $_db,
      $_db.duesLedger,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_duesLedgerRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DuesReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $DuesReceiptsTable> {
  $$DuesReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivedBy => $composableBuilder(
    column: $table.receivedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashPaise => $composableBuilder(
    column: $table.cashPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get upiPaise => $composableBuilder(
    column: $table.upiPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardPaise => $composableBuilder(
    column: $table.cardPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changePaise => $composableBuilder(
    column: $table.changePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedPaise => $composableBuilder(
    column: $table.appliedPaise,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableFilterComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> duesLedgerRefs(
    Expression<bool> Function($$DuesLedgerTableFilterComposer f) f,
  ) {
    final $$DuesLedgerTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesLedger,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesLedgerTableFilterComposer(
            $db: $db,
            $table: $db.duesLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DuesReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $DuesReceiptsTable> {
  $$DuesReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivedBy => $composableBuilder(
    column: $table.receivedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashPaise => $composableBuilder(
    column: $table.cashPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get upiPaise => $composableBuilder(
    column: $table.upiPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardPaise => $composableBuilder(
    column: $table.cardPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changePaise => $composableBuilder(
    column: $table.changePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedPaise => $composableBuilder(
    column: $table.appliedPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableOrderingComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuesReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DuesReceiptsTable> {
  $$DuesReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get receivedBy => $composableBuilder(
    column: $table.receivedBy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashPaise =>
      $composableBuilder(column: $table.cashPaise, builder: (column) => column);

  GeneratedColumn<int> get upiPaise =>
      $composableBuilder(column: $table.upiPaise, builder: (column) => column);

  GeneratedColumn<int> get cardPaise =>
      $composableBuilder(column: $table.cardPaise, builder: (column) => column);

  GeneratedColumn<int> get changePaise => $composableBuilder(
    column: $table.changePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get appliedPaise => $composableBuilder(
    column: $table.appliedPaise,
    builder: (column) => column,
  );

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableAnnotationComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> duesLedgerRefs<T extends Object>(
    Expression<T> Function($$DuesLedgerTableAnnotationComposer a) f,
  ) {
    final $$DuesLedgerTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesLedger,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesLedgerTableAnnotationComposer(
            $db: $db,
            $table: $db.duesLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DuesReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DuesReceiptsTable,
          DuesReceiptRow,
          $$DuesReceiptsTableFilterComposer,
          $$DuesReceiptsTableOrderingComposer,
          $$DuesReceiptsTableAnnotationComposer,
          $$DuesReceiptsTableCreateCompanionBuilder,
          $$DuesReceiptsTableUpdateCompanionBuilder,
          (DuesReceiptRow, $$DuesReceiptsTableReferences),
          DuesReceiptRow,
          PrefetchHooks Function({
            bool customerId,
            bool shiftId,
            bool duesLedgerRefs,
          })
        > {
  $$DuesReceiptsTableTableManager(_$AppDatabase db, $DuesReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DuesReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DuesReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DuesReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> receivedBy = const Value.absent(),
                Value<int> cashPaise = const Value.absent(),
                Value<int> upiPaise = const Value.absent(),
                Value<int> cardPaise = const Value.absent(),
                Value<int> changePaise = const Value.absent(),
                Value<int> appliedPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DuesReceiptsCompanion(
                id: id,
                customerId: customerId,
                at: at,
                shiftId: shiftId,
                receivedBy: receivedBy,
                cashPaise: cashPaise,
                upiPaise: upiPaise,
                cardPaise: cardPaise,
                changePaise: changePaise,
                appliedPaise: appliedPaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required DateTime at,
                required String shiftId,
                required String receivedBy,
                required int cashPaise,
                required int upiPaise,
                required int cardPaise,
                required int changePaise,
                required int appliedPaise,
                Value<int> rowid = const Value.absent(),
              }) => DuesReceiptsCompanion.insert(
                id: id,
                customerId: customerId,
                at: at,
                shiftId: shiftId,
                receivedBy: receivedBy,
                cashPaise: cashPaise,
                upiPaise: upiPaise,
                cardPaise: cardPaise,
                changePaise: changePaise,
                appliedPaise: appliedPaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DuesReceiptsTable, DuesReceiptRow>(table),
                  $$DuesReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({customerId = false, shiftId = false, duesLedgerRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (duesLedgerRefs) db.duesLedger],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (customerId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.customerId,
                            referencedTable: $$DuesReceiptsTableReferences
                                ._customerIdTable(db),
                            referencedColumn: $$DuesReceiptsTableReferences
                                ._customerIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (shiftId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.shiftId,
                            referencedTable: $$DuesReceiptsTableReferences
                                ._shiftIdTable(db),
                            referencedColumn: $$DuesReceiptsTableReferences
                                ._shiftIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (duesLedgerRefs)
                        await $_getPrefetchedDataByColumns<
                          DuesReceiptRow,
                          $DuesReceiptsTable,
                          DuesLedgerRow,
                          $DuesLedgerTable
                        >(
                          currentTable: table,
                          referencedTable: $$DuesReceiptsTableReferences
                              ._duesLedgerRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DuesReceiptsTableReferences(
                                db,
                                table,
                                p0,
                              ).duesLedgerRefs,
                          currentColumn: 'id',
                          referencedColumn: 'receipt_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DuesReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DuesReceiptsTable,
      DuesReceiptRow,
      $$DuesReceiptsTableFilterComposer,
      $$DuesReceiptsTableOrderingComposer,
      $$DuesReceiptsTableAnnotationComposer,
      $$DuesReceiptsTableCreateCompanionBuilder,
      $$DuesReceiptsTableUpdateCompanionBuilder,
      (DuesReceiptRow, $$DuesReceiptsTableReferences),
      DuesReceiptRow,
      PrefetchHooks Function({
        bool customerId,
        bool shiftId,
        bool duesLedgerRefs,
      })
    >;
typedef $$BillsTableCreateCompanionBuilder = BillsCompanion Function({
  required String id,
  required String billNo,
  required String counterId,
  required String cashierId,
  Value<String?> shiftId,
  Value<String?> customerName,
  Value<String?> customerPhone,
  required int totalPaise,
  required int changePaise,
  required DateTime billedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$BillsTableUpdateCompanionBuilder = BillsCompanion Function({
  Value<String> id,
  Value<String> billNo,
  Value<String> counterId,
  Value<String> cashierId,
  Value<String?> shiftId,
  Value<String?> customerName,
  Value<String?> customerPhone,
  Value<int> totalPaise,
  Value<int> changePaise,
  Value<DateTime> billedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$BillsTableReferences
    extends BaseReferences<_$AppDatabase, $BillsTable, BillRow> {
  $$BillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CountersTable _counterIdTable(_$AppDatabase db) =>
      db.counters.createAlias('bills__counter_id__counters__id');

  $$CountersTableProcessedTableManager get counterId {
    final $_column = $_itemColumn<String>('counter_id')!;

    final manager = $$CountersTableTableManager(
      $_db,
      $_db.counters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTable _cashierIdTable(_$AppDatabase db) =>
      db.users.createAlias('bills__cashier_id__users__id');

  $$UsersTableProcessedTableManager get cashierId {
    final $_column = $_itemColumn<String>('cashier_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) =>
      db.shifts.createAlias('bills__shift_id__shifts__id');

  $$ShiftsTableProcessedTableManager? get shiftId {
    final $_column = $_itemColumn<String>('shift_id');
    if ($_column == null) return null;
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DuesLedgerTable, List<DuesLedgerRow>>
  _duesLedgerRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.duesLedger,
    aliasName: 'bills__id__dues_ledger__bill_id',
  );

  $$DuesLedgerTableProcessedTableManager get duesLedgerRefs {
    final manager = $$DuesLedgerTableTableManager(
      $_db,
      $_db.duesLedger,
    ).filter((f) => f.billId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_duesLedgerRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillLinesTable, List<BillLineRow>>
  _billLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.billLines,
    aliasName: 'bills__id__bill_lines__bill_id',
  );

  $$BillLinesTableProcessedTableManager get billLinesRefs {
    final manager = $$BillLinesTableTableManager(
      $_db,
      $_db.billLines,
    ).filter((f) => f.billId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillPaymentsTable, List<BillPaymentRow>>
  _billPaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.billPayments,
    aliasName: 'bills__id__bill_payments__bill_id',
  );

  $$BillPaymentsTableProcessedTableManager get billPaymentsRefs {
    final manager = $$BillPaymentsTableTableManager(
      $_db,
      $_db.billPayments,
    ).filter((f) => f.billId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billPaymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CreditNoteUsesTable, List<CreditNoteUseRow>>
  _creditNoteUsesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.creditNoteUses,
    aliasName: 'bills__id__credit_note_uses__bill_id',
  );

  $$CreditNoteUsesTableProcessedTableManager get creditNoteUsesRefs {
    final manager = $$CreditNoteUsesTableTableManager(
      $_db,
      $_db.creditNoteUses,
    ).filter((f) => f.billId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_creditNoteUsesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BillsTableFilterComposer extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billNo => $composableBuilder(
    column: $table.billNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changePaise => $composableBuilder(
    column: $table.changePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get billedAt => $composableBuilder(
    column: $table.billedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CountersTableFilterComposer get counterId {
    final $$CountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableFilterComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableFilterComposer get cashierId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> duesLedgerRefs(
    Expression<bool> Function($$DuesLedgerTableFilterComposer f) f,
  ) {
    final $$DuesLedgerTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesLedger,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesLedgerTableFilterComposer(
            $db: $db,
            $table: $db.duesLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billLinesRefs(
    Expression<bool> Function($$BillLinesTableFilterComposer f) f,
  ) {
    final $$BillLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billLines,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillLinesTableFilterComposer(
            $db: $db,
            $table: $db.billLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billPaymentsRefs(
    Expression<bool> Function($$BillPaymentsTableFilterComposer f) f,
  ) {
    final $$BillPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billPayments,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.billPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> creditNoteUsesRefs(
    Expression<bool> Function($$CreditNoteUsesTableFilterComposer f) f,
  ) {
    final $$CreditNoteUsesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditNoteUses,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNoteUsesTableFilterComposer(
            $db: $db,
            $table: $db.creditNoteUses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billNo => $composableBuilder(
    column: $table.billNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changePaise => $composableBuilder(
    column: $table.changePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get billedAt => $composableBuilder(
    column: $table.billedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CountersTableOrderingComposer get counterId {
    final $$CountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableOrderingComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableOrderingComposer get cashierId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get billNo =>
      $composableBuilder(column: $table.billNo, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get changePaise => $composableBuilder(
    column: $table.changePaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get billedAt =>
      $composableBuilder(column: $table.billedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CountersTableAnnotationComposer get counterId {
    final $$CountersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableAnnotationComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableAnnotationComposer get cashierId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> duesLedgerRefs<T extends Object>(
    Expression<T> Function($$DuesLedgerTableAnnotationComposer a) f,
  ) {
    final $$DuesLedgerTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesLedger,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesLedgerTableAnnotationComposer(
            $db: $db,
            $table: $db.duesLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billLinesRefs<T extends Object>(
    Expression<T> Function($$BillLinesTableAnnotationComposer a) f,
  ) {
    final $$BillLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billLines,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.billLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billPaymentsRefs<T extends Object>(
    Expression<T> Function($$BillPaymentsTableAnnotationComposer a) f,
  ) {
    final $$BillPaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billPayments,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillPaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.billPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> creditNoteUsesRefs<T extends Object>(
    Expression<T> Function($$CreditNoteUsesTableAnnotationComposer a) f,
  ) {
    final $$CreditNoteUsesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditNoteUses,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNoteUsesTableAnnotationComposer(
            $db: $db,
            $table: $db.creditNoteUses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillsTable,
          BillRow,
          $$BillsTableFilterComposer,
          $$BillsTableOrderingComposer,
          $$BillsTableAnnotationComposer,
          $$BillsTableCreateCompanionBuilder,
          $$BillsTableUpdateCompanionBuilder,
          (BillRow, $$BillsTableReferences),
          BillRow,
          PrefetchHooks Function({
            bool counterId,
            bool cashierId,
            bool shiftId,
            bool duesLedgerRefs,
            bool billLinesRefs,
            bool billPaymentsRefs,
            bool creditNoteUsesRefs,
          })
        > {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> billNo = const Value.absent(),
                Value<String> counterId = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                Value<int> totalPaise = const Value.absent(),
                Value<int> changePaise = const Value.absent(),
                Value<DateTime> billedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion(
                id: id,
                billNo: billNo,
                counterId: counterId,
                cashierId: cashierId,
                shiftId: shiftId,
                customerName: customerName,
                customerPhone: customerPhone,
                totalPaise: totalPaise,
                changePaise: changePaise,
                billedAt: billedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String billNo,
                required String counterId,
                required String cashierId,
                Value<String?> shiftId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                required int totalPaise,
                required int changePaise,
                required DateTime billedAt,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion.insert(
                id: id,
                billNo: billNo,
                counterId: counterId,
                cashierId: cashierId,
                shiftId: shiftId,
                customerName: customerName,
                customerPhone: customerPhone,
                totalPaise: totalPaise,
                changePaise: changePaise,
                billedAt: billedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillsTable, BillRow>(table),
                  $$BillsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                counterId = false,
                cashierId = false,
                shiftId = false,
                duesLedgerRefs = false,
                billLinesRefs = false,
                billPaymentsRefs = false,
                creditNoteUsesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (duesLedgerRefs) db.duesLedger,
                    if (billLinesRefs) db.billLines,
                    if (billPaymentsRefs) db.billPayments,
                    if (creditNoteUsesRefs) db.creditNoteUses,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (counterId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.counterId,
                            referencedTable: $$BillsTableReferences
                                ._counterIdTable(db),
                            referencedColumn: $$BillsTableReferences
                                ._counterIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (cashierId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cashierId,
                            referencedTable: $$BillsTableReferences
                                ._cashierIdTable(db),
                            referencedColumn: $$BillsTableReferences
                                ._cashierIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (shiftId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.shiftId,
                            referencedTable: $$BillsTableReferences
                                ._shiftIdTable(db),
                            referencedColumn: $$BillsTableReferences
                                ._shiftIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (duesLedgerRefs)
                        await $_getPrefetchedDataByColumns<
                          BillRow,
                          $BillsTable,
                          DuesLedgerRow,
                          $DuesLedgerTable
                        >(
                          currentTable: table,
                          referencedTable: $$BillsTableReferences
                              ._duesLedgerRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BillsTableReferences(
                                db,
                                table,
                                p0,
                              ).duesLedgerRefs,
                          currentColumn: 'id',
                          referencedColumn: 'bill_id',
                          typedResults: items,
                        ),
                      if (billLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          BillRow,
                          $BillsTable,
                          BillLineRow,
                          $BillLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$BillsTableReferences
                              ._billLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BillsTableReferences(
                                db,
                                table,
                                p0,
                              ).billLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'bill_id',
                          typedResults: items,
                        ),
                      if (billPaymentsRefs)
                        await $_getPrefetchedDataByColumns<
                          BillRow,
                          $BillsTable,
                          BillPaymentRow,
                          $BillPaymentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$BillsTableReferences
                              ._billPaymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BillsTableReferences(
                                db,
                                table,
                                p0,
                              ).billPaymentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'bill_id',
                          typedResults: items,
                        ),
                      if (creditNoteUsesRefs)
                        await $_getPrefetchedDataByColumns<
                          BillRow,
                          $BillsTable,
                          CreditNoteUseRow,
                          $CreditNoteUsesTable
                        >(
                          currentTable: table,
                          referencedTable: $$BillsTableReferences
                              ._creditNoteUsesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BillsTableReferences(
                                db,
                                table,
                                p0,
                              ).creditNoteUsesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'bill_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillsTable,
      BillRow,
      $$BillsTableFilterComposer,
      $$BillsTableOrderingComposer,
      $$BillsTableAnnotationComposer,
      $$BillsTableCreateCompanionBuilder,
      $$BillsTableUpdateCompanionBuilder,
      (BillRow, $$BillsTableReferences),
      BillRow,
      PrefetchHooks Function({
        bool counterId,
        bool cashierId,
        bool shiftId,
        bool duesLedgerRefs,
        bool billLinesRefs,
        bool billPaymentsRefs,
        bool creditNoteUsesRefs,
      })
    >;
typedef $$CreditNotesTableCreateCompanionBuilder =
    CreditNotesCompanion Function({
      required String id,
      required String code,
      required String counterId,
      required int serial,
      required int amountPaise,
      required DateTime issuedAt,
      required String issuedBy,
      Value<int> rowid,
    });
typedef $$CreditNotesTableUpdateCompanionBuilder =
    CreditNotesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> counterId,
      Value<int> serial,
      Value<int> amountPaise,
      Value<DateTime> issuedAt,
      Value<String> issuedBy,
      Value<int> rowid,
    });

final class $$CreditNotesTableReferences
    extends BaseReferences<_$AppDatabase, $CreditNotesTable, CreditNoteRow> {
  $$CreditNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CountersTable _counterIdTable(_$AppDatabase db) =>
      db.counters.createAlias('credit_notes__counter_id__counters__id');

  $$CountersTableProcessedTableManager get counterId {
    final $_column = $_itemColumn<String>('counter_id')!;

    final manager = $$CountersTableTableManager(
      $_db,
      $_db.counters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTable _issuedByTable(_$AppDatabase db) =>
      db.users.createAlias('credit_notes__issued_by__users__id');

  $$UsersTableProcessedTableManager get issuedBy {
    final $_column = $_itemColumn<String>('issued_by')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_issuedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReturnsTable, List<ReturnRow>> _returnsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.returns,
    aliasName: 'credit_notes__id__returns__credit_note_id',
  );

  $$ReturnsTableProcessedTableManager get returnsRefs {
    final manager = $$ReturnsTableTableManager(
      $_db,
      $_db.returns,
    ).filter((f) => f.creditNoteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_returnsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CreditNoteUsesTable, List<CreditNoteUseRow>>
  _creditNoteUsesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.creditNoteUses,
    aliasName: 'credit_notes__id__credit_note_uses__credit_note_id',
  );

  $$CreditNoteUsesTableProcessedTableManager get creditNoteUsesRefs {
    final manager = $$CreditNoteUsesTableTableManager(
      $_db,
      $_db.creditNoteUses,
    ).filter((f) => f.creditNoteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_creditNoteUsesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CreditNotesTableFilterComposer
    extends Composer<_$AppDatabase, $CreditNotesTable> {
  $$CreditNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CountersTableFilterComposer get counterId {
    final $$CountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableFilterComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableFilterComposer get issuedBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.issuedBy,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> returnsRefs(
    Expression<bool> Function($$ReturnsTableFilterComposer f) f,
  ) {
    final $$ReturnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.creditNoteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableFilterComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> creditNoteUsesRefs(
    Expression<bool> Function($$CreditNoteUsesTableFilterComposer f) f,
  ) {
    final $$CreditNoteUsesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditNoteUses,
      getReferencedColumn: (t) => t.creditNoteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNoteUsesTableFilterComposer(
            $db: $db,
            $table: $db.creditNoteUses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreditNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditNotesTable> {
  $$CreditNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CountersTableOrderingComposer get counterId {
    final $$CountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableOrderingComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableOrderingComposer get issuedBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.issuedBy,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CreditNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditNotesTable> {
  $$CreditNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<int> get serial =>
      $composableBuilder(column: $table.serial, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  $$CountersTableAnnotationComposer get counterId {
    final $$CountersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableAnnotationComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableAnnotationComposer get issuedBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.issuedBy,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> returnsRefs<T extends Object>(
    Expression<T> Function($$ReturnsTableAnnotationComposer a) f,
  ) {
    final $$ReturnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.creditNoteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableAnnotationComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> creditNoteUsesRefs<T extends Object>(
    Expression<T> Function($$CreditNoteUsesTableAnnotationComposer a) f,
  ) {
    final $$CreditNoteUsesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditNoteUses,
      getReferencedColumn: (t) => t.creditNoteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNoteUsesTableAnnotationComposer(
            $db: $db,
            $table: $db.creditNoteUses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreditNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditNotesTable,
          CreditNoteRow,
          $$CreditNotesTableFilterComposer,
          $$CreditNotesTableOrderingComposer,
          $$CreditNotesTableAnnotationComposer,
          $$CreditNotesTableCreateCompanionBuilder,
          $$CreditNotesTableUpdateCompanionBuilder,
          (CreditNoteRow, $$CreditNotesTableReferences),
          CreditNoteRow,
          PrefetchHooks Function({
            bool counterId,
            bool issuedBy,
            bool returnsRefs,
            bool creditNoteUsesRefs,
          })
        > {
  $$CreditNotesTableTableManager(_$AppDatabase db, $CreditNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> counterId = const Value.absent(),
                Value<int> serial = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<String> issuedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditNotesCompanion(
                id: id,
                code: code,
                counterId: counterId,
                serial: serial,
                amountPaise: amountPaise,
                issuedAt: issuedAt,
                issuedBy: issuedBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String counterId,
                required int serial,
                required int amountPaise,
                required DateTime issuedAt,
                required String issuedBy,
                Value<int> rowid = const Value.absent(),
              }) => CreditNotesCompanion.insert(
                id: id,
                code: code,
                counterId: counterId,
                serial: serial,
                amountPaise: amountPaise,
                issuedAt: issuedAt,
                issuedBy: issuedBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CreditNotesTable, CreditNoteRow>(table),
                  $$CreditNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                counterId = false,
                issuedBy = false,
                returnsRefs = false,
                creditNoteUsesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (returnsRefs) db.returns,
                    if (creditNoteUsesRefs) db.creditNoteUses,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (counterId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.counterId,
                            referencedTable: $$CreditNotesTableReferences
                                ._counterIdTable(db),
                            referencedColumn: $$CreditNotesTableReferences
                                ._counterIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (issuedBy) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.issuedBy,
                            referencedTable: $$CreditNotesTableReferences
                                ._issuedByTable(db),
                            referencedColumn: $$CreditNotesTableReferences
                                ._issuedByTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (returnsRefs)
                        await $_getPrefetchedDataByColumns<
                          CreditNoteRow,
                          $CreditNotesTable,
                          ReturnRow,
                          $ReturnsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CreditNotesTableReferences
                              ._returnsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreditNotesTableReferences(
                                db,
                                table,
                                p0,
                              ).returnsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'credit_note_id',
                          typedResults: items,
                        ),
                      if (creditNoteUsesRefs)
                        await $_getPrefetchedDataByColumns<
                          CreditNoteRow,
                          $CreditNotesTable,
                          CreditNoteUseRow,
                          $CreditNoteUsesTable
                        >(
                          currentTable: table,
                          referencedTable: $$CreditNotesTableReferences
                              ._creditNoteUsesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreditNotesTableReferences(
                                db,
                                table,
                                p0,
                              ).creditNoteUsesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'credit_note_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CreditNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditNotesTable,
      CreditNoteRow,
      $$CreditNotesTableFilterComposer,
      $$CreditNotesTableOrderingComposer,
      $$CreditNotesTableAnnotationComposer,
      $$CreditNotesTableCreateCompanionBuilder,
      $$CreditNotesTableUpdateCompanionBuilder,
      (CreditNoteRow, $$CreditNotesTableReferences),
      CreditNoteRow,
      PrefetchHooks Function({
        bool counterId,
        bool issuedBy,
        bool returnsRefs,
        bool creditNoteUsesRefs,
      })
    >;
typedef $$ReturnsTableCreateCompanionBuilder = ReturnsCompanion Function({
  required String id,
  required String cashierId,
  Value<String?> shiftId,
  Value<String?> approvedBy,
  required String refundMode,
  Value<String?> creditNoteId,
  required int totalPaise,
  required DateTime returnedAt,
  Value<int> rowid,
});
typedef $$ReturnsTableUpdateCompanionBuilder = ReturnsCompanion Function({
  Value<String> id,
  Value<String> cashierId,
  Value<String?> shiftId,
  Value<String?> approvedBy,
  Value<String> refundMode,
  Value<String?> creditNoteId,
  Value<int> totalPaise,
  Value<DateTime> returnedAt,
  Value<int> rowid,
});

final class $$ReturnsTableReferences
    extends BaseReferences<_$AppDatabase, $ReturnsTable, ReturnRow> {
  $$ReturnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _cashierIdTable(_$AppDatabase db) =>
      db.users.createAlias('returns__cashier_id__users__id');

  $$UsersTableProcessedTableManager get cashierId {
    final $_column = $_itemColumn<String>('cashier_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) =>
      db.shifts.createAlias('returns__shift_id__shifts__id');

  $$ShiftsTableProcessedTableManager? get shiftId {
    final $_column = $_itemColumn<String>('shift_id');
    if ($_column == null) return null;
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTable _approvedByTable(_$AppDatabase db) =>
      db.users.createAlias('returns__approved_by__users__id');

  $$UsersTableProcessedTableManager? get approvedBy {
    final $_column = $_itemColumn<String>('approved_by');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_approvedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CreditNotesTable _creditNoteIdTable(_$AppDatabase db) =>
      db.creditNotes.createAlias('returns__credit_note_id__credit_notes__id');

  $$CreditNotesTableProcessedTableManager? get creditNoteId {
    final $_column = $_itemColumn<String>('credit_note_id');
    if ($_column == null) return null;
    final manager = $$CreditNotesTableTableManager(
      $_db,
      $_db.creditNotes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creditNoteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DuesLedgerTable, List<DuesLedgerRow>>
  _duesLedgerRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.duesLedger,
    aliasName: 'returns__id__dues_ledger__return_id',
  );

  $$DuesLedgerTableProcessedTableManager get duesLedgerRefs {
    final manager = $$DuesLedgerTableTableManager(
      $_db,
      $_db.duesLedger,
    ).filter((f) => f.returnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_duesLedgerRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReturnLinesTable, List<ReturnLineRow>>
  _returnLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.returnLines,
    aliasName: 'returns__id__return_lines__return_id',
  );

  $$ReturnLinesTableProcessedTableManager get returnLinesRefs {
    final manager = $$ReturnLinesTableTableManager(
      $_db,
      $_db.returnLines,
    ).filter((f) => f.returnId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_returnLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReturnsTableFilterComposer
    extends Composer<_$AppDatabase, $ReturnsTable> {
  $$ReturnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refundMode => $composableBuilder(
    column: $table.refundMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get cashierId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableFilterComposer get approvedBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.approvedBy,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CreditNotesTableFilterComposer get creditNoteId {
    final $$CreditNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditNoteId,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableFilterComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> duesLedgerRefs(
    Expression<bool> Function($$DuesLedgerTableFilterComposer f) f,
  ) {
    final $$DuesLedgerTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesLedger,
      getReferencedColumn: (t) => t.returnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesLedgerTableFilterComposer(
            $db: $db,
            $table: $db.duesLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> returnLinesRefs(
    Expression<bool> Function($$ReturnLinesTableFilterComposer f) f,
  ) {
    final $$ReturnLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returnLines,
      getReferencedColumn: (t) => t.returnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnLinesTableFilterComposer(
            $db: $db,
            $table: $db.returnLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReturnsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReturnsTable> {
  $$ReturnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refundMode => $composableBuilder(
    column: $table.refundMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get cashierId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableOrderingComposer get approvedBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.approvedBy,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CreditNotesTableOrderingComposer get creditNoteId {
    final $$CreditNotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditNoteId,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableOrderingComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReturnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReturnsTable> {
  $$ReturnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get refundMode => $composableBuilder(
    column: $table.refundMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPaise => $composableBuilder(
    column: $table.totalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get cashierId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashierId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableAnnotationComposer get approvedBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.approvedBy,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CreditNotesTableAnnotationComposer get creditNoteId {
    final $$CreditNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditNoteId,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> duesLedgerRefs<T extends Object>(
    Expression<T> Function($$DuesLedgerTableAnnotationComposer a) f,
  ) {
    final $$DuesLedgerTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duesLedger,
      getReferencedColumn: (t) => t.returnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesLedgerTableAnnotationComposer(
            $db: $db,
            $table: $db.duesLedger,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> returnLinesRefs<T extends Object>(
    Expression<T> Function($$ReturnLinesTableAnnotationComposer a) f,
  ) {
    final $$ReturnLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returnLines,
      getReferencedColumn: (t) => t.returnId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.returnLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReturnsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReturnsTable,
          ReturnRow,
          $$ReturnsTableFilterComposer,
          $$ReturnsTableOrderingComposer,
          $$ReturnsTableAnnotationComposer,
          $$ReturnsTableCreateCompanionBuilder,
          $$ReturnsTableUpdateCompanionBuilder,
          (ReturnRow, $$ReturnsTableReferences),
          ReturnRow,
          PrefetchHooks Function({
            bool cashierId,
            bool shiftId,
            bool approvedBy,
            bool creditNoteId,
            bool duesLedgerRefs,
            bool returnLinesRefs,
          })
        > {
  $$ReturnsTableTableManager(_$AppDatabase db, $ReturnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReturnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReturnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReturnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<String> refundMode = const Value.absent(),
                Value<String?> creditNoteId = const Value.absent(),
                Value<int> totalPaise = const Value.absent(),
                Value<DateTime> returnedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReturnsCompanion(
                id: id,
                cashierId: cashierId,
                shiftId: shiftId,
                approvedBy: approvedBy,
                refundMode: refundMode,
                creditNoteId: creditNoteId,
                totalPaise: totalPaise,
                returnedAt: returnedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cashierId,
                Value<String?> shiftId = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                required String refundMode,
                Value<String?> creditNoteId = const Value.absent(),
                required int totalPaise,
                required DateTime returnedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReturnsCompanion.insert(
                id: id,
                cashierId: cashierId,
                shiftId: shiftId,
                approvedBy: approvedBy,
                refundMode: refundMode,
                creditNoteId: creditNoteId,
                totalPaise: totalPaise,
                returnedAt: returnedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReturnsTable, ReturnRow>(table),
                  $$ReturnsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cashierId = false,
                shiftId = false,
                approvedBy = false,
                creditNoteId = false,
                duesLedgerRefs = false,
                returnLinesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (duesLedgerRefs) db.duesLedger,
                    if (returnLinesRefs) db.returnLines,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cashierId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cashierId,
                            referencedTable: $$ReturnsTableReferences
                                ._cashierIdTable(db),
                            referencedColumn: $$ReturnsTableReferences
                                ._cashierIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (shiftId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.shiftId,
                            referencedTable: $$ReturnsTableReferences
                                ._shiftIdTable(db),
                            referencedColumn: $$ReturnsTableReferences
                                ._shiftIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (approvedBy) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.approvedBy,
                            referencedTable: $$ReturnsTableReferences
                                ._approvedByTable(db),
                            referencedColumn: $$ReturnsTableReferences
                                ._approvedByTable(db)
                                .id,
                          ) as T;
                        }
                        if (creditNoteId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.creditNoteId,
                            referencedTable: $$ReturnsTableReferences
                                ._creditNoteIdTable(db),
                            referencedColumn: $$ReturnsTableReferences
                                ._creditNoteIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (duesLedgerRefs)
                        await $_getPrefetchedDataByColumns<
                          ReturnRow,
                          $ReturnsTable,
                          DuesLedgerRow,
                          $DuesLedgerTable
                        >(
                          currentTable: table,
                          referencedTable: $$ReturnsTableReferences
                              ._duesLedgerRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReturnsTableReferences(
                                db,
                                table,
                                p0,
                              ).duesLedgerRefs,
                          currentColumn: 'id',
                          referencedColumn: 'return_id',
                          typedResults: items,
                        ),
                      if (returnLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          ReturnRow,
                          $ReturnsTable,
                          ReturnLineRow,
                          $ReturnLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ReturnsTableReferences
                              ._returnLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReturnsTableReferences(
                                db,
                                table,
                                p0,
                              ).returnLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'return_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ReturnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReturnsTable,
      ReturnRow,
      $$ReturnsTableFilterComposer,
      $$ReturnsTableOrderingComposer,
      $$ReturnsTableAnnotationComposer,
      $$ReturnsTableCreateCompanionBuilder,
      $$ReturnsTableUpdateCompanionBuilder,
      (ReturnRow, $$ReturnsTableReferences),
      ReturnRow,
      PrefetchHooks Function({
        bool cashierId,
        bool shiftId,
        bool approvedBy,
        bool creditNoteId,
        bool duesLedgerRefs,
        bool returnLinesRefs,
      })
    >;
typedef $$DuesLedgerTableCreateCompanionBuilder = DuesLedgerCompanion Function({
  required String id,
  required String customerId,
  required String billId,
  required String kind,
  required int amountPaise,
  Value<String?> receiptId,
  Value<String?> returnId,
  required DateTime at,
  required String actorId,
  Value<String?> approvedBy,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$DuesLedgerTableUpdateCompanionBuilder = DuesLedgerCompanion Function({
  Value<String> id,
  Value<String> customerId,
  Value<String> billId,
  Value<String> kind,
  Value<int> amountPaise,
  Value<String?> receiptId,
  Value<String?> returnId,
  Value<DateTime> at,
  Value<String> actorId,
  Value<String?> approvedBy,
  Value<String?> note,
  Value<int> rowid,
});

final class $$DuesLedgerTableReferences
    extends BaseReferences<_$AppDatabase, $DuesLedgerTable, DuesLedgerRow> {
  $$DuesLedgerTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomersTable _customerIdTable(_$AppDatabase db) =>
      db.customers.createAlias('dues_ledger__customer_id__customers__id');

  $$CustomersTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<String>('customer_id')!;

    final manager = $$CustomersTableTableManager(
      $_db,
      $_db.customers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BillsTable _billIdTable(_$AppDatabase db) =>
      db.bills.createAlias('dues_ledger__bill_id__bills__id');

  $$BillsTableProcessedTableManager get billId {
    final $_column = $_itemColumn<String>('bill_id')!;

    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DuesReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.duesReceipts.createAlias('dues_ledger__receipt_id__dues_receipts__id');

  $$DuesReceiptsTableProcessedTableManager? get receiptId {
    final $_column = $_itemColumn<String>('receipt_id');
    if ($_column == null) return null;
    final manager = $$DuesReceiptsTableTableManager(
      $_db,
      $_db.duesReceipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ReturnsTable _returnIdTable(_$AppDatabase db) =>
      db.returns.createAlias('dues_ledger__return_id__returns__id');

  $$ReturnsTableProcessedTableManager? get returnId {
    final $_column = $_itemColumn<String>('return_id');
    if ($_column == null) return null;
    final manager = $$ReturnsTableTableManager(
      $_db,
      $_db.returns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_returnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DuesLedgerTableFilterComposer
    extends Composer<_$AppDatabase, $DuesLedgerTable> {
  $$DuesLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableFilterComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DuesReceiptsTableFilterComposer get receiptId {
    final $$DuesReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.duesReceipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.duesReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ReturnsTableFilterComposer get returnId {
    final $$ReturnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.returnId,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableFilterComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuesLedgerTableOrderingComposer
    extends Composer<_$AppDatabase, $DuesLedgerTable> {
  $$DuesLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableOrderingComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableOrderingComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DuesReceiptsTableOrderingComposer get receiptId {
    final $$DuesReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.duesReceipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.duesReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ReturnsTableOrderingComposer get returnId {
    final $$ReturnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.returnId,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableOrderingComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuesLedgerTableAnnotationComposer
    extends Composer<_$AppDatabase, $DuesLedgerTable> {
  $$DuesLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableAnnotationComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableAnnotationComposer get billId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DuesReceiptsTableAnnotationComposer get receiptId {
    final $$DuesReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.duesReceipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuesReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.duesReceipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ReturnsTableAnnotationComposer get returnId {
    final $$ReturnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.returnId,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableAnnotationComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuesLedgerTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DuesLedgerTable,
          DuesLedgerRow,
          $$DuesLedgerTableFilterComposer,
          $$DuesLedgerTableOrderingComposer,
          $$DuesLedgerTableAnnotationComposer,
          $$DuesLedgerTableCreateCompanionBuilder,
          $$DuesLedgerTableUpdateCompanionBuilder,
          (DuesLedgerRow, $$DuesLedgerTableReferences),
          DuesLedgerRow,
          PrefetchHooks Function({
            bool customerId,
            bool billId,
            bool receiptId,
            bool returnId,
          })
        > {
  $$DuesLedgerTableTableManager(_$AppDatabase db, $DuesLedgerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DuesLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DuesLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DuesLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String?> receiptId = const Value.absent(),
                Value<String?> returnId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> actorId = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DuesLedgerCompanion(
                id: id,
                customerId: customerId,
                billId: billId,
                kind: kind,
                amountPaise: amountPaise,
                receiptId: receiptId,
                returnId: returnId,
                at: at,
                actorId: actorId,
                approvedBy: approvedBy,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required String billId,
                required String kind,
                required int amountPaise,
                Value<String?> receiptId = const Value.absent(),
                Value<String?> returnId = const Value.absent(),
                required DateTime at,
                required String actorId,
                Value<String?> approvedBy = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DuesLedgerCompanion.insert(
                id: id,
                customerId: customerId,
                billId: billId,
                kind: kind,
                amountPaise: amountPaise,
                receiptId: receiptId,
                returnId: returnId,
                at: at,
                actorId: actorId,
                approvedBy: approvedBy,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DuesLedgerTable, DuesLedgerRow>(table),
                  $$DuesLedgerTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customerId = false,
                billId = false,
                receiptId = false,
                returnId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (customerId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.customerId,
                            referencedTable: $$DuesLedgerTableReferences
                                ._customerIdTable(db),
                            referencedColumn: $$DuesLedgerTableReferences
                                ._customerIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (billId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.billId,
                            referencedTable: $$DuesLedgerTableReferences
                                ._billIdTable(db),
                            referencedColumn: $$DuesLedgerTableReferences
                                ._billIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (receiptId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.receiptId,
                            referencedTable: $$DuesLedgerTableReferences
                                ._receiptIdTable(db),
                            referencedColumn: $$DuesLedgerTableReferences
                                ._receiptIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (returnId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.returnId,
                            referencedTable: $$DuesLedgerTableReferences
                                ._returnIdTable(db),
                            referencedColumn: $$DuesLedgerTableReferences
                                ._returnIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$DuesLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DuesLedgerTable,
      DuesLedgerRow,
      $$DuesLedgerTableFilterComposer,
      $$DuesLedgerTableOrderingComposer,
      $$DuesLedgerTableAnnotationComposer,
      $$DuesLedgerTableCreateCompanionBuilder,
      $$DuesLedgerTableUpdateCompanionBuilder,
      (DuesLedgerRow, $$DuesLedgerTableReferences),
      DuesLedgerRow,
      PrefetchHooks Function({
        bool customerId,
        bool billId,
        bool receiptId,
        bool returnId,
      })
    >;
typedef $$VariantsTableCreateCompanionBuilder = VariantsCompanion Function({
  required String id,
  required String productId,
  required String size,
  required String color,
  required int mrpPaise,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$VariantsTableUpdateCompanionBuilder = VariantsCompanion Function({
  Value<String> id,
  Value<String> productId,
  Value<String> size,
  Value<String> color,
  Value<int> mrpPaise,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$VariantsTableReferences
    extends BaseReferences<_$AppDatabase, $VariantsTable, VariantRow> {
  $$VariantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('variants__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BatchLinesTable, List<BatchLineRow>>
  _batchLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.batchLines,
    aliasName: 'variants__id__batch_lines__variant_id',
  );

  $$BatchLinesTableProcessedTableManager get batchLinesRefs {
    final manager = $$BatchLinesTableTableManager(
      $_db,
      $_db.batchLines,
    ).filter((f) => f.variantId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_batchLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArticlesTable, List<ArticleRow>>
  _articlesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.articles,
    aliasName: 'variants__id__articles__variant_id',
  );

  $$ArticlesTableProcessedTableManager get articlesRefs {
    final manager = $$ArticlesTableTableManager(
      $_db,
      $_db.articles,
    ).filter((f) => f.variantId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_articlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VariantsTableFilterComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mrpPaise => $composableBuilder(
    column: $table.mrpPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> batchLinesRefs(
    Expression<bool> Function($$BatchLinesTableFilterComposer f) f,
  ) {
    final $$BatchLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.batchLines,
      getReferencedColumn: (t) => t.variantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchLinesTableFilterComposer(
            $db: $db,
            $table: $db.batchLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> articlesRefs(
    Expression<bool> Function($$ArticlesTableFilterComposer f) f,
  ) {
    final $$ArticlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.variantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableFilterComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mrpPaise => $composableBuilder(
    column: $table.mrpPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get mrpPaise =>
      $composableBuilder(column: $table.mrpPaise, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> batchLinesRefs<T extends Object>(
    Expression<T> Function($$BatchLinesTableAnnotationComposer a) f,
  ) {
    final $$BatchLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.batchLines,
      getReferencedColumn: (t) => t.variantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.batchLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> articlesRefs<T extends Object>(
    Expression<T> Function($$ArticlesTableAnnotationComposer a) f,
  ) {
    final $$ArticlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.variantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableAnnotationComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VariantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VariantsTable,
          VariantRow,
          $$VariantsTableFilterComposer,
          $$VariantsTableOrderingComposer,
          $$VariantsTableAnnotationComposer,
          $$VariantsTableCreateCompanionBuilder,
          $$VariantsTableUpdateCompanionBuilder,
          (VariantRow, $$VariantsTableReferences),
          VariantRow,
          PrefetchHooks Function({
            bool productId,
            bool batchLinesRefs,
            bool articlesRefs,
          })
        > {
  $$VariantsTableTableManager(_$AppDatabase db, $VariantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> size = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<int> mrpPaise = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VariantsCompanion(
                id: id,
                productId: productId,
                size: size,
                color: color,
                mrpPaise: mrpPaise,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String size,
                required String color,
                required int mrpPaise,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VariantsCompanion.insert(
                id: id,
                productId: productId,
                size: size,
                color: color,
                mrpPaise: mrpPaise,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VariantsTable, VariantRow>(table),
                  $$VariantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                productId = false,
                batchLinesRefs = false,
                articlesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (batchLinesRefs) db.batchLines,
                    if (articlesRefs) db.articles,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (productId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable: $$VariantsTableReferences
                                ._productIdTable(db),
                            referencedColumn: $$VariantsTableReferences
                                ._productIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (batchLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          VariantRow,
                          $VariantsTable,
                          BatchLineRow,
                          $BatchLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$VariantsTableReferences
                              ._batchLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VariantsTableReferences(
                                db,
                                table,
                                p0,
                              ).batchLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'variant_id',
                          typedResults: items,
                        ),
                      if (articlesRefs)
                        await $_getPrefetchedDataByColumns<
                          VariantRow,
                          $VariantsTable,
                          ArticleRow,
                          $ArticlesTable
                        >(
                          currentTable: table,
                          referencedTable: $$VariantsTableReferences
                              ._articlesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VariantsTableReferences(
                                db,
                                table,
                                p0,
                              ).articlesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'variant_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VariantsTable,
      VariantRow,
      $$VariantsTableFilterComposer,
      $$VariantsTableOrderingComposer,
      $$VariantsTableAnnotationComposer,
      $$VariantsTableCreateCompanionBuilder,
      $$VariantsTableUpdateCompanionBuilder,
      (VariantRow, $$VariantsTableReferences),
      VariantRow,
      PrefetchHooks Function({
        bool productId,
        bool batchLinesRefs,
        bool articlesRefs,
      })
    >;
typedef $$BatchesTableCreateCompanionBuilder = BatchesCompanion Function({
  required String id,
  required String supplier,
  required int lot,
  required DateTime purchasedAt,
  Value<String?> createdBy,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BatchesTableUpdateCompanionBuilder = BatchesCompanion Function({
  Value<String> id,
  Value<String> supplier,
  Value<int> lot,
  Value<DateTime> purchasedAt,
  Value<String?> createdBy,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$BatchesTableReferences
    extends BaseReferences<_$AppDatabase, $BatchesTable, BatchRow> {
  $$BatchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BatchLinesTable, List<BatchLineRow>>
  _batchLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.batchLines,
    aliasName: 'batches__id__batch_lines__batch_id',
  );

  $$BatchLinesTableProcessedTableManager get batchLinesRefs {
    final manager = $$BatchLinesTableTableManager(
      $_db,
      $_db.batchLines,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_batchLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArticlesTable, List<ArticleRow>>
  _articlesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.articles,
    aliasName: 'batches__id__articles__batch_id',
  );

  $$ArticlesTableProcessedTableManager get articlesRefs {
    final manager = $$ArticlesTableTableManager(
      $_db,
      $_db.articles,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_articlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BatchesTableFilterComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lot => $composableBuilder(
    column: $table.lot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> batchLinesRefs(
    Expression<bool> Function($$BatchLinesTableFilterComposer f) f,
  ) {
    final $$BatchLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.batchLines,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchLinesTableFilterComposer(
            $db: $db,
            $table: $db.batchLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> articlesRefs(
    Expression<bool> Function($$ArticlesTableFilterComposer f) f,
  ) {
    final $$ArticlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableFilterComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lot => $composableBuilder(
    column: $table.lot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<int> get lot =>
      $composableBuilder(column: $table.lot, builder: (column) => column);

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> batchLinesRefs<T extends Object>(
    Expression<T> Function($$BatchLinesTableAnnotationComposer a) f,
  ) {
    final $$BatchLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.batchLines,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.batchLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> articlesRefs<T extends Object>(
    Expression<T> Function($$ArticlesTableAnnotationComposer a) f,
  ) {
    final $$ArticlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableAnnotationComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchesTable,
          BatchRow,
          $$BatchesTableFilterComposer,
          $$BatchesTableOrderingComposer,
          $$BatchesTableAnnotationComposer,
          $$BatchesTableCreateCompanionBuilder,
          $$BatchesTableUpdateCompanionBuilder,
          (BatchRow, $$BatchesTableReferences),
          BatchRow,
          PrefetchHooks Function({bool batchLinesRefs, bool articlesRefs})
        > {
  $$BatchesTableTableManager(_$AppDatabase db, $BatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> supplier = const Value.absent(),
                Value<int> lot = const Value.absent(),
                Value<DateTime> purchasedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion(
                id: id,
                supplier: supplier,
                lot: lot,
                purchasedAt: purchasedAt,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String supplier,
                required int lot,
                required DateTime purchasedAt,
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion.insert(
                id: id,
                supplier: supplier,
                lot: lot,
                purchasedAt: purchasedAt,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BatchesTable, BatchRow>(table),
                  $$BatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({batchLinesRefs = false, articlesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (batchLinesRefs) db.batchLines,
                    if (articlesRefs) db.articles,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (batchLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          BatchRow,
                          $BatchesTable,
                          BatchLineRow,
                          $BatchLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._batchLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).batchLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'batch_id',
                          typedResults: items,
                        ),
                      if (articlesRefs)
                        await $_getPrefetchedDataByColumns<
                          BatchRow,
                          $BatchesTable,
                          ArticleRow,
                          $ArticlesTable
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._articlesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).articlesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'batch_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchesTable,
      BatchRow,
      $$BatchesTableFilterComposer,
      $$BatchesTableOrderingComposer,
      $$BatchesTableAnnotationComposer,
      $$BatchesTableCreateCompanionBuilder,
      $$BatchesTableUpdateCompanionBuilder,
      (BatchRow, $$BatchesTableReferences),
      BatchRow,
      PrefetchHooks Function({bool batchLinesRefs, bool articlesRefs})
    >;
typedef $$BatchLinesTableCreateCompanionBuilder = BatchLinesCompanion Function({
  required String id,
  required String batchId,
  required String variantId,
  required int quantity,
  required int unitCostPaise,
  Value<int> rowid,
});
typedef $$BatchLinesTableUpdateCompanionBuilder = BatchLinesCompanion Function({
  Value<String> id,
  Value<String> batchId,
  Value<String> variantId,
  Value<int> quantity,
  Value<int> unitCostPaise,
  Value<int> rowid,
});

final class $$BatchLinesTableReferences
    extends BaseReferences<_$AppDatabase, $BatchLinesTable, BatchLineRow> {
  $$BatchLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias('batch_lines__batch_id__batches__id');

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VariantsTable _variantIdTable(_$AppDatabase db) =>
      db.variants.createAlias('batch_lines__variant_id__variants__id');

  $$VariantsTableProcessedTableManager get variantId {
    final $_column = $_itemColumn<String>('variant_id')!;

    final manager = $$VariantsTableTableManager(
      $_db,
      $_db.variants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_variantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BatchLinesTableFilterComposer
    extends Composer<_$AppDatabase, $BatchLinesTable> {
  $$BatchLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitCostPaise => $composableBuilder(
    column: $table.unitCostPaise,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VariantsTableFilterComposer get variantId {
    final $$VariantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.variantId,
      referencedTable: $db.variants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantsTableFilterComposer(
            $db: $db,
            $table: $db.variants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BatchLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchLinesTable> {
  $$BatchLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitCostPaise => $composableBuilder(
    column: $table.unitCostPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VariantsTableOrderingComposer get variantId {
    final $$VariantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.variantId,
      referencedTable: $db.variants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantsTableOrderingComposer(
            $db: $db,
            $table: $db.variants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BatchLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchLinesTable> {
  $$BatchLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unitCostPaise => $composableBuilder(
    column: $table.unitCostPaise,
    builder: (column) => column,
  );

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VariantsTableAnnotationComposer get variantId {
    final $$VariantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.variantId,
      referencedTable: $db.variants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantsTableAnnotationComposer(
            $db: $db,
            $table: $db.variants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BatchLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchLinesTable,
          BatchLineRow,
          $$BatchLinesTableFilterComposer,
          $$BatchLinesTableOrderingComposer,
          $$BatchLinesTableAnnotationComposer,
          $$BatchLinesTableCreateCompanionBuilder,
          $$BatchLinesTableUpdateCompanionBuilder,
          (BatchLineRow, $$BatchLinesTableReferences),
          BatchLineRow,
          PrefetchHooks Function({bool batchId, bool variantId})
        > {
  $$BatchLinesTableTableManager(_$AppDatabase db, $BatchLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> unitCostPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchLinesCompanion(
                id: id,
                batchId: batchId,
                variantId: variantId,
                quantity: quantity,
                unitCostPaise: unitCostPaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String batchId,
                required String variantId,
                required int quantity,
                required int unitCostPaise,
                Value<int> rowid = const Value.absent(),
              }) => BatchLinesCompanion.insert(
                id: id,
                batchId: batchId,
                variantId: variantId,
                quantity: quantity,
                unitCostPaise: unitCostPaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BatchLinesTable, BatchLineRow>(table),
                  $$BatchLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false, variantId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.batchId,
                        referencedTable: $$BatchLinesTableReferences
                            ._batchIdTable(db),
                        referencedColumn: $$BatchLinesTableReferences
                            ._batchIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (variantId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.variantId,
                        referencedTable: $$BatchLinesTableReferences
                            ._variantIdTable(db),
                        referencedColumn: $$BatchLinesTableReferences
                            ._variantIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BatchLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchLinesTable,
      BatchLineRow,
      $$BatchLinesTableFilterComposer,
      $$BatchLinesTableOrderingComposer,
      $$BatchLinesTableAnnotationComposer,
      $$BatchLinesTableCreateCompanionBuilder,
      $$BatchLinesTableUpdateCompanionBuilder,
      (BatchLineRow, $$BatchLinesTableReferences),
      BatchLineRow,
      PrefetchHooks Function({bool batchId, bool variantId})
    >;
typedef $$ArticlesTableCreateCompanionBuilder = ArticlesCompanion Function({
  required String id,
  required String barcodeValue,
  required String variantId,
  required String batchId,
  required int mrpPaise,
  required String status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ArticlesTableUpdateCompanionBuilder = ArticlesCompanion Function({
  Value<String> id,
  Value<String> barcodeValue,
  Value<String> variantId,
  Value<String> batchId,
  Value<int> mrpPaise,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ArticlesTableReferences
    extends BaseReferences<_$AppDatabase, $ArticlesTable, ArticleRow> {
  $$ArticlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VariantsTable _variantIdTable(_$AppDatabase db) =>
      db.variants.createAlias('articles__variant_id__variants__id');

  $$VariantsTableProcessedTableManager get variantId {
    final $_column = $_itemColumn<String>('variant_id')!;

    final manager = $$VariantsTableTableManager(
      $_db,
      $_db.variants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_variantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias('articles__batch_id__batches__id');

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BillLinesTable, List<BillLineRow>>
  _billLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.billLines,
    aliasName: 'articles__id__bill_lines__article_id',
  );

  $$BillLinesTableProcessedTableManager get billLinesRefs {
    final manager = $$BillLinesTableTableManager(
      $_db,
      $_db.billLines,
    ).filter((f) => f.articleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReturnLinesTable, List<ReturnLineRow>>
  _returnLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.returnLines,
    aliasName: 'articles__id__return_lines__article_id',
  );

  $$ReturnLinesTableProcessedTableManager get returnLinesRefs {
    final manager = $$ReturnLinesTableTableManager(
      $_db,
      $_db.returnLines,
    ).filter((f) => f.articleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_returnLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mrpPaise => $composableBuilder(
    column: $table.mrpPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VariantsTableFilterComposer get variantId {
    final $$VariantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.variantId,
      referencedTable: $db.variants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantsTableFilterComposer(
            $db: $db,
            $table: $db.variants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> billLinesRefs(
    Expression<bool> Function($$BillLinesTableFilterComposer f) f,
  ) {
    final $$BillLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billLines,
      getReferencedColumn: (t) => t.articleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillLinesTableFilterComposer(
            $db: $db,
            $table: $db.billLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> returnLinesRefs(
    Expression<bool> Function($$ReturnLinesTableFilterComposer f) f,
  ) {
    final $$ReturnLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returnLines,
      getReferencedColumn: (t) => t.articleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnLinesTableFilterComposer(
            $db: $db,
            $table: $db.returnLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mrpPaise => $composableBuilder(
    column: $table.mrpPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VariantsTableOrderingComposer get variantId {
    final $$VariantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.variantId,
      referencedTable: $db.variants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantsTableOrderingComposer(
            $db: $db,
            $table: $db.variants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mrpPaise =>
      $composableBuilder(column: $table.mrpPaise, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VariantsTableAnnotationComposer get variantId {
    final $$VariantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.variantId,
      referencedTable: $db.variants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantsTableAnnotationComposer(
            $db: $db,
            $table: $db.variants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> billLinesRefs<T extends Object>(
    Expression<T> Function($$BillLinesTableAnnotationComposer a) f,
  ) {
    final $$BillLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billLines,
      getReferencedColumn: (t) => t.articleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.billLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> returnLinesRefs<T extends Object>(
    Expression<T> Function($$ReturnLinesTableAnnotationComposer a) f,
  ) {
    final $$ReturnLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returnLines,
      getReferencedColumn: (t) => t.articleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.returnLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticlesTable,
          ArticleRow,
          $$ArticlesTableFilterComposer,
          $$ArticlesTableOrderingComposer,
          $$ArticlesTableAnnotationComposer,
          $$ArticlesTableCreateCompanionBuilder,
          $$ArticlesTableUpdateCompanionBuilder,
          (ArticleRow, $$ArticlesTableReferences),
          ArticleRow,
          PrefetchHooks Function({
            bool variantId,
            bool batchId,
            bool billLinesRefs,
            bool returnLinesRefs,
          })
        > {
  $$ArticlesTableTableManager(_$AppDatabase db, $ArticlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> barcodeValue = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<int> mrpPaise = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArticlesCompanion(
                id: id,
                barcodeValue: barcodeValue,
                variantId: variantId,
                batchId: batchId,
                mrpPaise: mrpPaise,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String barcodeValue,
                required String variantId,
                required String batchId,
                required int mrpPaise,
                required String status,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ArticlesCompanion.insert(
                id: id,
                barcodeValue: barcodeValue,
                variantId: variantId,
                batchId: batchId,
                mrpPaise: mrpPaise,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArticlesTable, ArticleRow>(table),
                  $$ArticlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                variantId = false,
                batchId = false,
                billLinesRefs = false,
                returnLinesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (billLinesRefs) db.billLines,
                    if (returnLinesRefs) db.returnLines,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (variantId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.variantId,
                            referencedTable: $$ArticlesTableReferences
                                ._variantIdTable(db),
                            referencedColumn: $$ArticlesTableReferences
                                ._variantIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (batchId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.batchId,
                            referencedTable: $$ArticlesTableReferences
                                ._batchIdTable(db),
                            referencedColumn: $$ArticlesTableReferences
                                ._batchIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (billLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          ArticleRow,
                          $ArticlesTable,
                          BillLineRow,
                          $BillLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ArticlesTableReferences
                              ._billLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArticlesTableReferences(
                                db,
                                table,
                                p0,
                              ).billLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'article_id',
                          typedResults: items,
                        ),
                      if (returnLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          ArticleRow,
                          $ArticlesTable,
                          ReturnLineRow,
                          $ReturnLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ArticlesTableReferences
                              ._returnLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ArticlesTableReferences(
                                db,
                                table,
                                p0,
                              ).returnLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'article_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticlesTable,
      ArticleRow,
      $$ArticlesTableFilterComposer,
      $$ArticlesTableOrderingComposer,
      $$ArticlesTableAnnotationComposer,
      $$ArticlesTableCreateCompanionBuilder,
      $$ArticlesTableUpdateCompanionBuilder,
      (ArticleRow, $$ArticlesTableReferences),
      ArticleRow,
      PrefetchHooks Function({
        bool variantId,
        bool batchId,
        bool billLinesRefs,
        bool returnLinesRefs,
      })
    >;
typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  required String id,
  required DateTime at,
  Value<String?> actor,
  required String action,
  required String entityType,
  required String entityId,
  required String details,
  Value<int> rowid,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<String> id,
  Value<DateTime> at,
  Value<String?> actor,
  Value<String> action,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> details,
  Value<int> rowid,
});

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogTable,
          AuditRow,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (AuditRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditRow>),
          AuditRow,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> actor = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> details = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                at: at,
                actor: actor,
                action: action,
                entityType: entityType,
                entityId: entityId,
                details: details,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime at,
                Value<String?> actor = const Value.absent(),
                required String action,
                required String entityType,
                required String entityId,
                required String details,
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion.insert(
                id: id,
                at: at,
                actor: actor,
                action: action,
                entityType: entityType,
                entityId: entityId,
                details: details,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditLogTable, AuditRow>(table),
                  BaseReferences<_$AppDatabase, $AuditLogTable, AuditRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogTable,
      AuditRow,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (AuditRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditRow>),
      AuditRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String id,
  required DateTime createdAt,
  required String entityType,
  required String entityId,
  required String operation,
  required String payload,
  Value<DateTime?> sentAt,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payload,
  Value<DateTime?> sentAt,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                createdAt: createdAt,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payload: payload,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required String entityType,
                required String entityId,
                required String operation,
                required String payload,
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                createdAt: createdAt,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payload: payload,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxRow>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$BillLinesTableCreateCompanionBuilder = BillLinesCompanion Function({
  required String id,
  required String billId,
  required String articleId,
  required String barcodeValue,
  required String productName,
  required String size,
  required String color,
  required int mrpPaise,
  required int markdownPaise,
  required int discountPaise,
  required int finalPaise,
  Value<int> gstBp,
  Value<int> taxablePaise,
  Value<int> taxPaise,
  Value<int> extraTaxPaise,
  Value<int> rowid,
});
typedef $$BillLinesTableUpdateCompanionBuilder = BillLinesCompanion Function({
  Value<String> id,
  Value<String> billId,
  Value<String> articleId,
  Value<String> barcodeValue,
  Value<String> productName,
  Value<String> size,
  Value<String> color,
  Value<int> mrpPaise,
  Value<int> markdownPaise,
  Value<int> discountPaise,
  Value<int> finalPaise,
  Value<int> gstBp,
  Value<int> taxablePaise,
  Value<int> taxPaise,
  Value<int> extraTaxPaise,
  Value<int> rowid,
});

final class $$BillLinesTableReferences
    extends BaseReferences<_$AppDatabase, $BillLinesTable, BillLineRow> {
  $$BillLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BillsTable _billIdTable(_$AppDatabase db) =>
      db.bills.createAlias('bill_lines__bill_id__bills__id');

  $$BillsTableProcessedTableManager get billId {
    final $_column = $_itemColumn<String>('bill_id')!;

    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArticlesTable _articleIdTable(_$AppDatabase db) =>
      db.articles.createAlias('bill_lines__article_id__articles__id');

  $$ArticlesTableProcessedTableManager get articleId {
    final $_column = $_itemColumn<String>('article_id')!;

    final manager = $$ArticlesTableTableManager(
      $_db,
      $_db.articles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_articleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReturnLinesTable, List<ReturnLineRow>>
  _returnLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.returnLines,
    aliasName: 'bill_lines__id__return_lines__bill_line_id',
  );

  $$ReturnLinesTableProcessedTableManager get returnLinesRefs {
    final manager = $$ReturnLinesTableTableManager(
      $_db,
      $_db.returnLines,
    ).filter((f) => f.billLineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_returnLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BillLinesTableFilterComposer
    extends Composer<_$AppDatabase, $BillLinesTable> {
  $$BillLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mrpPaise => $composableBuilder(
    column: $table.mrpPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get markdownPaise => $composableBuilder(
    column: $table.markdownPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalPaise => $composableBuilder(
    column: $table.finalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gstBp => $composableBuilder(
    column: $table.gstBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxablePaise => $composableBuilder(
    column: $table.taxablePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxPaise => $composableBuilder(
    column: $table.taxPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extraTaxPaise => $composableBuilder(
    column: $table.extraTaxPaise,
    builder: (column) => ColumnFilters(column),
  );

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArticlesTableFilterComposer get articleId {
    final $$ArticlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableFilterComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> returnLinesRefs(
    Expression<bool> Function($$ReturnLinesTableFilterComposer f) f,
  ) {
    final $$ReturnLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returnLines,
      getReferencedColumn: (t) => t.billLineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnLinesTableFilterComposer(
            $db: $db,
            $table: $db.returnLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $BillLinesTable> {
  $$BillLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mrpPaise => $composableBuilder(
    column: $table.mrpPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get markdownPaise => $composableBuilder(
    column: $table.markdownPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalPaise => $composableBuilder(
    column: $table.finalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gstBp => $composableBuilder(
    column: $table.gstBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxablePaise => $composableBuilder(
    column: $table.taxablePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxPaise => $composableBuilder(
    column: $table.taxPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extraTaxPaise => $composableBuilder(
    column: $table.extraTaxPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableOrderingComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArticlesTableOrderingComposer get articleId {
    final $$ArticlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableOrderingComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillLinesTable> {
  $$BillLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get mrpPaise =>
      $composableBuilder(column: $table.mrpPaise, builder: (column) => column);

  GeneratedColumn<int> get markdownPaise => $composableBuilder(
    column: $table.markdownPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountPaise => $composableBuilder(
    column: $table.discountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finalPaise => $composableBuilder(
    column: $table.finalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gstBp =>
      $composableBuilder(column: $table.gstBp, builder: (column) => column);

  GeneratedColumn<int> get taxablePaise => $composableBuilder(
    column: $table.taxablePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxPaise =>
      $composableBuilder(column: $table.taxPaise, builder: (column) => column);

  GeneratedColumn<int> get extraTaxPaise => $composableBuilder(
    column: $table.extraTaxPaise,
    builder: (column) => column,
  );

  $$BillsTableAnnotationComposer get billId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArticlesTableAnnotationComposer get articleId {
    final $$ArticlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableAnnotationComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> returnLinesRefs<T extends Object>(
    Expression<T> Function($$ReturnLinesTableAnnotationComposer a) f,
  ) {
    final $$ReturnLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.returnLines,
      getReferencedColumn: (t) => t.billLineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.returnLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillLinesTable,
          BillLineRow,
          $$BillLinesTableFilterComposer,
          $$BillLinesTableOrderingComposer,
          $$BillLinesTableAnnotationComposer,
          $$BillLinesTableCreateCompanionBuilder,
          $$BillLinesTableUpdateCompanionBuilder,
          (BillLineRow, $$BillLinesTableReferences),
          BillLineRow,
          PrefetchHooks Function({
            bool billId,
            bool articleId,
            bool returnLinesRefs,
          })
        > {
  $$BillLinesTableTableManager(_$AppDatabase db, $BillLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<String> articleId = const Value.absent(),
                Value<String> barcodeValue = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> size = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<int> mrpPaise = const Value.absent(),
                Value<int> markdownPaise = const Value.absent(),
                Value<int> discountPaise = const Value.absent(),
                Value<int> finalPaise = const Value.absent(),
                Value<int> gstBp = const Value.absent(),
                Value<int> taxablePaise = const Value.absent(),
                Value<int> taxPaise = const Value.absent(),
                Value<int> extraTaxPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillLinesCompanion(
                id: id,
                billId: billId,
                articleId: articleId,
                barcodeValue: barcodeValue,
                productName: productName,
                size: size,
                color: color,
                mrpPaise: mrpPaise,
                markdownPaise: markdownPaise,
                discountPaise: discountPaise,
                finalPaise: finalPaise,
                gstBp: gstBp,
                taxablePaise: taxablePaise,
                taxPaise: taxPaise,
                extraTaxPaise: extraTaxPaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String billId,
                required String articleId,
                required String barcodeValue,
                required String productName,
                required String size,
                required String color,
                required int mrpPaise,
                required int markdownPaise,
                required int discountPaise,
                required int finalPaise,
                Value<int> gstBp = const Value.absent(),
                Value<int> taxablePaise = const Value.absent(),
                Value<int> taxPaise = const Value.absent(),
                Value<int> extraTaxPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillLinesCompanion.insert(
                id: id,
                billId: billId,
                articleId: articleId,
                barcodeValue: barcodeValue,
                productName: productName,
                size: size,
                color: color,
                mrpPaise: mrpPaise,
                markdownPaise: markdownPaise,
                discountPaise: discountPaise,
                finalPaise: finalPaise,
                gstBp: gstBp,
                taxablePaise: taxablePaise,
                taxPaise: taxPaise,
                extraTaxPaise: extraTaxPaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillLinesTable, BillLineRow>(table),
                  $$BillLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({billId = false, articleId = false, returnLinesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (returnLinesRefs) db.returnLines,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (billId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.billId,
                            referencedTable: $$BillLinesTableReferences
                                ._billIdTable(db),
                            referencedColumn: $$BillLinesTableReferences
                                ._billIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (articleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.articleId,
                            referencedTable: $$BillLinesTableReferences
                                ._articleIdTable(db),
                            referencedColumn: $$BillLinesTableReferences
                                ._articleIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (returnLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          BillLineRow,
                          $BillLinesTable,
                          ReturnLineRow,
                          $ReturnLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$BillLinesTableReferences
                              ._returnLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BillLinesTableReferences(
                                db,
                                table,
                                p0,
                              ).returnLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'bill_line_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BillLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillLinesTable,
      BillLineRow,
      $$BillLinesTableFilterComposer,
      $$BillLinesTableOrderingComposer,
      $$BillLinesTableAnnotationComposer,
      $$BillLinesTableCreateCompanionBuilder,
      $$BillLinesTableUpdateCompanionBuilder,
      (BillLineRow, $$BillLinesTableReferences),
      BillLineRow,
      PrefetchHooks Function({
        bool billId,
        bool articleId,
        bool returnLinesRefs,
      })
    >;
typedef $$BillPaymentsTableCreateCompanionBuilder =
    BillPaymentsCompanion Function({
      required String id,
      required String billId,
      required String mode,
      required int amountPaise,
      Value<int> rowid,
    });
typedef $$BillPaymentsTableUpdateCompanionBuilder =
    BillPaymentsCompanion Function({
      Value<String> id,
      Value<String> billId,
      Value<String> mode,
      Value<int> amountPaise,
      Value<int> rowid,
    });

final class $$BillPaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $BillPaymentsTable, BillPaymentRow> {
  $$BillPaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BillsTable _billIdTable(_$AppDatabase db) =>
      db.bills.createAlias('bill_payments__bill_id__bills__id');

  $$BillsTableProcessedTableManager get billId {
    final $_column = $_itemColumn<String>('bill_id')!;

    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BillPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $BillPaymentsTable> {
  $$BillPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillPaymentsTable> {
  $$BillPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableOrderingComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillPaymentsTable> {
  $$BillPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  $$BillsTableAnnotationComposer get billId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillPaymentsTable,
          BillPaymentRow,
          $$BillPaymentsTableFilterComposer,
          $$BillPaymentsTableOrderingComposer,
          $$BillPaymentsTableAnnotationComposer,
          $$BillPaymentsTableCreateCompanionBuilder,
          $$BillPaymentsTableUpdateCompanionBuilder,
          (BillPaymentRow, $$BillPaymentsTableReferences),
          BillPaymentRow,
          PrefetchHooks Function({bool billId})
        > {
  $$BillPaymentsTableTableManager(_$AppDatabase db, $BillPaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillPaymentsCompanion(
                id: id,
                billId: billId,
                mode: mode,
                amountPaise: amountPaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String billId,
                required String mode,
                required int amountPaise,
                Value<int> rowid = const Value.absent(),
              }) => BillPaymentsCompanion.insert(
                id: id,
                billId: billId,
                mode: mode,
                amountPaise: amountPaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillPaymentsTable, BillPaymentRow>(table),
                  $$BillPaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({billId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (billId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.billId,
                        referencedTable: $$BillPaymentsTableReferences
                            ._billIdTable(db),
                        referencedColumn: $$BillPaymentsTableReferences
                            ._billIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BillPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillPaymentsTable,
      BillPaymentRow,
      $$BillPaymentsTableFilterComposer,
      $$BillPaymentsTableOrderingComposer,
      $$BillPaymentsTableAnnotationComposer,
      $$BillPaymentsTableCreateCompanionBuilder,
      $$BillPaymentsTableUpdateCompanionBuilder,
      (BillPaymentRow, $$BillPaymentsTableReferences),
      BillPaymentRow,
      PrefetchHooks Function({bool billId})
    >;
typedef $$BillSequencesTableCreateCompanionBuilder =
    BillSequencesCompanion Function({
      required String counterId,
      required String yearLabel,
      required int lastSerial,
      Value<int> rowid,
    });
typedef $$BillSequencesTableUpdateCompanionBuilder =
    BillSequencesCompanion Function({
      Value<String> counterId,
      Value<String> yearLabel,
      Value<int> lastSerial,
      Value<int> rowid,
    });

final class $$BillSequencesTableReferences
    extends
        BaseReferences<_$AppDatabase, $BillSequencesTable, BillSequenceRow> {
  $$BillSequencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CountersTable _counterIdTable(_$AppDatabase db) =>
      db.counters.createAlias('bill_sequences__counter_id__counters__id');

  $$CountersTableProcessedTableManager get counterId {
    final $_column = $_itemColumn<String>('counter_id')!;

    final manager = $$CountersTableTableManager(
      $_db,
      $_db.counters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BillSequencesTableFilterComposer
    extends Composer<_$AppDatabase, $BillSequencesTable> {
  $$BillSequencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get yearLabel => $composableBuilder(
    column: $table.yearLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSerial => $composableBuilder(
    column: $table.lastSerial,
    builder: (column) => ColumnFilters(column),
  );

  $$CountersTableFilterComposer get counterId {
    final $$CountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableFilterComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillSequencesTableOrderingComposer
    extends Composer<_$AppDatabase, $BillSequencesTable> {
  $$BillSequencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get yearLabel => $composableBuilder(
    column: $table.yearLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSerial => $composableBuilder(
    column: $table.lastSerial,
    builder: (column) => ColumnOrderings(column),
  );

  $$CountersTableOrderingComposer get counterId {
    final $$CountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableOrderingComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillSequencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillSequencesTable> {
  $$BillSequencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get yearLabel =>
      $composableBuilder(column: $table.yearLabel, builder: (column) => column);

  GeneratedColumn<int> get lastSerial => $composableBuilder(
    column: $table.lastSerial,
    builder: (column) => column,
  );

  $$CountersTableAnnotationComposer get counterId {
    final $$CountersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableAnnotationComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillSequencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillSequencesTable,
          BillSequenceRow,
          $$BillSequencesTableFilterComposer,
          $$BillSequencesTableOrderingComposer,
          $$BillSequencesTableAnnotationComposer,
          $$BillSequencesTableCreateCompanionBuilder,
          $$BillSequencesTableUpdateCompanionBuilder,
          (BillSequenceRow, $$BillSequencesTableReferences),
          BillSequenceRow,
          PrefetchHooks Function({bool counterId})
        > {
  $$BillSequencesTableTableManager(_$AppDatabase db, $BillSequencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillSequencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillSequencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillSequencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> counterId = const Value.absent(),
                Value<String> yearLabel = const Value.absent(),
                Value<int> lastSerial = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillSequencesCompanion(
                counterId: counterId,
                yearLabel: yearLabel,
                lastSerial: lastSerial,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String counterId,
                required String yearLabel,
                required int lastSerial,
                Value<int> rowid = const Value.absent(),
              }) => BillSequencesCompanion.insert(
                counterId: counterId,
                yearLabel: yearLabel,
                lastSerial: lastSerial,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillSequencesTable, BillSequenceRow>(table),
                  $$BillSequencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({counterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (counterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.counterId,
                        referencedTable: $$BillSequencesTableReferences
                            ._counterIdTable(db),
                        referencedColumn: $$BillSequencesTableReferences
                            ._counterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BillSequencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillSequencesTable,
      BillSequenceRow,
      $$BillSequencesTableFilterComposer,
      $$BillSequencesTableOrderingComposer,
      $$BillSequencesTableAnnotationComposer,
      $$BillSequencesTableCreateCompanionBuilder,
      $$BillSequencesTableUpdateCompanionBuilder,
      (BillSequenceRow, $$BillSequencesTableReferences),
      BillSequenceRow,
      PrefetchHooks Function({bool counterId})
    >;
typedef $$CreditNoteUsesTableCreateCompanionBuilder =
    CreditNoteUsesCompanion Function({
      required String id,
      required String creditNoteId,
      required String billId,
      required int amountPaise,
      Value<int> rowid,
    });
typedef $$CreditNoteUsesTableUpdateCompanionBuilder =
    CreditNoteUsesCompanion Function({
      Value<String> id,
      Value<String> creditNoteId,
      Value<String> billId,
      Value<int> amountPaise,
      Value<int> rowid,
    });

final class $$CreditNoteUsesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CreditNoteUsesTable, CreditNoteUseRow> {
  $$CreditNoteUsesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CreditNotesTable _creditNoteIdTable(_$AppDatabase db) => db
      .creditNotes
      .createAlias('credit_note_uses__credit_note_id__credit_notes__id');

  $$CreditNotesTableProcessedTableManager get creditNoteId {
    final $_column = $_itemColumn<String>('credit_note_id')!;

    final manager = $$CreditNotesTableTableManager(
      $_db,
      $_db.creditNotes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creditNoteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BillsTable _billIdTable(_$AppDatabase db) =>
      db.bills.createAlias('credit_note_uses__bill_id__bills__id');

  $$BillsTableProcessedTableManager get billId {
    final $_column = $_itemColumn<String>('bill_id')!;

    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CreditNoteUsesTableFilterComposer
    extends Composer<_$AppDatabase, $CreditNoteUsesTable> {
  $$CreditNoteUsesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  $$CreditNotesTableFilterComposer get creditNoteId {
    final $$CreditNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditNoteId,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableFilterComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CreditNoteUsesTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditNoteUsesTable> {
  $$CreditNoteUsesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$CreditNotesTableOrderingComposer get creditNoteId {
    final $$CreditNotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditNoteId,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableOrderingComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableOrderingComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CreditNoteUsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditNoteUsesTable> {
  $$CreditNoteUsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  $$CreditNotesTableAnnotationComposer get creditNoteId {
    final $$CreditNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditNoteId,
      referencedTable: $db.creditNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.creditNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableAnnotationComposer get billId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CreditNoteUsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditNoteUsesTable,
          CreditNoteUseRow,
          $$CreditNoteUsesTableFilterComposer,
          $$CreditNoteUsesTableOrderingComposer,
          $$CreditNoteUsesTableAnnotationComposer,
          $$CreditNoteUsesTableCreateCompanionBuilder,
          $$CreditNoteUsesTableUpdateCompanionBuilder,
          (CreditNoteUseRow, $$CreditNoteUsesTableReferences),
          CreditNoteUseRow,
          PrefetchHooks Function({bool creditNoteId, bool billId})
        > {
  $$CreditNoteUsesTableTableManager(
    _$AppDatabase db,
    $CreditNoteUsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditNoteUsesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditNoteUsesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditNoteUsesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> creditNoteId = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditNoteUsesCompanion(
                id: id,
                creditNoteId: creditNoteId,
                billId: billId,
                amountPaise: amountPaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String creditNoteId,
                required String billId,
                required int amountPaise,
                Value<int> rowid = const Value.absent(),
              }) => CreditNoteUsesCompanion.insert(
                id: id,
                creditNoteId: creditNoteId,
                billId: billId,
                amountPaise: amountPaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CreditNoteUsesTable, CreditNoteUseRow>(table),
                  $$CreditNoteUsesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({creditNoteId = false, billId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (creditNoteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.creditNoteId,
                        referencedTable: $$CreditNoteUsesTableReferences
                            ._creditNoteIdTable(db),
                        referencedColumn: $$CreditNoteUsesTableReferences
                            ._creditNoteIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (billId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.billId,
                        referencedTable: $$CreditNoteUsesTableReferences
                            ._billIdTable(db),
                        referencedColumn: $$CreditNoteUsesTableReferences
                            ._billIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CreditNoteUsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditNoteUsesTable,
      CreditNoteUseRow,
      $$CreditNoteUsesTableFilterComposer,
      $$CreditNoteUsesTableOrderingComposer,
      $$CreditNoteUsesTableAnnotationComposer,
      $$CreditNoteUsesTableCreateCompanionBuilder,
      $$CreditNoteUsesTableUpdateCompanionBuilder,
      (CreditNoteUseRow, $$CreditNoteUsesTableReferences),
      CreditNoteUseRow,
      PrefetchHooks Function({bool creditNoteId, bool billId})
    >;
typedef $$ReturnLinesTableCreateCompanionBuilder =
    ReturnLinesCompanion Function({
      required String id,
      required String returnId,
      required String billLineId,
      required String articleId,
      required int refundPaise,
      required String outcome,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$ReturnLinesTableUpdateCompanionBuilder =
    ReturnLinesCompanion Function({
      Value<String> id,
      Value<String> returnId,
      Value<String> billLineId,
      Value<String> articleId,
      Value<int> refundPaise,
      Value<String> outcome,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$ReturnLinesTableReferences
    extends BaseReferences<_$AppDatabase, $ReturnLinesTable, ReturnLineRow> {
  $$ReturnLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReturnsTable _returnIdTable(_$AppDatabase db) =>
      db.returns.createAlias('return_lines__return_id__returns__id');

  $$ReturnsTableProcessedTableManager get returnId {
    final $_column = $_itemColumn<String>('return_id')!;

    final manager = $$ReturnsTableTableManager(
      $_db,
      $_db.returns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_returnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BillLinesTable _billLineIdTable(_$AppDatabase db) =>
      db.billLines.createAlias('return_lines__bill_line_id__bill_lines__id');

  $$BillLinesTableProcessedTableManager get billLineId {
    final $_column = $_itemColumn<String>('bill_line_id')!;

    final manager = $$BillLinesTableTableManager(
      $_db,
      $_db.billLines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billLineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ArticlesTable _articleIdTable(_$AppDatabase db) =>
      db.articles.createAlias('return_lines__article_id__articles__id');

  $$ArticlesTableProcessedTableManager get articleId {
    final $_column = $_itemColumn<String>('article_id')!;

    final manager = $$ArticlesTableTableManager(
      $_db,
      $_db.articles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_articleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReturnLinesTableFilterComposer
    extends Composer<_$AppDatabase, $ReturnLinesTable> {
  $$ReturnLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refundPaise => $composableBuilder(
    column: $table.refundPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$ReturnsTableFilterComposer get returnId {
    final $$ReturnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.returnId,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableFilterComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillLinesTableFilterComposer get billLineId {
    final $$BillLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billLineId,
      referencedTable: $db.billLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillLinesTableFilterComposer(
            $db: $db,
            $table: $db.billLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArticlesTableFilterComposer get articleId {
    final $$ArticlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableFilterComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReturnLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReturnLinesTable> {
  $$ReturnLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refundPaise => $composableBuilder(
    column: $table.refundPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReturnsTableOrderingComposer get returnId {
    final $$ReturnsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.returnId,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableOrderingComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillLinesTableOrderingComposer get billLineId {
    final $$BillLinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billLineId,
      referencedTable: $db.billLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillLinesTableOrderingComposer(
            $db: $db,
            $table: $db.billLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArticlesTableOrderingComposer get articleId {
    final $$ArticlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableOrderingComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReturnLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReturnLinesTable> {
  $$ReturnLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get refundPaise => $composableBuilder(
    column: $table.refundPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$ReturnsTableAnnotationComposer get returnId {
    final $$ReturnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.returnId,
      referencedTable: $db.returns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReturnsTableAnnotationComposer(
            $db: $db,
            $table: $db.returns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillLinesTableAnnotationComposer get billLineId {
    final $$BillLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billLineId,
      referencedTable: $db.billLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.billLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ArticlesTableAnnotationComposer get articleId {
    final $$ArticlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.articleId,
      referencedTable: $db.articles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArticlesTableAnnotationComposer(
            $db: $db,
            $table: $db.articles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReturnLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReturnLinesTable,
          ReturnLineRow,
          $$ReturnLinesTableFilterComposer,
          $$ReturnLinesTableOrderingComposer,
          $$ReturnLinesTableAnnotationComposer,
          $$ReturnLinesTableCreateCompanionBuilder,
          $$ReturnLinesTableUpdateCompanionBuilder,
          (ReturnLineRow, $$ReturnLinesTableReferences),
          ReturnLineRow,
          PrefetchHooks Function({
            bool returnId,
            bool billLineId,
            bool articleId,
          })
        > {
  $$ReturnLinesTableTableManager(_$AppDatabase db, $ReturnLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReturnLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReturnLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReturnLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> returnId = const Value.absent(),
                Value<String> billLineId = const Value.absent(),
                Value<String> articleId = const Value.absent(),
                Value<int> refundPaise = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReturnLinesCompanion(
                id: id,
                returnId: returnId,
                billLineId: billLineId,
                articleId: articleId,
                refundPaise: refundPaise,
                outcome: outcome,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String returnId,
                required String billLineId,
                required String articleId,
                required int refundPaise,
                required String outcome,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReturnLinesCompanion.insert(
                id: id,
                returnId: returnId,
                billLineId: billLineId,
                articleId: articleId,
                refundPaise: refundPaise,
                outcome: outcome,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReturnLinesTable, ReturnLineRow>(table),
                  $$ReturnLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({returnId = false, billLineId = false, articleId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (returnId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.returnId,
                            referencedTable: $$ReturnLinesTableReferences
                                ._returnIdTable(db),
                            referencedColumn: $$ReturnLinesTableReferences
                                ._returnIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (billLineId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.billLineId,
                            referencedTable: $$ReturnLinesTableReferences
                                ._billLineIdTable(db),
                            referencedColumn: $$ReturnLinesTableReferences
                                ._billLineIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (articleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.articleId,
                            referencedTable: $$ReturnLinesTableReferences
                                ._articleIdTable(db),
                            referencedColumn: $$ReturnLinesTableReferences
                                ._articleIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ReturnLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReturnLinesTable,
      ReturnLineRow,
      $$ReturnLinesTableFilterComposer,
      $$ReturnLinesTableOrderingComposer,
      $$ReturnLinesTableAnnotationComposer,
      $$ReturnLinesTableCreateCompanionBuilder,
      $$ReturnLinesTableUpdateCompanionBuilder,
      (ReturnLineRow, $$ReturnLinesTableReferences),
      ReturnLineRow,
      PrefetchHooks Function({bool returnId, bool billLineId, bool articleId})
    >;
typedef $$ShiftClosesTableCreateCompanionBuilder =
    ShiftClosesCompanion Function({
      required String id,
      required String shiftId,
      required DateTime closedAt,
      required int countedPaise,
      required int expectedPaise,
      required int variancePaise,
      required String countDetail,
      Value<int> rowid,
    });
typedef $$ShiftClosesTableUpdateCompanionBuilder =
    ShiftClosesCompanion Function({
      Value<String> id,
      Value<String> shiftId,
      Value<DateTime> closedAt,
      Value<int> countedPaise,
      Value<int> expectedPaise,
      Value<int> variancePaise,
      Value<String> countDetail,
      Value<int> rowid,
    });

final class $$ShiftClosesTableReferences
    extends BaseReferences<_$AppDatabase, $ShiftClosesTable, ShiftCloseRow> {
  $$ShiftClosesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) =>
      db.shifts.createAlias('shift_closes__shift_id__shifts__id');

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<String>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShiftClosesTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftClosesTable> {
  $$ShiftClosesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countedPaise => $composableBuilder(
    column: $table.countedPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedPaise => $composableBuilder(
    column: $table.expectedPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get variancePaise => $composableBuilder(
    column: $table.variancePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countDetail => $composableBuilder(
    column: $table.countDetail,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftClosesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftClosesTable> {
  $$ShiftClosesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countedPaise => $composableBuilder(
    column: $table.countedPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedPaise => $composableBuilder(
    column: $table.expectedPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get variancePaise => $composableBuilder(
    column: $table.variancePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countDetail => $composableBuilder(
    column: $table.countDetail,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftClosesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftClosesTable> {
  $$ShiftClosesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get countedPaise => $composableBuilder(
    column: $table.countedPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedPaise => $composableBuilder(
    column: $table.expectedPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get variancePaise => $composableBuilder(
    column: $table.variancePaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countDetail => $composableBuilder(
    column: $table.countDetail,
    builder: (column) => column,
  );

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftClosesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftClosesTable,
          ShiftCloseRow,
          $$ShiftClosesTableFilterComposer,
          $$ShiftClosesTableOrderingComposer,
          $$ShiftClosesTableAnnotationComposer,
          $$ShiftClosesTableCreateCompanionBuilder,
          $$ShiftClosesTableUpdateCompanionBuilder,
          (ShiftCloseRow, $$ShiftClosesTableReferences),
          ShiftCloseRow,
          PrefetchHooks Function({bool shiftId})
        > {
  $$ShiftClosesTableTableManager(_$AppDatabase db, $ShiftClosesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftClosesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftClosesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftClosesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<DateTime> closedAt = const Value.absent(),
                Value<int> countedPaise = const Value.absent(),
                Value<int> expectedPaise = const Value.absent(),
                Value<int> variancePaise = const Value.absent(),
                Value<String> countDetail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftClosesCompanion(
                id: id,
                shiftId: shiftId,
                closedAt: closedAt,
                countedPaise: countedPaise,
                expectedPaise: expectedPaise,
                variancePaise: variancePaise,
                countDetail: countDetail,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shiftId,
                required DateTime closedAt,
                required int countedPaise,
                required int expectedPaise,
                required int variancePaise,
                required String countDetail,
                Value<int> rowid = const Value.absent(),
              }) => ShiftClosesCompanion.insert(
                id: id,
                shiftId: shiftId,
                closedAt: closedAt,
                countedPaise: countedPaise,
                expectedPaise: expectedPaise,
                variancePaise: variancePaise,
                countDetail: countDetail,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShiftClosesTable, ShiftCloseRow>(table),
                  $$ShiftClosesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shiftId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shiftId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.shiftId,
                        referencedTable: $$ShiftClosesTableReferences
                            ._shiftIdTable(db),
                        referencedColumn: $$ShiftClosesTableReferences
                            ._shiftIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShiftClosesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftClosesTable,
      ShiftCloseRow,
      $$ShiftClosesTableFilterComposer,
      $$ShiftClosesTableOrderingComposer,
      $$ShiftClosesTableAnnotationComposer,
      $$ShiftClosesTableCreateCompanionBuilder,
      $$ShiftClosesTableUpdateCompanionBuilder,
      (ShiftCloseRow, $$ShiftClosesTableReferences),
      ShiftCloseRow,
      PrefetchHooks Function({bool shiftId})
    >;
typedef $$ShiftBreaksTableCreateCompanionBuilder =
    ShiftBreaksCompanion Function({
      required String id,
      required String shiftId,
      required DateTime startedAt,
      Value<int> rowid,
    });
typedef $$ShiftBreaksTableUpdateCompanionBuilder =
    ShiftBreaksCompanion Function({
      Value<String> id,
      Value<String> shiftId,
      Value<DateTime> startedAt,
      Value<int> rowid,
    });

final class $$ShiftBreaksTableReferences
    extends BaseReferences<_$AppDatabase, $ShiftBreaksTable, ShiftBreakRow> {
  $$ShiftBreaksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) =>
      db.shifts.createAlias('shift_breaks__shift_id__shifts__id');

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<String>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShiftBreakEndsTable, List<ShiftBreakEndRow>>
  _shiftBreakEndsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shiftBreakEnds,
    aliasName: 'shift_breaks__id__shift_break_ends__break_id',
  );

  $$ShiftBreakEndsTableProcessedTableManager get shiftBreakEndsRefs {
    final manager = $$ShiftBreakEndsTableTableManager(
      $_db,
      $_db.shiftBreakEnds,
    ).filter((f) => f.breakId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftBreakEndsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShiftBreaksTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftBreaksTable> {
  $$ShiftBreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shiftBreakEndsRefs(
    Expression<bool> Function($$ShiftBreakEndsTableFilterComposer f) f,
  ) {
    final $$ShiftBreakEndsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shiftBreakEnds,
      getReferencedColumn: (t) => t.breakId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftBreakEndsTableFilterComposer(
            $db: $db,
            $table: $db.shiftBreakEnds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftBreaksTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftBreaksTable> {
  $$ShiftBreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftBreaksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftBreaksTable> {
  $$ShiftBreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shiftBreakEndsRefs<T extends Object>(
    Expression<T> Function($$ShiftBreakEndsTableAnnotationComposer a) f,
  ) {
    final $$ShiftBreakEndsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shiftBreakEnds,
      getReferencedColumn: (t) => t.breakId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftBreakEndsTableAnnotationComposer(
            $db: $db,
            $table: $db.shiftBreakEnds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftBreaksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftBreaksTable,
          ShiftBreakRow,
          $$ShiftBreaksTableFilterComposer,
          $$ShiftBreaksTableOrderingComposer,
          $$ShiftBreaksTableAnnotationComposer,
          $$ShiftBreaksTableCreateCompanionBuilder,
          $$ShiftBreaksTableUpdateCompanionBuilder,
          (ShiftBreakRow, $$ShiftBreaksTableReferences),
          ShiftBreakRow,
          PrefetchHooks Function({bool shiftId, bool shiftBreakEndsRefs})
        > {
  $$ShiftBreaksTableTableManager(_$AppDatabase db, $ShiftBreaksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftBreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftBreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftBreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftBreaksCompanion(
                id: id,
                shiftId: shiftId,
                startedAt: startedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String shiftId,
                required DateTime startedAt,
                Value<int> rowid = const Value.absent(),
              }) => ShiftBreaksCompanion.insert(
                id: id,
                shiftId: shiftId,
                startedAt: startedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShiftBreaksTable, ShiftBreakRow>(table),
                  $$ShiftBreaksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({shiftId = false, shiftBreakEndsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shiftBreakEndsRefs) db.shiftBreakEnds,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (shiftId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.shiftId,
                            referencedTable: $$ShiftBreaksTableReferences
                                ._shiftIdTable(db),
                            referencedColumn: $$ShiftBreaksTableReferences
                                ._shiftIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shiftBreakEndsRefs)
                        await $_getPrefetchedDataByColumns<
                          ShiftBreakRow,
                          $ShiftBreaksTable,
                          ShiftBreakEndRow,
                          $ShiftBreakEndsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ShiftBreaksTableReferences
                              ._shiftBreakEndsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShiftBreaksTableReferences(
                                db,
                                table,
                                p0,
                              ).shiftBreakEndsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'break_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ShiftBreaksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftBreaksTable,
      ShiftBreakRow,
      $$ShiftBreaksTableFilterComposer,
      $$ShiftBreaksTableOrderingComposer,
      $$ShiftBreaksTableAnnotationComposer,
      $$ShiftBreaksTableCreateCompanionBuilder,
      $$ShiftBreaksTableUpdateCompanionBuilder,
      (ShiftBreakRow, $$ShiftBreaksTableReferences),
      ShiftBreakRow,
      PrefetchHooks Function({bool shiftId, bool shiftBreakEndsRefs})
    >;
typedef $$ShiftBreakEndsTableCreateCompanionBuilder =
    ShiftBreakEndsCompanion Function({
      required String id,
      required String breakId,
      required DateTime endedAt,
      Value<int> rowid,
    });
typedef $$ShiftBreakEndsTableUpdateCompanionBuilder =
    ShiftBreakEndsCompanion Function({
      Value<String> id,
      Value<String> breakId,
      Value<DateTime> endedAt,
      Value<int> rowid,
    });

final class $$ShiftBreakEndsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ShiftBreakEndsTable, ShiftBreakEndRow> {
  $$ShiftBreakEndsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShiftBreaksTable _breakIdTable(_$AppDatabase db) => db.shiftBreaks
      .createAlias('shift_break_ends__break_id__shift_breaks__id');

  $$ShiftBreaksTableProcessedTableManager get breakId {
    final $_column = $_itemColumn<String>('break_id')!;

    final manager = $$ShiftBreaksTableTableManager(
      $_db,
      $_db.shiftBreaks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_breakIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShiftBreakEndsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftBreakEndsTable> {
  $$ShiftBreakEndsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftBreaksTableFilterComposer get breakId {
    final $$ShiftBreaksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.breakId,
      referencedTable: $db.shiftBreaks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftBreaksTableFilterComposer(
            $db: $db,
            $table: $db.shiftBreaks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftBreakEndsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftBreakEndsTable> {
  $$ShiftBreakEndsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftBreaksTableOrderingComposer get breakId {
    final $$ShiftBreaksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.breakId,
      referencedTable: $db.shiftBreaks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftBreaksTableOrderingComposer(
            $db: $db,
            $table: $db.shiftBreaks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftBreakEndsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftBreakEndsTable> {
  $$ShiftBreakEndsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  $$ShiftBreaksTableAnnotationComposer get breakId {
    final $$ShiftBreaksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.breakId,
      referencedTable: $db.shiftBreaks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftBreaksTableAnnotationComposer(
            $db: $db,
            $table: $db.shiftBreaks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftBreakEndsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftBreakEndsTable,
          ShiftBreakEndRow,
          $$ShiftBreakEndsTableFilterComposer,
          $$ShiftBreakEndsTableOrderingComposer,
          $$ShiftBreakEndsTableAnnotationComposer,
          $$ShiftBreakEndsTableCreateCompanionBuilder,
          $$ShiftBreakEndsTableUpdateCompanionBuilder,
          (ShiftBreakEndRow, $$ShiftBreakEndsTableReferences),
          ShiftBreakEndRow,
          PrefetchHooks Function({bool breakId})
        > {
  $$ShiftBreakEndsTableTableManager(
    _$AppDatabase db,
    $ShiftBreakEndsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftBreakEndsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftBreakEndsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftBreakEndsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> breakId = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftBreakEndsCompanion(
                id: id,
                breakId: breakId,
                endedAt: endedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String breakId,
                required DateTime endedAt,
                Value<int> rowid = const Value.absent(),
              }) => ShiftBreakEndsCompanion.insert(
                id: id,
                breakId: breakId,
                endedAt: endedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShiftBreakEndsTable, ShiftBreakEndRow>(table),
                  $$ShiftBreakEndsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({breakId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (breakId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.breakId,
                        referencedTable: $$ShiftBreakEndsTableReferences
                            ._breakIdTable(db),
                        referencedColumn: $$ShiftBreakEndsTableReferences
                            ._breakIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShiftBreakEndsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftBreakEndsTable,
      ShiftBreakEndRow,
      $$ShiftBreakEndsTableFilterComposer,
      $$ShiftBreakEndsTableOrderingComposer,
      $$ShiftBreakEndsTableAnnotationComposer,
      $$ShiftBreakEndsTableCreateCompanionBuilder,
      $$ShiftBreakEndsTableUpdateCompanionBuilder,
      (ShiftBreakEndRow, $$ShiftBreakEndsTableReferences),
      ShiftBreakEndRow,
      PrefetchHooks Function({bool breakId})
    >;
typedef $$DaybookTableCreateCompanionBuilder = DaybookCompanion Function({
  required String id,
  required DateTime at,
  required String shiftId,
  required String kind,
  required int amountPaise,
  required String refType,
  required String refId,
  Value<int> rowid,
});
typedef $$DaybookTableUpdateCompanionBuilder = DaybookCompanion Function({
  Value<String> id,
  Value<DateTime> at,
  Value<String> shiftId,
  Value<String> kind,
  Value<int> amountPaise,
  Value<String> refType,
  Value<String> refId,
  Value<int> rowid,
});

final class $$DaybookTableReferences
    extends BaseReferences<_$AppDatabase, $DaybookTable, DaybookRow> {
  $$DaybookTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) =>
      db.shifts.createAlias('daybook__shift_id__shifts__id');

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<String>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DaybookTableFilterComposer
    extends Composer<_$AppDatabase, $DaybookTable> {
  $$DaybookTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refType => $composableBuilder(
    column: $table.refType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DaybookTableOrderingComposer
    extends Composer<_$AppDatabase, $DaybookTable> {
  $$DaybookTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refType => $composableBuilder(
    column: $table.refType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DaybookTableAnnotationComposer
    extends Composer<_$AppDatabase, $DaybookTable> {
  $$DaybookTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refType =>
      $composableBuilder(column: $table.refType, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DaybookTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DaybookTable,
          DaybookRow,
          $$DaybookTableFilterComposer,
          $$DaybookTableOrderingComposer,
          $$DaybookTableAnnotationComposer,
          $$DaybookTableCreateCompanionBuilder,
          $$DaybookTableUpdateCompanionBuilder,
          (DaybookRow, $$DaybookTableReferences),
          DaybookRow,
          PrefetchHooks Function({bool shiftId})
        > {
  $$DaybookTableTableManager(_$AppDatabase db, $DaybookTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaybookTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaybookTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaybookTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> refType = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DaybookCompanion(
                id: id,
                at: at,
                shiftId: shiftId,
                kind: kind,
                amountPaise: amountPaise,
                refType: refType,
                refId: refId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime at,
                required String shiftId,
                required String kind,
                required int amountPaise,
                required String refType,
                required String refId,
                Value<int> rowid = const Value.absent(),
              }) => DaybookCompanion.insert(
                id: id,
                at: at,
                shiftId: shiftId,
                kind: kind,
                amountPaise: amountPaise,
                refType: refType,
                refId: refId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DaybookTable, DaybookRow>(table),
                  $$DaybookTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shiftId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shiftId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.shiftId,
                        referencedTable: $$DaybookTableReferences._shiftIdTable(
                          db,
                        ),
                        referencedColumn: $$DaybookTableReferences
                            ._shiftIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DaybookTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DaybookTable,
      DaybookRow,
      $$DaybookTableFilterComposer,
      $$DaybookTableOrderingComposer,
      $$DaybookTableAnnotationComposer,
      $$DaybookTableCreateCompanionBuilder,
      $$DaybookTableUpdateCompanionBuilder,
      (DaybookRow, $$DaybookTableReferences),
      DaybookRow,
      PrefetchHooks Function({bool shiftId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SizeOptionsTableTableManager get sizeOptions =>
      $$SizeOptionsTableTableManager(_db, _db.sizeOptions);
  $$ColorOptionsTableTableManager get colorOptions =>
      $$ColorOptionsTableTableManager(_db, _db.colorOptions);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$CountersTableTableManager get counters =>
      $$CountersTableTableManager(_db, _db.counters);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$StyleMarkdownsTableTableManager get styleMarkdowns =>
      $$StyleMarkdownsTableTableManager(_db, _db.styleMarkdowns);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
  $$DuesReceiptsTableTableManager get duesReceipts =>
      $$DuesReceiptsTableTableManager(_db, _db.duesReceipts);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$CreditNotesTableTableManager get creditNotes =>
      $$CreditNotesTableTableManager(_db, _db.creditNotes);
  $$ReturnsTableTableManager get returns =>
      $$ReturnsTableTableManager(_db, _db.returns);
  $$DuesLedgerTableTableManager get duesLedger =>
      $$DuesLedgerTableTableManager(_db, _db.duesLedger);
  $$VariantsTableTableManager get variants =>
      $$VariantsTableTableManager(_db, _db.variants);
  $$BatchesTableTableManager get batches =>
      $$BatchesTableTableManager(_db, _db.batches);
  $$BatchLinesTableTableManager get batchLines =>
      $$BatchLinesTableTableManager(_db, _db.batchLines);
  $$ArticlesTableTableManager get articles =>
      $$ArticlesTableTableManager(_db, _db.articles);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$BillLinesTableTableManager get billLines =>
      $$BillLinesTableTableManager(_db, _db.billLines);
  $$BillPaymentsTableTableManager get billPayments =>
      $$BillPaymentsTableTableManager(_db, _db.billPayments);
  $$BillSequencesTableTableManager get billSequences =>
      $$BillSequencesTableTableManager(_db, _db.billSequences);
  $$CreditNoteUsesTableTableManager get creditNoteUses =>
      $$CreditNoteUsesTableTableManager(_db, _db.creditNoteUses);
  $$ReturnLinesTableTableManager get returnLines =>
      $$ReturnLinesTableTableManager(_db, _db.returnLines);
  $$ShiftClosesTableTableManager get shiftCloses =>
      $$ShiftClosesTableTableManager(_db, _db.shiftCloses);
  $$ShiftBreaksTableTableManager get shiftBreaks =>
      $$ShiftBreaksTableTableManager(_db, _db.shiftBreaks);
  $$ShiftBreakEndsTableTableManager get shiftBreakEnds =>
      $$ShiftBreakEndsTableTableManager(_db, _db.shiftBreakEnds);
  $$DaybookTableTableManager get daybook =>
      $$DaybookTableTableManager(_db, _db.daybook);
}
