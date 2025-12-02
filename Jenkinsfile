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

		BRANCH_NAME = getBranchName()

		// Image tags
		IMAGE_NAME="$CI_REPOSITORY_NAMESPACE/node${BRANCH_NAME}"

		TEST_PORT = 9005 // Host Port for testing container
		HOST_PORT = getEnvPort("$BRANCH_NAME") // Set a host port for deployment
		CONTAINER_PORT = 3000 // Internal container port

	}

	stages {
		stage('Setup Environment') {
			steps {
				echo "Setup environment"
				sh '''
					
					echo "$CI_REPOSITORY_TOKEN" | docker login -u "$CI_REPOSITORY_USER" --password-stdin
				'''
			}
		}

		stage('Use library') {
			steps {
				script {
					helloWorld(dayOfWeek:"Thu",name:"kilterdev")
				}
			}
		}

		stage('Build App') {
			steps {
				echo 'Installing deps...'
				sh '''
					rm -rf node_modules/
					rm -rf package-lock.json
					npm install
				'''
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
					trivy image --exit-code 1 \
						--ignore-unfixed \
						--exit-code 1 \
						--no-progress \
						--db-repository docker.io/aquasec/trivy-db \
						-s CRITICAL \
						$IMAGE_NAME:tested > trivy-report.txt

						if [[ "$?" == 1 ]]; then
							echo "Image scanning failed: Critical vulnerabilities found."
							exit 
						else
							echo "Image scanning passed or no critical vulnerabilities found."
						fi
				'''
			}
			post {
				always {
					archiveArtifacts artifacts: 'trivy-report.txt', fingerprint: true
				}
			}
		}

		stage('Test Container') {
			steps {
				echo 'Testing....'
				sh '''
				docker stop $(docker ps --filter "publish=$TEST_PORT" --format "{{.ID}}") || echo ""
				docker run -d -p $TEST_PORT:$CONTAINER_PORT $IMAGE_NAME:tested
				
				cid=$(docker ps -q --filter ancestor=$IMAGE_NAME:tested)
				for _ in {1..10}; do
					status=$(docker inspect --format='{{.State.Running}}' $cid)
					if [[ $status ]]; then
						break
					fi
					sleep 3s
				done

				// A good practice would be to introduce logic that cleans up a stuck container
				// so it does not drain resourses trying to restart deadly-born application
				curl -f localhost:$TEST_PORT

				// this won't be executed unless curl has succeeded
				docker stop $(docker ps -q --filter ancestor=$IMAGE_NAME:tested)
				'''
			}
		}

		stage('Push') {
			environment {
				IMAGE_TAGGED_NAME = "$IMAGE_NAME:${env.GIT_COMMIT}"
			}
			steps {
				sh 'echo "Pusing image with tag: $IMAGE_TAGGED_NAME"'

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
