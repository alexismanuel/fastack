PWD=/home/alexismanuel/github/fastack
NETWORK=localbound
POSTGRES_IMAGE=postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
MONGO_IMAGE=mongo:latest
MONGO_PORT=27017
MONGO_USER=mongo
MONGO_PASSWORD=mongo
DAGSTER_PORT=3000
DAGSTER_IMAGE_TAG=localhost/dagster
DAGSTER_HOME=/opt/dagster/dagster_home/
DBT_IMAGE_TAG=localhost/dbt
JUPYTERHUB_IMAGE_TAG=jupyter/minimal-notebook:4d9c9bd9ced0
JUPYTERHUB_PORT=8888
JUPYTERHUB_USER=alexismanuel
METABASE_PORT=12345
METABASE_IMAGE_TAG=metabase/metabase

.PHONY: network
network:
	@ docker network create $(NETWORK) 1> /dev/null 2>&1 || true

.PHONY: postgres
postgres: network
ifeq ($(shell docker images -q postgres 2> /dev/null),)
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--publish $(POSTGRES_PORT):$(POSTGRES_PORT) \
	--env POSTGRES_USER=$(POSTGRES_USER) \
	--env POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
	-v $(PWD)/postgres/scripts:/docker-entrypoint-initdb.d \
	--name postgres \
	$(POSTGRES_IMAGE)
endif

.PHONY: mongo
mongo: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--publish $(MONGO_PORT):$(MONGO_PORT) \
	--env MONGODB_INITDB_ROOT_USERNAME=$(MONGO_USER) \
	--env MONGODB_INITDB_ROOT_PASSWORD=$(MONGO_PASSWORD) \
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
dagster-ui: postgres build-dagster
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--publish $(DAGSTER_PORT):$(DAGSTER_PORT) \
	--env DAGSTER_HOME=$(DAGSTER_HOME) \
	--env INSTANCE_USERNAME=$(POSTGRES_USER) \
	--env INSTANCE_PASSWORD=$(POSTGRES_PASSWORD) \
	--env INSTANCE_HOSTNAME=postgres \
	--env DAGSTER_DB_NAME=dagster \
	--name dagster-ui \
	$(DAGSTER_IMAGE_TAG) dagit -h 0.0.0.0 -p $(DAGSTER_PORT)

.PHONY: dagster-daemon
dagster-daemon: postgres build-dagster
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--env DAGSTER_HOME=$(DAGSTER_HOME) \
	--env INSTANCE_USERNAME=$(POSTGRES_USER) \
	--env INSTANCE_PASSWORD=$(POSTGRES_PASSWORD) \
	--env INSTANCE_HOSTNAME=postgres \
	--env DAGSTER_DB_NAME=dagster \
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
	--env DBT_HOST=postgres \
	--env DBT_USERNAME=$(POSTGRES_USER) \
	--env DBT_PASSWORD=$(POSTGRES_PASSWORD) \
	--env DBT_DBNAME=postgres \
	--env DBT_SCHEMA=cd \
	--env DBT_PROFILES_DIR=/home/src/dbt \
	$(DBT_IMAGE_TAG) bash

.PHONY: jupyterhub
jupyterhub: network
	@ docker run -it --rm -d \
	--name jupyterhub \
	-p $(JUPYTERHUB_PORT):$(JUPYTERHUB_PORT) \
	-v $(PWD)/jupyterhub:/home/$(JUPYTERHUB_USER) \
	-w /home/$(JUPYTERHUB_USER)/ \
	--user root \
	--env NB_USER=$(JUPYTERHUB_USER) \
	--env NB_UID="1000" \
	--env CHOWN_HOME=yes \
	--env CHOWN_HOME_OPTS='-R' \
	$(JUPYTERHUB_IMAGE_TAG)

.PHONY: metabase
metabase: network
	@ docker run -it --rm -d \
	--name metabase \
	-p $(METABASE_PORT):3000 \
	$(METABASE_IMAGE_TAG)

.PHONY: stop
stop:
	@ docker container kill postgres mongo dagster-ui dagster-daemon dbt jupyterhub metabase || true
	cd airbyte && docker-compose down
	@ docker container kill airbyte-worker airbyte-server airbyte-webapp airbyte-db
