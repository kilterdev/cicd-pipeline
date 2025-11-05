FROM node:7.8.0
WORKDIR /opt
ADD . /opt
RUN npm install

CMD ["run", "start"]
ENTRYPOINT npm
