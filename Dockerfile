# Start from the latest Nim image
FROM nimlang/nim:latest

# Set the working directory in the container
WORKDIR /src

# Copy the current directory contents into the container at /app
COPY . /src

RUN nimble install jester

# Compile the Nim application
RUN nim c -d:release -d:ssl -o:/src/main src/main.nim

# Make port 7777 available to the world outside this container
EXPOSE 7777

# Run the app when the container launches
CMD ["/src/main"]