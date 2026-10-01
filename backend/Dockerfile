# Paketlotse Backend – schlankes Node-22-Image, SQLite-Datei im Volume /data
FROM node:22-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build && npm prune --omit=dev

FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production DATABASE_PATH=/data/paketlotse.sqlite PORT=8787
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
VOLUME ["/data"]
EXPOSE 8787
USER node
CMD ["node", "--disable-warning=ExperimentalWarning", "dist/index.js"]
