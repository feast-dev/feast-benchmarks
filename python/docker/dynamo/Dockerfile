FROM python:3.9

RUN pip3 install 'feast[aws]==0.17.0'
# Remove after feast 0.18 comes out
RUN pip3 install 'git+https://github.com/feast-dev/feast.git@57a97d8e207e38876901b9a6b1d6e0f7cc6ce43d#subdirectory=sdk/python'

COPY feature_repos/dynamo feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
