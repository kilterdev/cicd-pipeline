FROM node:20.19.5
WORKDIR /opt
ADD . /opt
RUN npm install

CMD ["run", "start"]
ENTRYPOINT npm
