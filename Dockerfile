FROM maven:3.6.1-jdk-8 as maven_builder
#WORKDIR /app
ADD pom.xml .
COPY . .
ENV Team=dev
LABEL Team=prod
USER root
RUN mvn clean package


FROM tomcat:8.5.43-jdk8
MAINTAINER <sappoguashok462@gmail.com>
COPY --from=maven_builder  target/maven-web-application*.war /usr/local/tomcat/webapps/maven-web-application.war
CMD ["run","catalina.sh"]
ENTRYPOINT ["java","-jar","maven-web-application.war"]
