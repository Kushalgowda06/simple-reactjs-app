# 1. Build stage: build your React app using Node.js
FROM node:20 AS build

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy rest of the source code and build the app
COPY . .
RUN npm run build

# 2. Production stage: serve built files with Nginx
FROM nginx:alpine

# Copy built files from previous stage to nginx web directory
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80 for the web server
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
