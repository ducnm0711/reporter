# build
FROM golang:1.18-bullseye AS build
WORKDIR /go/src/${owner:-github.com/IzakMarais}/reporter
RUN apt-get update && apt-get install -y make git
ADD . .
RUN make build

# create image
FROM debian:bullseye
COPY util/texlive.profile /

RUN PACKAGES="wget libswitch-perl" \
  && apt-get update \
  && apt-get install -y -qq $PACKAGES --no-install-recommends \
  && apt-get install -y ca-certificates --no-install-recommends 

RUN wget -qO- "https://yihui.org/tinytex/install-bin-unix.sh" | sh \
    && mv ~/.TinyTeX /opt/TinyTeX

RUN /opt/TinyTeX/bin/x86_64-linux/tlmgr option sys_bin /usr/local/bin \
    && /opt/TinyTeX/bin/x86_64-linux/tlmgr path add

RUN tlmgr path add \
    && chown -R root:staff /opt/TinyTeX \
    && chmod -R g+w /opt/TinyTeX \
    && chmod -R g+wx /opt/TinyTeX/bin \
    && tlmgr install epstopdf-pkg \
    && apt-get remove --purge -qq $PACKAGES \
    && apt-get autoremove --purge -qq \
    && rm -rf /var/lib/apt/lists/*


COPY --from=build /go/bin/grafana-reporter /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/grafana-reporter" ]