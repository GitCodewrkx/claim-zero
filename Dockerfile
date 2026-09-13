# ----- Stage 1: compile the React application into static files (dist/) -----
# node:22-alpine = small Linux Node image used ONLY for building (not the final runtime).
# Alpine keeps the builder small; the compiled files are copied out in Stage 2.
FROM node:22-alpine AS builder

# Working directory inside the build container. Later COPY/RUN paths are relative to /app.
WORKDIR /app

# Copy dependency manifests first to leverage Docker layer caching.
# If package.json does not change, Docker can reuse the npm install layer.
COPY package*.json ./

# Install dependencies required to compile the application.
RUN npm install

# Copy the full application source into the build context.
# .dockerignore (Lab 1.3) keeps node_modules, dist, and docs out of this copy.
COPY . .

# Produce optimised static assets in /app/dist (HTML/CSS/JS).
# This is the same production build you already proved locally in Stage 0.
RUN npm run build

# ----- Stage 2: serve the compiled assets with nginx -----
# Fresh slim image — no Node, no npm, only a web server.
# Everything above the second FROM is discarded except what you COPY --from=builder.
FROM nginx:alpine

# Replace default nginx web root with the Vite build output from the builder stage.
COPY --from=builder /app/dist /usr/share/nginx/html

# Document that the container listens on HTTP port 80.
# Lab 1.5 maps laptop port 8080 to this container port 80.
EXPOSE 80

# Start nginx in the foreground (required for containers — no background daemon).
CMD ["nginx", "-g", "daemon off;"]