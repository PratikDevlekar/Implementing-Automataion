pipeline{
    agent any 
    environment{
        //holds version genrated in every build
        VERSION = "${env.BUILD_ID}"                          
    }
    stages{
         //static-code analysis
        stage("sonar quality check"){                      
            agent {                             
                docker {
                    image 'openjdk:11'
                }
            }
            steps{
                script{
                    withSonarQubeEnv(credentialsId: 'sonar-token') {
                            sh 'chmod +x gradlew'
                            sh './gradlew sonarqube'  
                    }
                    //collected responce from sonar 
                    timeout(time: 1, unit: 'HOURS') {
                      def qg = waitForQualityGate()                                 
                      if (qg.status != 'OK') {                                      
                           error "Pipeline aborted due to quality gate failure: ${qg.status}"
                      }
                    }
                }  
            }
        }
        stage("docker build + docker push"){
            steps{
                script{
                    //Genrate through snippet using key for docker password it's just to hide the password
                    withCredentials([string(credentialsId: 'docker_pass', variable: 'docker_password')]) {  
                             sh '''
                                docker build -t 34.125.214.226:8083/springapp:${VERSION} .
                                docker login -u admin -p $docker_password 34.125.214.226:8083               
                                docker push  34.125.214.226:8083/springapp:${VERSION}
                                docker rmi 34.125.214.226:8083/springapp:${VERSION}
                            '''
                            //build image named spring:@version    8083 is nexus repo - (docker-hosted)
                            //if incase username password expires
                            //pushed the created image
                            //deleted the image just to save space
                    }
                }
            }
        }

        // Used datree to check the configs and validate helm charts for every run.
        // good to check minor issues in early devlopment life cycle
        stage('indentifying misconfigs using datree in helm charts'){
            steps{
                script{
                    dir('kubernetes/') {
                        withEnv(['DATREE_TOKEN=GJdx2cP2TCDyUY3EhQKgTc']) {
                              sh 'helm datree test myapp/'
                        }
                    }
                }
            }
        }

        // Uploading the helm charts in personalised repo (nexus) rather than github which turn's out to be good pratice, read somewhere.
        stage("pushing the helm charts to nexus"){
            steps{
                script{
                    withCredentials([string(credentialsId: 'docker_pass', variable: 'docker_password')]) {
                          dir('kubernetes/') {
                             sh '''
                                 helmversion=$( helm show chart myapp | grep version | cut -d: -f 2 | tr -d ' ')
                                 tar -czvf  myapp-${helmversion}.tgz myapp/
                                 curl -u admin:$docker_password http://34.125.214.226:8081/repository/helm-hosted/ --upload-file myapp-${helmversion}.tgz -v
                            '''
                          }
                    }
                    //form the first line i just wanted to get the version through meta data, cut it into 2 parts and use the version 
                    //kind of like archived and then pushed artifact to dir
                    //The api syntax( curl -u admin:$nexus_password http://nexus_machine_ip:8081/repository/helm-hosted/ --upload-file myapp-${helmversion}.tgz -v)
                }
            }
        }

        //Senior approval
        stage('manual approval'){
            steps{
                script{
                    //enfore the time limit to be 10min
                    timeout(10) {
                        mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Go to build url and approve the deployment request <br> URL de build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", to: "deekshith.snsep@gmail.com";  
                        input(id: "Deploy Gate", message: "Deploy the build: ${params.project_name}?", ok: 'Deploy')
                    }
                    //sends a mail to lead with a link to approve the build 
                    //used jenkin input to deployable approval if 'ok' == Deploy then build
                }
            }
        }

        //  deploy setup on k8 cluster
        stage('Deploying application on k8s cluster') {
            steps {
               script{
                   withCredentials([kubeconfigFile(credentialsId: 'kubernetes-config', variable: 'KUBECONFIG')]) {
                        dir('kubernetes/') {
                          sh 'helm upgrade --install --set image.repository="34.125.214.226:8083/springapp" --set image.tag="${VERSION}" myjavaapp myapp/ ' 
                        }
                    }
                    // doing upgrade if the release is present or else install and then further are values which are there in corrosponding value.yaml file 
               }
            }
        }

        //Just to verify the deployment  
        stage('verifying app deployment'){
            steps{
                script{
                     withCredentials([kubeconfigFile(credentialsId: 'kubernetes-config', variable: 'KUBECONFIG')]) {
                         sh 'kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- curl myjavaapp-myapp:8080'
                     }
                }
                //to get done i runned a curl image if it works fine i would remove it and never restart 
            }
        }
    }

    post {
        // email post block
		always {
			mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL de build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", to: "deekshith.snsep@gmail.com";  
		 }
	   }
}
