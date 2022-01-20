FROM python:3.9

RUN pip3 install 'feast[redis]==0.17.0'
# RUN pip3 install 'git+https://github.com/feast-dev/feast.git@1b98ec94e3573991627d561d6d207126a40a21cf#subdirectory=sdk/python'
RUN pip3 install 'git+https://github.com/feast-dev/feast.git@master#subdirectory=sdk/python'


COPY feature_repos/redis feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
