FROM node:22.21.1-trixie
WORKDIR /opt
ADD . /opt
RUN npm install
ENTRYPOINT npm run start
