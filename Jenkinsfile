pipeline {
    agent any

    environment{
        AWS_REGION = 'ap-northeast-1'
        IMAGE_NAME = 'cryptory-config'
        ECR_REGISTRY = '050314037804.dkr.ecr.ap-northeast-1.amazonaws.com'
        ECR_REPO = "${ECR_REGISTRY}/cryptory-config"
        GIT_USERNAME = "${GIT_USERNAME}"
        GIT_PASSWORD = "${GIT_PASSWORD}"
    }

    stages {
        stage('Checkout') {  // 1️⃣ GitHub에서 코드 가져오기
            steps {
                git branch: 'main', url: 'https://github.com/lgcns-2nd-project-Ix4/Cryptory-ConfigServer.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t $IMAGE_NAME .
                    docker tag $IMAGE_NAME:latest $ECR_REPO:latest
                    echo docker build success
                """
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'AWS-CREDENTIALS'
                ]]) {
                    sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push $ECR_REPO:latest'
            }
        }

        stage('Deploy to EC2'){
            steps{
                withEnv([
                    "AWS_REGION=${env.AWS_REGION}",
                    "ECR_REPO=${env.ECR_REPO}",
                    "ECR_REGISTRY=${env.ECR_REGISTRY}",
                    "GIT_USERNAME=${env.GIT_USERNAME}",
                    "GIT_PASSWORD=${env.GIT_PASSWORD}",
                    "RABBITMQ_HOST=${env.RABBITMQ_HOST}",
                    "RABBITMQ_PORT=${env.RABBITMQ_PORT}",
                    "RABBITMQ_USERNAME=${env.RABBITMQ_USERNAME}",
                    "RABBITMQ_PASSWORD=${env.RABBITMQ_PASSWORD}"
                ]){
                    sshPublisher(
                        publishers: [
                            sshPublisherDesc(
                                configName: 'Outer-Server',
                                transfers: [
                                    sshTransfer(
                                        cleanRemote: false,
                                        excludes: '',
                                        execCommand: """
                                            set -x

                                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                                            docker pull $ECR_REPO:latest

                                            if [ -z "\$(docker ps -q -f name=rabbit)" ]; then
                                                if [ -n "\$(docker ps -aq -f status=exited -f name=rabbit)" ]; then
                                                    docker rm rabbit
                                                fi
                                                docker run -d --name rabbit -p 15672:15672 -p 5672:5672 -e RABBITMQ_DEFAULT_USER=guest -e RABBITMQ_DEFAULT_PASS=guest rabbitmq:3-management
                                            fi

                                            docker stop cryptory-config || true
                                            docker rm cryptory-config || true
                                            docker run -d --name cryptory-config -p 8888:8888 \\
                                                -e GIT_USERNAME=$GIT_USERNAME \\
                                                -e GIT_PASSWORD=$GIT_PASSWORD \\
                                                -e RABBITMQ_HOST=$RABBITMQ_HOST \\
                                                -e RABBITMQ_PORT=$RABBITMQ_PORT \\
                                                -e RABBITMQ_USERNAME=$RABBITMQ_USERNAME \\
                                                -e RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD \\
                                                $ECR_REPO:latest

                                            echo "Deploy successful"
                                        """,
                                        execTimeout: 120000,
                                        flatten: false,
                                        )
                                ],
                            usePromotionTimestamp: false,
                            useWorkspaceInPromotion: false,
                            verbose: false)
                        ]
                    )
                }
            }
        }
    }


   post {
        success {
            echo "✅ Docker image successfully pushed to ECR!"
        }
        failure {
            echo "❌ Docker image push failed!"
        }
    }
}
