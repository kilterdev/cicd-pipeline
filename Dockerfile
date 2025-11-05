FROM --platform=linux/arm64 node:trixie
WORKDIR /opt
ADD . /opt
RUN npm install
ENTRYPOINT npm run start
