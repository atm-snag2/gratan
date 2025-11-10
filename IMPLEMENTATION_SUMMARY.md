# MySQL Version Separation - Implementation Summary

## Problem Statement (Japanese)
mysql8 系の機能と同居するために，mysql5 の機能を分離できる状態にしたい．実装クラスを入れ替えられるようにしたい

Translation: To coexist with MySQL 8 features, we want to separate MySQL 5 functionality and make implementation classes replaceable.

## Solution Overview

Implemented a **Factory Pattern** for driver architecture that:
1. Automatically detects MySQL version
2. Instantiates the appropriate driver implementation
3. Maintains backward compatibility
4. Allows manual driver selection when needed

## Architecture

```
Gratan::Driver (Factory)
    ├── Gratan::Driver::Base (Abstract Base Class)
    │   └── Common MySQL functionality
    ├── Gratan::Driver::MySQL5 (MySQL 5.6 and earlier)
    │   └── No SHOW CREATE USER support
    ├── Gratan::Driver::MySQL57 (MySQL 5.7)
    │   └── SHOW CREATE USER support
    └── Gratan::Driver::MySQL8 (MySQL 8.0+)
        └── ALTER USER instead of SET PASSWORD
```

## Key Files Modified

1. **lib/gratan/driver.rb** (287 → 28 lines)
   - Converted to factory pattern
   - Auto-detects MySQL version
   - Returns appropriate driver instance

2. **lib/gratan/driver/base.rb** (NEW, 276 lines)
   - Common functionality extracted from original driver
   - Abstract methods for version-specific features

3. **lib/gratan/driver/mysql5.rb** (NEW, 18 lines)
   - MySQL 5.6 specific implementation
   - `show_create_user` returns nil

4. **lib/gratan/driver/mysql57.rb** (NEW, 16 lines)
   - MySQL 5.7 specific implementation
   - `show_create_user` supported

5. **lib/gratan/driver/mysql8.rb** (NEW, 48 lines)
   - MySQL 8.0 specific implementation
   - Uses `ALTER USER` for password management
   - Handles deprecated PASSWORD() function

6. **lib/gratan.rb**
   - Updated require order to load drivers properly

7. **spec/spec_helper.rb**
   - Added support for `:skip_db_connection` test tag

## Usage Examples

### Automatic Version Detection (Default)
```ruby
client = Gratan::Client.new(host: 'localhost', username: 'root')
# Automatically detects MySQL version and uses appropriate driver
```

### Manual Driver Selection
```ruby
client = Gratan::Client.new(
  host: 'localhost',
  username: 'root',
  driver_class: Gratan::Driver::MySQL8
)
# Forces use of MySQL8 driver regardless of version
```

## Version-Specific Behavior

| Feature | MySQL 5.6 | MySQL 5.7 | MySQL 8.0 |
|---------|-----------|-----------|-----------|
| SHOW CREATE USER | ❌ | ✅ | ✅ |
| SET PASSWORD | ✅ | ✅ | ❌ |
| ALTER USER | ❌ | ❌ | ✅ |
| PASSWORD() function | ✅ | ✅ | ❌ |
| IDENTIFIED BY in GRANT | ✅ | ✅ | ⚠️ Deprecated |

## Testing

### Test Coverage
- **Unit Tests**: 10 tests for driver factory functionality
- **Integration Tests**: 6 tests for client and exporter interaction
- **All tests passing**: ✅ 16/16

### Test Files
1. `spec/misc/driver_factory_spec.rb` - Driver factory unit tests
2. `spec/misc/driver_integration_spec.rb` - Integration tests

## Backward Compatibility

✅ **100% Backward Compatible**

- Existing code works without modifications
- Options flow through to driver factory
- Default behavior unchanged (auto-detection)
- `use_show_create_user` option still respected

## Benefits

1. **Clean Separation**: Version-specific code is isolated
2. **Easy Extension**: Add new MySQL versions by creating new driver classes
3. **Maintainability**: Changes to one version don't affect others
4. **Testability**: Each driver can be tested independently
5. **Flexibility**: Manual override available when needed

## Migration Path

No migration needed! The change is transparent to existing users.

Optional: Users can explicitly specify driver class if they need specific behavior:
```ruby
options = {driver_class: Gratan::Driver::MySQL8}
```

## Future Enhancements

1. Add support for MySQL 8.1+ features
2. Add MariaDB-specific driver if needed
3. Add Percona-specific driver if needed
4. Cache version detection to avoid repeated queries

## Documentation

- `DRIVER_ARCHITECTURE.md`: Detailed driver architecture documentation
- Inline code comments in driver classes
- RSpec test examples showing usage patterns
