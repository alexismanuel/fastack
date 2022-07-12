PWD=/home/alexismanuel/github/fastack
NETWORK=localbound
POSTGRES_IMAGE=postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
MONGO_IMAGE=mongo:latest
MONGO_PORT=27017
DAGSTER_PORT=3000
DAGSTER_IMAGE_TAG=localhost/dagster
DBT_IMAGE_TAG=localhost/dbt
JUPYTERHUB_IMAGE_TAG=jupyter/minimal-notebook:4d9c9bd9ced0
JUPYTERHUB_PORT=8888
JUPYTERHUB_USER=alexismanuel
METABASE_PORT=12345
METABASE_IMAGE_TAG=metabase/metabase
REDPANDA_IMAGE_TAG=docker.redpanda.com/vectorized/redpanda:latest
REDPANDA_PORTS=8081:8081 -p 8082:8082 -p 9092:9092 -p 9644:9644
REDPANDA_START_ARGS=--overprovisioned --smp 1  --memory 1G --reserve-memory 0M --node-id 0 --check=false
MATERIALIZE_IMAGE_TAG=materialize/materialized:v0.26.4
MATERIALIZE_PORT=6875
STREAMLIT_IMAGE_TAG=tomerlevi/streamlit-docker
STREAMLIT_PORT=8501
SUPERSET_IMAGE_TAG=apache/superset
SUPERSET_PORT=8080

.PHONY: network
network:
	@ docker network create $(NETWORK) 1> /dev/null 2>&1 || true

.PHONY: postgres
postgres: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--publish $(POSTGRES_PORT):$(POSTGRES_PORT) \
	--env-file ./postgres/postgres.env \
	-v $(PWD)/postgres/scripts:/docker-entrypoint-initdb.d \
	--name postgres \
	$(POSTGRES_IMAGE)

.PHONY: mongo
mongo: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--publish $(MONGO_PORT):$(MONGO_PORT) \
	--env-file ./mongo/mongo.env \
	-v $(PWD)/mongo/data:/data/db \
	-v $(PWD)/mongo/scripts:/docker-entrypoint-initdb.d \
	--name mongo \
	$(MONGO_IMAGE)

.PHONY: build-dagster
build-dagster:
	@ docker build \
	--tag $(DAGSTER_IMAGE_TAG) \
	./dagster

.PHONY: dagster-ui
dagster-ui: build-dagster
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--publish $(DAGSTER_PORT):$(DAGSTER_PORT) \
	--env-file ./dagster/dagster-ui.env \
	--name dagster-ui \
	$(DAGSTER_IMAGE_TAG) dagit -h 0.0.0.0 -p $(DAGSTER_PORT)

.PHONY: dagster-daemon
dagster-daemon: build-dagster
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--env-file ./dagster/dagster-daemon.env \
	--name dagster-daemon \
	$(DAGSTER_IMAGE_TAG) dagster-daemon run

.PHONY: psql
psql:
	PGPASSWORD=$(POSTGRES_PASSWORD) psql -h localhost -U $(POSTGRES_USER) -p $(POSTGRES_PORT) -d postgres

.PHONY: mongoshell
mongoshell:
	docker exec -it mongo mongo

.PHONY: airbyte
airbyte:
	cd airbyte && docker-compose up -d

.PHONY: build-dbt
build-dbt:
	@ docker build \
	--tag $(DBT_IMAGE_TAG) \
	./dbt

.PHONY: dbt
dbt: network build-dbt
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--name dbt \
	--env-file ./dbt/dbt.env \
	$(DBT_IMAGE_TAG) bash

.PHONY: jupyterhub
jupyterhub: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--name jupyterhub \
	--env-file ./jupyterhub/jupyterhub.env \
	-p $(JUPYTERHUB_PORT):$(JUPYTERHUB_PORT) \
	-v $(PWD)/jupyterhub:/home/$(JUPYTERHUB_USER) \
	-w /home/$(JUPYTERHUB_USER)/ \
	--user root \
	$(JUPYTERHUB_IMAGE_TAG)

.PHONY: metabase
metabase: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--name metabase \
	--env-file ./metabase/metabase.env \
	-p $(METABASE_PORT):3000 \
	$(METABASE_IMAGE_TAG)

.PHONY: redpanda
redpanda: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--name redpanda \
	-p $(REDPANDA_PORTS) \
	$(REDPANDA_IMAGE_TAG) \
	redpanda start $(REDPANDA_START_ARGS)

.PHONY: materialize
materialize: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--name materialize \
	-p $(MATERIALIZE_PORT):$(MATERIALIZE_PORT) \
	$(MATERIALIZE_IMAGE_TAG) --workers 1

.PHONY: streamlit
streamlit: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--name streamlit \
	-p $(STREAMLIT_PORT):$(STREAMLIT_PORT) \
	$(STREAMLIT_IMAGE_TAG) /examples/intro.py

.PHONY: superset
superset: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--name superset \
	-p $(SUPERSET_PORT):8088 \
	$(SUPERSET_IMAGE_TAG)

.PHONY: supersetup
supersetup: network
	@ docker exec -it superset superset fab create-admin \
	--username admin \
	--firstname Superset \
	--lastname Admin \
	--email admin@superset.com \
	--password admin
	@ docker exec -it superset superset db upgrade
	@ docker exec -it superset superset load_examples
	@ docker exec -it superset superset init

.PHONY: stop
stop:
	@ docker container kill postgres mongo dagster-ui dagster-daemon dbt jupyterhub metabase redpanda materialize streamlit superset || true
	cd airbyte && docker-compose down
	@ docker container kill airbyte-worker airbyte-server airbyte-webapp airbyte-db
