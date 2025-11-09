FROM node:20.19.5
WORKDIR /opt
ADD . /opt
RUN npm install

EXPOSE 3000
CMD ["run", "start"]
ENTRYPOINT ["npm"]
