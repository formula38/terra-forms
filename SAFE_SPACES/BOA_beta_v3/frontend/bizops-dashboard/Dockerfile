# Stage 1: Build the Angular application
FROM node:18 as build

WORKDIR /app

# Copy package.json and package-lock.json
COPY frontend/bizops-dashboard/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY frontend/bizops-dashboard/ .

# Build the application
RUN npm run build -- --configuration production

# Stage 2: Serve the application from a lightweight Nginx server
FROM nginx:alpine

# Copy the build output to replace the default Nginx content.
COPY --from=build /app/dist/bizops-dashboard/browser /usr/share/nginx/html

# Expose port 80
EXPOSE 80
