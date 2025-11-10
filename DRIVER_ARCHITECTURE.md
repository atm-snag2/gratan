# Driver Architecture

## Overview

Gratan uses a driver architecture to support different MySQL versions with their version-specific features. The system automatically detects the MySQL version and selects the appropriate driver implementation.

## Driver Classes

### Base Driver (`Gratan::Driver::Base`)

The base driver class contains common MySQL functionality that works across all supported versions. All version-specific drivers inherit from this base class.

### MySQL 5.6 Driver (`Gratan::Driver::MySQL5`)

- Supports MySQL 5.6 and earlier versions
- Does not support `SHOW CREATE USER` command (returns nil)
- Uses `SET PASSWORD` for password management
- Uses `IDENTIFIED BY` in GRANT statements

### MySQL 5.7 Driver (`Gratan::Driver::MySQL57`)

- Supports MySQL 5.7
- Supports `SHOW CREATE USER` command
- Uses `SET PASSWORD` for password management
- Uses `IDENTIFIED BY` in GRANT statements

### MySQL 8.0 Driver (`Gratan::Driver::MySQL8`)

- Supports MySQL 8.0 and later
- Supports `SHOW CREATE USER` command
- Uses `ALTER USER` instead of `SET PASSWORD` (PASSWORD() function removed in MySQL 8)
- Authentication plugin handling for MySQL 8's new authentication system

## Automatic Version Detection

When creating a driver, Gratan automatically detects the MySQL version by executing `SELECT VERSION()` and choosing the appropriate driver:

```ruby
client = Mysql2::Client.new(host: 'localhost', username: 'root')
driver = Gratan::Driver.new(client, {})
# Automatically selects MySQL5, MySQL57, or MySQL8 based on version
```

## Manual Driver Selection

You can explicitly specify which driver to use:

```ruby
options = {
  driver_class: Gratan::Driver::MySQL8
}
driver = Gratan::Driver.new(client, options)
```

## Version-Specific Behavior

### Password Management

- **MySQL 5.6/5.7**: Uses `SET PASSWORD FOR user@host = PASSWORD('password')`
- **MySQL 8.0**: Uses `ALTER USER user@host IDENTIFIED BY 'password'`

### User Authentication

- **MySQL 5.6/5.7**: Uses `IDENTIFIED BY` in GRANT statements
- **MySQL 8.0**: Uses `ALTER USER` for authentication (IDENTIFIED BY in GRANT is deprecated)

### SHOW CREATE USER

- **MySQL 5.6**: Not supported (returns nil)
- **MySQL 5.7/8.0**: Supported for retrieving full user authentication details

## Implementation Notes

The driver architecture uses a factory pattern where `Gratan::Driver.new()` is a factory method that:

1. Detects the MySQL version
2. Instantiates the appropriate driver class
3. Returns a driver instance with version-specific implementations

This design allows for:
- Easy addition of new MySQL version support
- Clean separation of version-specific code
- Backward compatibility with existing code
- Explicit control when needed via the `driver_class` option
