# run-queries
Small bash script to run MySQL queries on over SSH and generate CSV files. Useful for QA where queries need to be run repeatedly and CSV files handed off, to be imported elsewhere or easily opened in Excel or another spreadsheet application.

## Configuration

`mv config.example.sh config.sh` 

Fill in all login information:

* Path to SSH private key
* SSH username
* SSH host
* MySQL/MariaDB username
* MySQL/MariaDB password
* MySQL/MariaDB host (usually 127.0.0.1 or localhost)
* MySQL/MariaDB database name

*This script only works with SSH private keys.*

## Usage

Add `.sql` files to the `sql/` directory.

`./run-query.sh`

The script will list all available queries. Enter which query to run by number. After running the query, a timestamped CSV will be in `csv/` and a corresponding TSV in `tsv/`.

## Known Issues

* This script will break if double quotes or backticks are used in `.sql` files.
* Depending on data being fetched, the script may not generate a valid CSV. If so, try the TSV or adjust the query as needed.

