pipeline {
	options {
		skipDefaultCheckout(true)
	}
	agent any
	environment {
		CI_REPOSITORY=credentials("CI_REPOSITORY")
		CI_REPOSITORY_NAMESPACE=credentials("CI_REPOSITORY_NAMESPACE")
		CI_IMAGE_NAME="node${env.BRANCH_NAME}"
		CI_REPOSITORY_TOKEN=credentials("CI_REPOSITORY_TOKEN")
		CI_REPOSITORY_USER=credentials("CI_REPOSITORY_USER")
		IMAGE_TAG="$CI_REPOSITORY/$CI_REPOSITORY_NAMESPACE/$CI_IMAGE_NAME:$CI_IMAGE_TAG"
	}

	stages {
		stage('setup') {
			steps {
				echo "Setup environment"
				sh '''
					
					echo "$CI_REPOSITORY_TOKEN" | docker login -u "$CI_REPOSITORY_USER" --password-stdin
				'''
			}
		}
		stage('checkout') {
			steps {
				echo "Checkout SCM"
				checkout scm
			}
		}
		stage('build') {
			steps {
				echo 'Installing deps...'
				sh 'npm install'
			}
		}
		stage('test') {
			steps {
				echo 'Running tests....'
				sh 'npm test'
			}
		}
		stage('build_docker') {
			steps {
				echo 'Building....'
				sh '''
					docker build . -t $IMAGE_TAG
					docker push $IMAGE_TAG
				'''
			}
		}
		stage('deploy') {
			steps {
				echo 'Deploying....'
			}
		}
	}
}
