@Library('jenkinslib') _

def getEnvPort(branchName) {
    if("dev".equals(branchName)) {
        return 3001;
    } else if ("main".equals(branchName)) {
        return 3000;
    }
}

def getBranchName() {
	if ("$CUSTOM_BRANCH".isEmpty()) {
		return "${env.BRANCH_NAME}";
	else {
		return "$CUSTOM_BRANCH";
	}
}

pipeline {
	
	agent any
	environment {
		BRANCH_NAME=getBranchName()
		CI_REPOSITORY=credentials("CI_REPOSITORY")
		CI_REPOSITORY_NAMESPACE=credentials("CI_REPOSITORY_NAMESPACE")
		CI_IMAGE_NAME="node${BRANCH_NAME}"
		CI_REPOSITORY_TOKEN=credentials("CI_REPOSITORY_TOKEN")
		CI_REPOSITORY_USER=credentials("CI_REPOSITORY_USER")

		IMAGE_RELEASE_TAG="v1.0"
		IMAGE_NAME="$CI_REPOSITORY_NAMESPACE/$CI_IMAGE_NAME"
		IMAGE_TAGGED_NAME="$IMAGE_NAME:$IMAGE_RELEASE_TAG"

		TEST_PORT=9005

		HOST_PORT=getEnvPort(BRANCH_NAME)
		CONTAINER_PORT=3000
	}

	stages {
		stage('Use library') {
			steps {
				script {
					helloWorld(dayOfWeek:"Thu",name:"kilterdev")
				}
			}
		}

		stage('Setup Environment') {
			steps {
				echo "Setup environment"
				sh '''
					
					echo "$CI_REPOSITORY_TOKEN" | docker login -u "$CI_REPOSITORY_USER" --password-stdin
				'''
			}
		}

		stage('Checkout') {
			steps {
				echo "Checkout SCM"
				checkout scm
			}
		}

		stage('Build App') {
			steps {
				echo 'Installing deps...'
				sh 'npm install'
			}
		}

		stage('Test App') {
			steps {
				echo 'Running tests....'
				sh 'npm test'
			}
		}
		
		stage('Docker Lint') {
			agent {
				docker {
					image 'hadolint/hadolint:latest-debian'
				}
			}
			steps {
				sh '''
					cat Dockerfile
					hadolint Dockerfile | tee hadolint.txt
				'''
			}
			post {
				always {
					archiveArtifacts 'hadolint.txt'
				}
			}
		}

		stage('Build Image') {
			steps {
				echo 'Building....'
				sh '''
					docker build . --no-cache -t $IMAGE_NAME:tested
				'''
			}
		}

		stage('Scan Vulnerabilities') {
			steps {
				sh '''
					docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --db-repository docker.io/aquasec/trivy-db -s HIGH,CRITICAL $IMAGE_NAME:tested > trivy_report.txt
				'''
			}
			post {
				always {
					archiveArtifacts 'trivy_report.txt'
				}
			}
		}

		stage('Test Container') {
			steps {
				echo 'Testing....'
				sh '''
				docker stop $(docker ps --filter "publish=$TEST_PORT" --format "{{.ID}}") || echo ""
				docker run -d -p $TEST_PORT:$CONTAINER_PORT $IMAGE_NAME:tested
					sleep 10s
#[ $( docker container inspect -f '{{.State.Status}}' $IMAGE_NAME:tested)" = "running" ]

					curl localhost:$TEST_PORT
					docker stop $(docker ps -q --filter ancestor=$IMAGE_NAME:tested)
				'''
			}
		}

		stage('Push') {
			steps {
				// Remove latest tag that is currently running as a container
				// and tag tested image as latest
				// Push tested version to repository
				// Remove all local images
				sh '''
					docker rmi $IMAGE_NAME:latest || echo
					docker tag $IMAGE_NAME:tested $IMAGE_TAGGED_NAME
					docker tag $IMAGE_NAME:tested $IMAGE_NAME:latest

					docker push $CI_REPOSITORY/$IMAGE_TAGGED_NAME
					docker push $CI_REPOSITORY/$IMAGE_NAME:latest

					docker rmi $IMAGE_NAME || echo
				'''
			}
		}

		stage('Deploy Container') {
			steps {
				sh '''
					docker pull $CI_REPOSITORY/$IMAGE_NAME:latest
					
					docker stop $(docker ps --filter "publish=$HOST_PORT" --format "{{.ID}}") || echo ""
#docker stop $(docker ps -q --filter ancestor=$IMAGE_NAME:latest) || echo
					docker run -d -p $HOST_PORT:$CONTAINER_PORT $IMAGE_NAME:latest
				'''
			}
		}

		stage('Deploy to K8S') {
			steps {
				echo "Deploying to K8S"
			}
		}
	}
}
