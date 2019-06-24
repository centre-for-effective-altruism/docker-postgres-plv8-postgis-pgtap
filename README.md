# Postgres/PLV8/Postgis/pg_tap

A Docker image for Postgres 9.6 which combines:
- The [PLV8](https://github.com/plv8/plv8) scripting language (Javascript functions in Postgres)
- [PostGIS](https://postgis.net/) geospatial tools
- Theory's [pg_tap](https://github.com/theory/pgtap) utility for database testing

Comes in two flavours, `:base` which is just PLV8 and PostGIS, and `:testing` which also includes pg_tap.

## Building

To build the `base` image:

```sh
docker build --target=base -t centreforea/postgres-plv8-postgis:plv8 .
```

To build the `testing` image:

```sh
docker build --target=testing -t centreforea/postgres-plv8-postgis:testing .
```

## Usage

Run with the following command:

```
docker run --name postgres -v $PATH_TO_DATA_DIR:/var/lib/postgresql/data -p 5432:5432 centreforea/postgres-plv8-postgis:testing
```

**Flags explained:**

- `--name postgres` just makes it easier to reference the image (e.g. with `docker start postgres`)
- `-v $PATH_TO_DATA_DIR:/var/lib/postgresql/data` for data persistence
- `-p 5432:5432` expose Postgres to local applications on port 5432

## Connecting

This image uses the base Ubuntu [Postgres Docker image](https://hub.docker.com/_/postgres), and so inherits its default settings. In particular, you'll need to explicitly connect over localhost (this is different to the default behaviour of e.g. `brew` Postgres, which accepts connections without a hostname):

**Shell:**

```sh
createdb -h localhost -U postgres mydbname
psql -h localhost -U postgres mydbname
dropdb -h localhost -U postgres mydbname
```

**Connection string:**

```
postgres://postgres@localhost/mydbname
```

If you want to use the extensions in your database, you'll need to enable them with `CREATE EXTENSION`:

```sh
# psql
db=# CREATE EXTENSION plv8;
db=# CREATE EXTENSION postgis;
```

## Prior art

Heavily inspired by [Geodan's attempt at the same](https://github.com/Geodan/docker-postgres-plv8-postgis) (which unfortunately doesn't build for the latest version of Postgres 9.6) and of course the [Docker PLV8](https://hub.docker.com/r/clkao/postgres-plv8/) project.
