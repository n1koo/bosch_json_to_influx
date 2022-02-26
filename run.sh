#!/bin/bash

set -e

for name in BOSCH_IP BOSCH_TOKEN BOSCH_PASSWORD INFLUX_DB_HOST INFLUX_DB_DATABASE INFLUX_DB_USER INFLUX_DB_PASSWORD PUMP_NAME; do
    if [[ -z "${!name}" ]]; then
        echo "Variable $name not set!"
        exit 1
    fi
done

echo "HC"
for i in {1..2}; do
    echo "[" >>hc$i.json
    bosch_cli query -p /heatingCircuits/hc$i/currentRoomSetpoint --host $BOSCH_IP --protocol HTTP --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD >>hc$i.json
    echo "," >>hc$i.json
    bosch_cli query -p /heatingCircuits/hc$i/actualSupplyTemperature --host $BOSCH_IP --protocol HTTP --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD >>hc$i.json
    echo "," >>hc$i.json
    bosch_cli query -p /heatingCircuits/hc$i/supplyTemperatureSetpoint --host $BOSCH_IP --protocol HTTP --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD >>hc$i.json
    echo "]" >>hc$i.json
    python3 ./bosch_json_to_influx.py --influx_db_host $INFLUX_DB_HOST --influx_db_database $INFLUX_DB_DATABASE --influx_db_user $INFLUX_DB_USER --influx_db_password $INFLUX_DB_PASSWORD --pump_name $PUMP_NAME --input_json_file hc$i.json
done

echo "Sensors"
bosch_cli scan -s SENSORS --host $BOSCH_IP --protocol HTTP --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD -o sensors.json
python3 ./bosch_json_to_influx.py --influx_db_host $INFLUX_DB_HOST --influx_db_database $INFLUX_DB_DATABASE --influx_db_user $INFLUX_DB_USER --influx_db_password $INFLUX_DB_PASSWORD --pump_name $PUMP_NAME --input_json_file sensors.json
echo "DHW"
bosch_cli scan -s dhw --host $BOSCH_IP --protocol HTTP --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD -o dhw.json
python3 ./bosch_json_to_influx.py --influx_db_host $INFLUX_DB_HOST --influx_db_database $INFLUX_DB_DATABASE --influx_db_user $INFLUX_DB_USER --influx_db_password $INFLUX_DB_PASSWORD --pump_name $PUMP_NAME --input_json_file dhw.json
