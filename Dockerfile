FROM node:latest
WORKDIR /opt

COPY . /opt
RUN npm install

EXPOSE 3000
ENTRYPOINT ["npm"]
CMD ["run", "start"]
