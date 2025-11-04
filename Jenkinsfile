pipeline {
    	agent any
    	environment {
    		CI_REPOSITORY_TOKEN=credentials("CI_REPOSITORY_TOKEN")
		CI_REPOSITORY_USER=credentials("CI_REPOSITORY_USER")
	}

	stages {
		stage('setup') {
			steps {
				echo "Setup environment"
				sh '''
					
					echo "${env.CI_REPOSITORY_TOKEN}" | docker login -u "${env.CI_REPOSITORY_USER}" --password-stdin
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
