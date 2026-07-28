FROM node:22-alpine

WORKDIR /app

RUN npm install -g npm@latest

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

USER node

CMD ["node", "index.js"]
