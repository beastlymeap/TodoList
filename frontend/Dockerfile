# Stage 1: build the React bundle
FROM node:20-alpine AS build
WORKDIR /app
COPY app/package*.json ./
RUN npm install
COPY app/ .
RUN npm run build

# Stage 2: Python runtime that serves static files and proxies /api/* with IAM auth
FROM python:3.12-slim
WORKDIR /app

COPY server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server/server.py .
COPY --from=build /app/dist ./dist

ENV PORT=8080
ENV STATIC_DIR=dist
EXPOSE 8080

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 server:app
