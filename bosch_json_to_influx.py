from influxdb import InfluxDBClient
import json
import os
import sys
import argparse
import logging
import coloredlogs
from datetime import datetime

log = logging.getLogger("bosch_json_to_influx")
LOGLEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()
logging.basicConfig(
    format='%(asctime)s %(levelname)-8s %(message)s',
    level=LOGLEVEL,
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[logging.StreamHandler(sys.stdout)])
coloredlogs.install(isatty=True, level=LOGLEVEL)


def _parse_args():
    # parse command line arguments
    parser = argparse.ArgumentParser(
        description='Bridge between Bosch sensor output json and InfluxDB')
    parser.add_argument(
        '--input_json_file', help='Location of the file to be parsed for data', default='sensor_scan.json', type=str)
    parser.add_argument('--influx_db_host', help='influx db host address',
                        default='127.0.0.1', type=str)
    parser.add_argument('--influx_db_port', help='influx db host port',
                        default=8086, type=int)
    parser.add_argument('--influx_db_database', help='influx db database name (eg default)',
                        default="bosch", type=str)
    parser.add_argument('--influx_db_user', help='influx db user',
                        default="bosch", type=str)
    parser.add_argument('--influx_db_password', help='influx db password',
                        default="bosch", type=str)
    parser.add_argument('--dry-run', help='Output to console rather than sending to influx',
                        default=False, type=bool)
    parser.add_argument('--pump_name', help='Optional heat pump name to use as tag', type=str)
    args = parser.parse_args()
    return args


def _parse_json(json_file: str, pump_name) -> dict:
    parsed_data = []
    with open(json_file, 'r') as input_json:
        data = json.load(input_json)
        timestamp = datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ")
        if pump_name:
            tags = {"pump_name": pump_name}
        else:
            tags = {}

        for entry in data:
            if not entry:
                continue
            # For some reason these are lists with single entry
            entry = entry[0]
            if entry['type'] == "floatValue" or entry['type'] == "stringValue":
                # Change / to _ and lowercase + remove leading ?
                # eg. /heatSources/numberOfStarts -> heatsources_numberofstarts
                measurement_name = entry['id'][1:].replace("/", "_").lower()

                parsed_entry = {"measurement": measurement_name,
                                "tags": tags,
                                "time": timestamp,
                                "fields": {
                                    "value": entry['value']},
                                }
                parsed_data.append(parsed_entry)
            else:
                log.warning(f"Skipped {entry}")
    # validate
    _ = json.JSONEncoder().encode(parsed_data)
    return parsed_data


def main():
    log.info("Starting Bosch json to Influx script")
    args = _parse_args()
    data = _parse_json(args.input_json_file, args.pump_name)
    log.debug(data)

    influx_client = InfluxDBClient(host=args.influx_db_host, port=args.influx_db_port, database=args.influx_db_database,
                                   username=args.influx_db_user, password=args.influx_db_password, timeout=3)
    if args.dry_run:
        log.info(f"Would try to output {data}")
    else:
        influx_client.write_points(data)


if __name__ == '__main__':
    main()
