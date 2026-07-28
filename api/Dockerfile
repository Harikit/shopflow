FROM node:20-alpine

WORKDIR /app

RUN npm install -g npm@10.7.0

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

USER node

CMD ["node", "index.js"]
