# Step 1: Use an official Node.js image as a base image
FROM node:16 AS build

# Step 2: Set the working directory inside the container
WORKDIR /app

# Step 3: Copy package.json and package-lock.json to the container
COPY package.json package-lock.json ./

# Step 4: Install dependencies
RUN npm install

# Step 5: Copy the rest of the app's code into the container
COPY . .

# Step 6: Build the React app for production
RUN npm run build

# Step 7: Use Nginx to serve the app
FROM nginx:alpine

# Step 8: Copy the build folder from the build container to the Nginx container
COPY --from=build /app/build /usr/share/nginx/html

# Step 9: Expose the port the app will run on
EXPOSE 80

# Step 10: Start Nginx
CMD ["nginx", "-g", "daemon off;"]
