# ============================================
# Stage 1: Install dependencies & build
# ============================================
FROM oven/bun:1-alpine AS build

WORKDIR /app

# Copy Vue source from frontend_dukkan/
COPY frontend_dukkan/package.json frontend_dukkan/bun.lock* ./
RUN bun install --frozen-lockfile

COPY frontend_dukkan/ .

ARG VITE_API_BASE_URL=https://api.haritna.net
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

RUN bun run build:web

# ============================================
# Stage 2: Production
# ============================================
FROM oven/bun:1-alpine AS production

WORKDIR /app

# Copy built output and server
COPY --from=build /app/dist ./dist
COPY --from=build /app/server.ts ./server.ts
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["bun", "run", "server.ts"]
