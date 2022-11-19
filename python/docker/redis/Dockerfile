FROM python:3.9

RUN pip3 install 'feast[redis]==0.26'
RUN pip3 install cffi

COPY feature_repos/redis feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
