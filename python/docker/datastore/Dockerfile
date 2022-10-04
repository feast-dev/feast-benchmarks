FROM python:3.9

RUN pip3 install 'feast[gcp]==0.25.1'

COPY feature_repos/datastore feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
