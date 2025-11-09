pipeline {
	options {
		skipDefaultCheckout(true) }
	agent any
	environment {
		CI_REPOSITORY=credentials("CI_REPOSITORY")
		CI_REPOSITORY_NAMESPACE=credentials("CI_REPOSITORY_NAMESPACE")
		CI_IMAGE_NAME="node${env.BRANCH_NAME}"
		CI_REPOSITORY_TOKEN=credentials("CI_REPOSITORY_TOKEN")
		CI_REPOSITORY_USER=credentials("CI_REPOSITORY_USER")

		IMAGE_RELEASE_TAG="v1.0"
		IMAGE_NAME="$CI_REPOSITORY_NAMESPACE/$CI_IMAGE_NAME"
		IMAGE_TAGGED_NAME="$IMAGE_NAME:$IMAGE_RELEASE_TAG"

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
				echo 'Testing....'
				sh ''' docker run -d -p $TEST_PORT:$CONTAINER_PORT $IMAGE_NAME:tested
					sleep 10s
#[ $( docker container inspect -f '{{.State.Status}}' $IMAGE_NAME:tested)" = "running" ]

					curl localhost:$TEST_PORT
					docker stop $(docker ps -q --filter ancestor=$IMAGE_NAME:tested)
				'''
			}
		}

		stage('Push') {
			stages {
				sh '''
					docker rmi $IMAGE_NAME:latest || echo
					docker tag $IMAGE_NAME:tested $IMAGE_TAGGED_NAME
					docker tag $IMAGE_NAME:tested $IMAGE_NAME:latest

					docker push $CI_REPOSITORY/$IMAGE_TAGGED_NAME
					docker push $CI_REPOSITORY/$IMAGE_NAME:latest
				'''
			}
		}

		stage('Deploy Container') {
			steps {
				sh '''
					docker pull $CI_REPOSITORY/$IMAGE_NAME:latest
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
