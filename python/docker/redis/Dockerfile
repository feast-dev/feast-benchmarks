FROM python:3.9

ENV COMPILE_GO=True

# Install the Go toolchain
RUN curl https://storage.googleapis.com/golang/go1.16.2.linux-amd64.tar.gz -o go.tar.gz && \
    tar -zxf go.tar.gz && \
    rm -rf go.tar.gz && \
    mv go /go
ENV GOPATH /go
ENV PATH $PATH:/go/bin:$GOPATH/bin

RUN pip3 install 'feast[redis]==0.19.4'
# Remove after feast 0.20 comes out
RUN pip3 install 'git+https://github.com/feast-dev/feast.git@a2ef3755766a7224298f984a2cadb17829b2f3d2#egg=feast[redis]&#subdirectory=sdk/python'

COPY feature_repos/redis feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
