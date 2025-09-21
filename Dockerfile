# Use official lightweight Node.js image
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy package files first (for caching layer)
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy the app source
COPY . .

# Expose app port
EXPOSE 3000

# Start the app
CMD ["npm", "start"]
