## Automated CI/CD pipeline (Jenkins)

Used a basic java application based on gradle build to learn the ci/cd pipelines.

#### The build pipeline series haves 
- Pull the code
- Do the static code analysis using sonarqube
- Check the status of the quality gate in sonar; if it fails, push a mail;
- Using multistage dockerfile, build the code generate artifacts, and create an image
- Push the image to private docker registry (nexus)
- Check if any misconfiguration helm charts; if it fails, push a mail;
- helm chart is pushed to nexus
- Senior manual approval before deployment 
- Deploy on K8 cluster 
- Send an API to test the app deployment  

