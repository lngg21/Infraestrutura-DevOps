# Estágio 1: Build
FROM node:20-alpine AS builder
WORKDIR /usr/src/app

COPY package*.json tsconfig.json ./
RUN npm ci

COPY src/ ./src
RUN npm run build
RUN npm prune --production

# Estágio 2: Runtime
FROM node:20-alpine AS runner
WORKDIR /usr/src/app
ENV NODE_ENV=production

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/dist ./dist

USER appuser
EXPOSE 3001

CMD ["node", "dist/server.js"]