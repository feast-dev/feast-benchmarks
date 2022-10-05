FROM python:3.9

# Downloading gcloud package
RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz

# Installing the package
RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh

# Adding the package path to local
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

RUN pip3 install 'feast[gcp]==0.25.1'

COPY feature_repos/datastore feature_repo

WORKDIR feature_repo

ENV FEAST_USAGE=False

CMD feast serve --host "0.0.0.0" --port 6566
