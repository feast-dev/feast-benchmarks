FROM python:3.9

RUN pip3 install 'feast[cassandra]==0.26'

COPY feature_repos/cassandra feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
