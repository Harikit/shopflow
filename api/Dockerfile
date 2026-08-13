# -----------------------------
# Build stage
# -----------------------------
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev


# -----------------------------
# Production stage
# -----------------------------
FROM node:22-alpine

WORKDIR /app

RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm \
    /usr/local/bin/npx

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY . .

EXPOSE 3000

USER node

CMD ["node", "index.js"]
