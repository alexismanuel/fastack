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

.PHONY: network
network:
	@ docker network create $(NETWORK) 1> /dev/null 2>&1 || true

.PHONY: postgres
postgres: network
	@ docker run -it --rm -d \
	--network $(NETWORK) \
	--publish $(POSTGRES_PORT):$(POSTGRES_PORT) \
	--env POSTGRES_USER=$(POSTGRES_USER) \
	--env POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
	-v $(PWD)/postgres/scripts:/docker-entrypoint-initdb.d \
	--name postgres \
	$(POSTGRES_IMAGE)

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

.PHONY: psql
psql:
	PGPASSWORD=$(POSTGRES_PASSWORD) psql -h localhost -U $(POSTGRES_USER) -p $(POSTGRES_PORT) -d postgres

.PHONY: mongoshell
mongoshell:
	docker exec -it mongo mongo

.PHONY: stop
stop:
	@ docker container kill postgres mongo || true
