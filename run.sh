#!/bin/bash

set -e

if [ -f .env ]; then 
  export $(cat .env |grep -v "#" | xargs)
fi

for name in BOSCH_IP BOSCH_TOKEN BOSCH_PASSWORD INFLUX_DB_HOST INFLUX_DB_DATABASE INFLUX_DB_USER INFLUX_DB_PASSWORD PUMP_NAME; do
    if [[ -z "${!name}" ]]; then
        echo "Variable $name not set!"
        exit 1
    fi
done

END=1
DWH=false
if [ "$PUMP_NAME" = "AWE17" ]; then
    END=2
    DWH=true
fi

echo "HC"
for i in $(seq 1 $END); do
    echo "[" >>hc$i.json
   # uv run bosch_cli query -p /heatingCircuits/hc$i/currentRoomSetpoint --host $BOSCH_IP --protocol HTTP --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD
    uv run bosch_cli query -p /heatingCircuits/hc$i/currentRoomSetpoint --host $BOSCH_IP --protocol $PROTOCOL --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD >>hc$i.json
    echo "," >>hc$i.json
    uv run bosch_cli query -p /heatingCircuits/hc$i/actualSupplyTemperature --host $BOSCH_IP --protocol $PROTOCOL --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD >>hc$i.json
    echo "," >>hc$i.json
    uv run bosch_cli query -p /heatingCircuits/hc$i/supplyTemperatureSetpoint --host $BOSCH_IP --protocol $PROTOCOL --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD >>hc$i.json
    echo "]" >>hc$i.json
    uv run bosch_json_to_influx.py --influx_db_host $INFLUX_DB_HOST --influx_db_database $INFLUX_DB_DATABASE --influx_db_user $INFLUX_DB_USER --influx_db_password $INFLUX_DB_PASSWORD --pump_name $PUMP_NAME --input_json_file hc$i.json
done

echo "Sensors"
uv run bosch_cli scan -s SENSORS --host $BOSCH_IP --protocol $PROTOCOL --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD -o sensors.json
uv run bosch_json_to_influx.py --influx_db_host $INFLUX_DB_HOST --influx_db_database $INFLUX_DB_DATABASE --influx_db_user $INFLUX_DB_USER --influx_db_password $INFLUX_DB_PASSWORD --pump_name $PUMP_NAME --input_json_file sensors.json

if $DWH; then
    echo "DHW"
    uv run bosch_cli scan -s dhw --host $BOSCH_IP --protocol $PROTOCOL --device IVT --token $BOSCH_TOKEN --password $BOSCH_PASSWORD -o dhw.json
    uv run bosch_json_to_influx.py --influx_db_host $INFLUX_DB_HOST --influx_db_database $INFLUX_DB_DATABASE --influx_db_user $INFLUX_DB_USER --influx_db_password $INFLUX_DB_PASSWORD --pump_name $PUMP_NAME --input_json_file dhw.json
fi
