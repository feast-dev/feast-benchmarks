FROM python:3.9

RUN pip3 install 'feast[gcp]==0.17.0'
# Remove after feast 0.18 comes out
RUN pip3 install 'git+https://github.com/feast-dev/feast.git@9f2c6d6168bac1b11be2c76c6b266a7444fc11c7#subdirectory=sdk/python'


COPY feature_repos/datastore feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
