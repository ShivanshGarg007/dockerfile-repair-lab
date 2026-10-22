# Use a supported, lightweight Node.js LTS image.
FROM node:22-alpine

# Set the app root before copying files so all paths are predictable.
WORKDIR /app

# Install dependencies in a separate layer; Docker can reuse this layer
# whenever only application source files change.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy only files needed at runtime. Keep src because app.js imports it.
COPY app.js ./
COPY src ./src
COPY public ./public

ENV NODE_ENV=production
EXPOSE 8080

# Use the package's declared start script.
CMD ["npm", "start"]
