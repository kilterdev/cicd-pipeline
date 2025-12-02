FROM node:latest
WORKDIR /opt

COPY . /opt
RUN npm install

HEALTHCHECK \
	--interval=5s \
	--timeout=3s\
	--retries=20 \
	CMD curl -f http://localhost:3000 || exit 1

EXPOSE 3000
ENTRYPOINT ["npm"]
CMD ["run", "start"]
