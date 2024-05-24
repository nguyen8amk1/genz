FROM node:14-alpine

WORKDIR /api 

COPY package.json .

RUN npm install # build time command 

COPY . . 

EXPOSE 8000

CMD ["npm", "start"]
