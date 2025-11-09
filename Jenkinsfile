pipeline {
	options {
		skipDefaultCheckout(true)
	}
	agent any
	environment {
		CI_REPOSITORY=credentials("CI_REPOSITORY")
		CI_REPOSITORY_NAMESPACE=credentials("CI_REPOSITORY_NAMESPACE")
		CI_IMAGE_NAME="node${env.BRANCH_NAME}"
		CI_IMAGE_TAG="v1.0"
		CI_REPOSITORY_TOKEN=credentials("CI_REPOSITORY_TOKEN")
		CI_REPOSITORY_USER=credentials("CI_REPOSITORY_USER")

		IMAGE_NAME="$CI_REPOSITORY/$CI_REPOSITORY_NAMESPACE/$CI_IMAGE_NAME"
		IMAGE_TAG="$IMAGE_FULL_NAME:$CI_IMAGE_TAG"

		TEST_PORT=9005
		HOST_PORT=3000
		CONTAINER_PORT=3000
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

		stage('Build Image') {
			steps {
				echo 'Building....'
				sh '''
					docker build . -t $IMAGE_NAME:tested
				'''
			}
		}

		stage('Test Container') {
			steps {
				echo 'Deploying....'
				sh '''
					docker run -d -p $TEST_PORT:$CONTAINER_PORT $IMAGE_NAME:tested
					curl localhost:$TEST_PORT
				'''
			}
		}

		stage('Deploy Container') {
			steps {
				sh '''
					docker rmi $IMAGE_NAME:latest
					docker tag $IMAGE_NAME:tested $IMAGE_TAG
					docker tag $IMAGE_NAME:tested $IMAGE_NAME:latest

					docker stop $(docker ps -q --filter ancestor=$IMAGE_NAME:latest)
					docker run -p $HOST_PORT:$CONTAINER_PORT $IMAGE_NAME:latest
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
