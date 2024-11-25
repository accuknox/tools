FROM accuknox/accuknox-container-scan:latest
WORKDIR /home/ak
RUN apk add jq curl bash python3

RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz

# Installing the package
RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
    && /usr/local/gcloud/google-cloud-sdk/install.sh

COPY imagescan.sh .
RUN chmod +x /home/ak/imagescan.sh
ENV PATH=$PATH:/usr/local/gcloud/google-cloud-sdk/bin

ENTRYPOINT ["/home/ak/imagescan.sh"]
