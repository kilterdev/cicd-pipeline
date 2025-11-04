pipeline {
    agent any

	stages {
		stage('setup') {
			steps {
				echo "Setup environment"
				sh '''
					echo $CI_REPOSITORY_TOKEN | docker login -u $CI_REPOSITORY_USER --password-stdin
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
			}
		}
		stage('deploy') {
			steps {
				echo 'Deploying....'
			}
		}
	}
}
