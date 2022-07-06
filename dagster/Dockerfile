FROM python:3.7-slim

RUN \
    apt-get -y update \
    && apt install -y postgresql-client cron \
    && rm -rf /var/lib/apt/lists/*

RUN \
    pip install --upgrade pip==20.2.4 \
    && pip install -U setuptools

WORKDIR /opt/dagster/app

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

COPY dagster.yaml /opt/dagster/dagster_home/

COPY repository.py workspace.yaml /opt/dagster/app/

EXPOSE 3000

CMD ["bash"]