# NCATS Orchestrator :notes: :musical_note: #

This is a simple [`docker-compose`](https://docs.docker.com/compose/)
project that orchestrates the running of the following Docker
containers: 
* [gatherer](https://github.com/dhs-ncats/gatherer)
* [scanner](https://github.com/dhs-ncats/scanner)
* [saver](https://github.com/dhs-ncats/saver)
* [pshtt_reporter](https://github.com/dhs-ncats/pshtt-reporter)
* [trustymail_reporter](https://github.com/dhs-ncats/trustymail-reporter)

## Setup ##
Before attempting to run this project, you must create a `secrets`
directory and several files inside it that contain credentials for the
various Docker containers to use.  These files are:
* `secrets/cyhy_read_creds.yml` - a YML file containing credentials to
  read from the Cyber Hygiene database
* `secrets/pshtt_write_creds.yml` - a YML file containing credentials
  to write to the pshtt database
* `secrets/trustymail_write_creds.yml` - a YML file containing
  credentials to write to the trustymail database
* `secrets/sslyze_write_creds.yml` - a YML file containing credentials
  to write to the sslyze database
* `secrets/aws/config` - [an ini format file containing the AWS
  configuration](http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)
* `secrets/aws/credentials` - [an ini format file containing the AWS
  credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html)

As an example, `secrets/cyhy_read_creds.yml` should look something
like this:
```
version: '1'

database:
  name: cyhy
  uri: mongodb://<DB_USERNAME>:<DB_PASSWORD>@<DB_HOST>:<DB_PORT>/cyhy
```
