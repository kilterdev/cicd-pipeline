@Library('jenkinslib') _

branchMap = [
	"dev": 3001,
	"main": 3000,
]

DEFAULT_PORT = 5000

def getEnvPort(String branchName) {
  if (branchMap.containsKey(branchName)) {
    return branchMap[branchName];
  } else {
    return DEFAULT_PORT;
  }
}

def getBranchName() {
	return (params.BRANCH_NAME) ? "${params.BRANCH_NAME}" : "${env.BRANCH_NAME}";
}

pipeline {
	/* Specifying that following pipeline will be run on any available agent */
	agent any

	/* Setting up environment variables that will be available throughout the pipeline */
	environment {

		/* Using jenkins credentials for secrets
		 * these will be masked (depending on settings and not seen in pipeline logs
		 */
		CI_REPOSITORY=credentials("CI_REPOSITORY")
		CI_REPOSITORY_NAMESPACE=credentials("CI_REPOSITORY_NAMESPACE")
		CI_REPOSITORY_TOKEN=credentials("CI_REPOSITORY_TOKEN")
		CI_REPOSITORY_USER=credentials("CI_REPOSITORY_USER")

		/* Deployment shorthand variables */
		BRANCH_NAME = getBranchName()

		// Name of the image will be suffixed with branch name
		CI_IMAGE_NAME="node${BRANCH_NAME}" 
		IMAGE_RELEASE_TAG="v1.0"
		// Complete local image name without remote repo name
		IMAGE_NAME="$CI_REPOSITORY_NAMESPACE/$CI_IMAGE_NAME"
		// Name of the image including image tag
		IMAGE_TAGGED_NAME="$IMAGE_NAME:$IMAGE_RELEASE_TAG"

		TEST_PORT=9005 // Host Port for testing container

		HOST_PORT=getEnvPort("$BRANCH_NAME") // Set a host port for deployment
		CONTAINER_PORT=3000 // Internal container port
	}

	stages {
		stage('Use library') {
			steps {
				script {
					echo "${params.CUSTOM_BRANCH}"
					echo "${BRANCH_NAME}"
					echo "$HOST_PORT"
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

		/* Can be used to perform "manual" checkout when there is need to do so.
		 * Usually Jenkins performs automatic checkout where needed.
		 * Disabling this feature in favor of manual checkout would be a bad idea.
		 * I.e. when you use agents, jenkins will always automatically perform a checkout of sources. But when you disable this feature, you will need to insert a checkout step everywhere needed, or there would be a need to configure checkout globally with a manual strategy which is redundant and dumb
		 ********************************
		stage('Checkout') {
			steps {
				echo "Checkout SCM"
				checkout scm
			}
		}
		*/

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
			agent {
				docker {
					image 'aquasec/trivy'
				}
			}
			steps {
				sh '''
					trivy image \
						--exit-code 1 \
						--db-repository docker.io/aquasec/trivy-db \
						-s HIGH,CRITICAL \
						-f json -o trivy-report.json \
						$IMAGE_NAME:tested
				'''
				sh '''
					trivy report \
						-f template \
						--template @junit.tpl \
						-i trivy-report.json \
						-o trivy-report.xml
				'''
				junit 'trivy-report.xml'
				/*
				sh '''
					docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --exit-code 1 --db-repository docker.io/aquasec/trivy-db -s HIGH,CRITICAL $IMAGE_NAME:tested > trivy_report.txt
				'''
				*/
			}
			post {
				always {
					archiveArtifacts 'trivy-report.xml'
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
