FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ADD . /

RUN apt update && \
    apt install curl wget unzip -y && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i google-chrome-stable_current_amd64.deb || apt-get install -fy && \
    CHROMEDRIVER_VERSION=$(curl -sS "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_114") && \
    wget https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip && \
    unzip chromedriver_linux64.zip -d /usr/bin && \
    chmod +x /usr/bin/chromedriver

RUN apt install python3-launchpadlib python3.11-venv -y && \
    python3.11 -m venv env && \
    . env/bin/activate && \
    python3.11 -m pip install -r requirements.txt

RUN apt install --no-install-recommends software-properties-common dirmngr gpg-agent default-jre default-jdk -y && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" -y && \
    apt install --no-install-recommends r-base -y

# Install R packages via r2u (https://eddelbuettel.github.io/r2u/), which
# serves CRAN packages as pre-built debs aligned with the installed R version.
# Replaces the previous c2d4u4.0+ PPA, which was shipping R 4.0/4.1-era
# r-cran-* binaries that broke under R 4.5 (e.g. fs.so undefined symbol
# SETLENGTH, Rcpp headers referencing the removed Rf_findVarInFrame).
RUN wget -qO- https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc \
        | tee /etc/apt/trusted.gpg.d/cranapt_key.asc > /dev/null && \
    echo "deb [arch=amd64] https://r2u.stat.illinois.edu/ubuntu jammy main" \
        > /etc/apt/sources.list.d/cranapt.list && \
    printf 'Package: *\nPin: release o=CRAN-Apt Project\nPin-Priority: 700\n\nPackage: *\nPin: release l=CRAN-Apt Project\nPin-Priority: 700\n' \
        > /etc/apt/preferences.d/99cranapt && \
    apt update && \
    apt install -y build-essential r-base-dev gfortran libblas-dev liblapack-dev && \
    for pkg in $(awk '{ print "r-cran-" tolower($0) }' packages.txt); do \
        apt install -y --no-install-recommends $pkg || echo "Failed to install $pkg"; \
    done && \
    Rscript --vanilla install2.R
