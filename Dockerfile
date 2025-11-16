FROM node:20.19.5
WORKDIR /opt
ADD . /opt
RUN npm install

EXPOSE 3000
ENTRYPOINT ["npm"]
CMD ["run", "start"]
