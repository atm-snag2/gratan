# Gratan

[![Gem Version](https://badge.fury.io/rb/gratan.svg)](http://badge.fury.io/rb/gratan)
[![CI](https://github.com/codenize-tools/gratan/workflows/CI/badge.svg)](https://github.com/codenize-tools/gratan/actions?query=workflow%3ACI)
[![Dev Container](https://github.com/codenize-tools/gratan/workflows/Dev%20Container%20CI/badge.svg)](https://github.com/codenize-tools/gratan/actions?query=workflow%3A%22Dev+Container+CI%22)

Gratan is a tool to manage MySQL permissions.

It defines the state of MySQL permissions using Ruby DSL, and updates permissions according to DSL.

## Notice

* `>= 0.3.0`
  * Support template
* `>= 0.3.1`
  * Fix `<secret>` password

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gratan'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gratan

## Usage

```sh
gratan -e -o Grantfile
vi Grantfile
gratan -a --dry-run
gratan -a
```

## Help

```sh
Usage: gratan [options]
        --host HOST
        --port PORT
        --socket SOCKET
        --username USERNAME
        --password PASSWORD
        --database DATABASE
    -a, --apply
    -f, --file FILE
        --dry-run
    -e, --export
        --with-identifier
        --split
        --chunk-by-user
    -o, --output FILE
        --ignore-user REGEXP
        --target-user REGEXP
        --ignore-object REGEXP
        --enable-expired
        --ignore-not-exist
        --ignore-password-secret
        --skip-disable-log-bin
        --override-sql-mode
        --use-show-create-user
        --no-color
        --debug
        --auto-identify OUTPUT
        --csv-identify CSV
        --mysql2-options JSON
    -h, --help
```

A default connection to a database can be established by setting the following environment variables:
- `GRATAN_DB_HOST`: database host
- `GRATAN_DB_PORT`: database port
- `GRATAN_DB_SOCKET`: database socket
- `GRATAN_DB_DATABASE`: database database name
- `GRATAN_DB_USERNAME`: database user
- `GRATAN_DB_PASSWORD`: database password

## Grantfile example

```ruby
require 'other/grantfile'

user "scott", "%" do
  on "*.*" do
    grant "USAGE"
  end

  on "test.*", expired: '2014/10/08', identified: "PASSWORD '*ABCDEF'" do
    grant "SELECT"
    grant "INSERT"
  end

  on /^foo\.prefix_/ do
    grant "SELECT"
    grant "INSERT"
  end
end

user "scott", ["localhost", "192.168.%"], expired: '2014/10/10' do
  on "*.*", with: 'GRANT OPTION' do
    grant "ALL PRIVILEGES"
  end
end
```

### Use template

```ruby
template 'all db template' do
  on '*.*' do
    grant 'SELECT'
  end
end

template 'test db template' do
  grant context.default

  context.extra.each do |priv|
    grant priv
  end
end

user 'scott', 'localhost', identified: 'tiger' do
  include_template 'all db template'

  on 'test.*' do
    context.default = 'SELECT'
    include_template 'test db template', extra: ['INSERT', 'UPDATE']
  end
end
```

## Run tests

### Using Dev Container (Recommended)

```sh
# Inside the dev container
bundle exec rspec

# Test with MySQL 5.7
MYSQL57=1 bundle exec rspec
```

### Local Development

```sh
bundle install
# Start MySQL services using dev container's docker-compose
docker compose -f .devcontainer/docker-compose.yml up -d mysql56 mysql57
bundle exec rake
# MYSQL57=1 bundle exec rake
```

## Development with Dev Containers

Gratan supports [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) for a streamlined development setup.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Quick Start

1. Clone the repository
2. Open in VS Code
3. When prompted, click "Reopen in Container" (or run command: `Dev Containers: Reopen in Container`)
4. Wait for the container to build (~5 minutes first time, <2 minutes thereafter)
5. Run tests: `bundle exec rspec`

The dev container automatically provides:
- Ruby environment matching project requirements
- MySQL 5.6 and 5.7 test instances (ports 14406, 14407)
- Pre-configured VS Code extensions (Ruby LSP, RSpec test adapter)
- Persistent gem cache across container rebuilds

For detailed setup instructions and troubleshooting, see [Dev Container Quickstart Guide](specs/001-devcontainer/quickstart.md).

## Similar tools
* [Codenize.tools](http://codenize.tools/)

## What does "Gratan" mean?

[![](http://i.gyazo.com/c37d934ba0a61f760603ce4c56401e60.png)](https://www.google.com/search?q=gratin&tbm=isch)
