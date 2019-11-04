# activerecord_bulkoperation
AR 4.2, 5.0, 5.1 and 5.2 are supported
## Database Driver support
currently only oracle_enhanced is supported

## Install

## Test
```bash
# You can use the env variables: DB_USER, DB_PASSWORD and DB_CONNECTION to specify the DB connection.
# A running ORACLE DB is neccessary to execute the tests.
rake test:oracle_enhanced
```