# Bosch heat pump data to influx db

Scrappy script to pull data from my Bosch 7000i heat pumps and dump it to influx

Leverages [bosch-thermostat-client-python](https://github.com/bosch-thermostat/bosch-thermostat-client-python) for scraping data and then mutates it from json to valid influx format