pipeline {
    agent any

	stages {
		stage('checkout') {
			steps {
				echo "Checkout SCM"
				checkout scm
			}
		}
		stage('build') {
			steps {
				echo 'Testing..'
				sh 'ls'
			}
		}
		stage('test') {
			steps {
				echo 'Deploying....'
			}
		}
		stage('build_docker') {
			steps {
				echo 'Deploying....'
			}
		}
		stage('deploy') {
			steps {
				echo 'Deploying....'
			}
		}
	}
}
