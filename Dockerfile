FROM python:3.9

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
#RUN cp /usr/local/lib/python3.9/site-packages/bosch_thermostat_client/db/nsc_icom_gateway/040713.json /usr/local/lib/python3.9/site-packages/bosch_thermostat_client/db/nsc_icom_gateway/040802.json
#RUN sed -i 's/04.07.13/04.08.02/g' /usr/local/lib/python3.9/site-packages/bosch_thermostat_client/db/nsc_icom_gateway/040802.json
#RUN cat /usr/local/lib/python3.9/site-packages/bosch_thermostat_client/db/nsc_icom_gateway/040802.json|grep version

COPY . .

CMD [ "./run.sh" ]
