FROM python:3.7-stretch

RUN \
    apt-get -y update \
    && apt install -y \
    && rm -rf /var/lib/apt/lists/*

RUN \
    pip install --upgrade pip==20.2.4 \
    && pip install -U setuptools

ENV ROOT_APP_DIR /home/src/dbt

WORKDIR $ROOT_APP_DIR

COPY ./requirements.txt .

RUN pip install -r requirements.txt

ADD ./project $ROOT_APP_DIR

CMD ["bash"]