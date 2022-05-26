FROM python:3.8

RUN pip3 install 'feast[redis]==0.21.2'
RUN pip3 install cffi
# Remove this after 0.22 ships
RUN pip3 install 'git+https://github.com/tsotnet/feast.git@caa0cf6c28c771efc8d23f70474cced43a722bb2'

COPY feature_repos/redis feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
