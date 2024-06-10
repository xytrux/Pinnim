# Start from the latest Nim image
FROM nimlang/nim:latest

# Set the working directory in the Docker image
WORKDIR /src

# Copy the current directory contents into the container at /app
COPY . /src

# Install Jester
RUN nimble install jester -y

# Compile the Jester application
RUN nim c -d:release -d:ssl src/main.nim

# Make port 5000 available to the world outside this container
EXPOSE 7777

# Run the app when the container launches
CMD ["./main]