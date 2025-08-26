# Step 1: Use an official Node.js image for the build stage
FROM node:16 AS build

# Step 2: Set the working directory inside the container
WORKDIR /app

# Step 3: Copy package.json and package-lock.json to the container
COPY package.json package-lock.json ./

# Step 4: Install dependencies
RUN npm install

# Step 5: Copy the rest of the application code
COPY . .

# Step 6: Build the React app for production
RUN npm run build

# Step 7: Use Nginx to serve the built React app
FROM nginx:alpine

# Step 8: Copy the build output from the build stage to the Nginx server folder
COPY --from=build /app/build /usr/share/nginx/html

# Step 9: Copy custom nginx.conf to the container (You need to add nginx.conf)
COPY nginx.conf /etc/nginx/nginx.conf

# Step 10: Expose the port the app will run on (default HTTP port)
EXPOSE 80

# Step 11: Start Nginx to serve the app
CMD ["nginx", "-g", "daemon off;"]
