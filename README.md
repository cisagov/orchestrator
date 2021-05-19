# Orchestrator #

[![GitHub Build Status](https://github.com/cisagov/orchestrator/workflows/build/badge.svg)](https://github.com/cisagov/orchestrator/actions)

This is a simple [`docker-compose`](https://docs.docker.com/compose/)
project that orchestrates the running of the following Docker
containers:

* [gatherer](https://github.com/cisagov/gatherer)
* [scanner](https://github.com/cisagov/scanner)
* [saver](https://github.com/cisagov/saver)
* [pshtt_reporter](https://github.com/cisagov/pshtt_reporter)
* [trustymail_reporter](https://github.com/cisagov/trustymail_reporter)

## Setup ##

Before attempting to run this project, you must create a `secrets`
directory and several files inside it that contain credentials for the
various Docker containers to use.  These files are:

* `secrets/cyhy_read_creds.yml` - a YAML file containing credentials to
  read from the Cyber Hygiene database
* `secrets/scan_read_creds.yml` - a YAML file containing credentials
  to read the database containing the pshtt, trustymail, and sslyze
  scan results
* `secrets/scan_write_creds.yml` - a YAML file containing credentials
  to write to the database containing the pshtt, trustymail, and
  sslyze scan results
* `secrets/aws_config` - [an ini format file containing the AWS
  configuration](http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)

As an example, `secrets/cyhy_read_creds.yml` should look something
like this:

```yaml
version: '1'

database:
  name: cyhy
  uri: mongodb://<DB_USERNAME>:<DB_PASSWORD>@<DB_HOST>:<DB_PORT>/cyhy
```

## Contributing ##

We welcome contributions!  Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
