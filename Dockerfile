# This is multi stage docker file 
# First part contains only the build
FROM openjdk:11 as builder 
WORKDIR /app
COPY . . 
RUN chmod +x gradlew
RUN ./gradlew build 

# New stage
# Rum the build on light weight image
FROM tomcat:9
WORKDIR webapps
COPY --from=builder /app/build/libs/sampleWeb-0.0.1-SNAPSHOT.war .
RUN rm -rf ROOT && mv sampleWeb-0.0.1-SNAPSHOT.war ROOT.war
