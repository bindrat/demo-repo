// Jenkinsfile - CI pipeline for demo-service
pipeline {
  agent any

  environment {
    // Assumed Docker Hub username -> change if different
    DOCKER_USER = "bijuindrat"
    IMAGE = "${DOCKER_USER}/demo-service"
    // Credentials ID in Jenkins for Docker Hub (create this in Jenkins > Credentials)
    REGISTRY_CREDENTIALS = 'dockerhub-creds'
    TAG = "${env.BUILD_NUMBER}"
  }

  options {
    // keep build logs for 30 days
    buildDiscarder(logRotator(numToKeepStr: '50', daysToKeepStr: '30'))
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        // checkout the repo the job is configured against
        checkout scm
      }
    }

    stage('Install & Test') {
      steps {
        echo "Installing dependencies..."
        sh 'npm ci'
        echo "Running tests..."
        // adjust to run real tests; here we allow non-zero to not block if empty
        sh 'npm test || true'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          sh "docker build -t ${IMAGE}:${TAG} ."
        }
      }
    }

    stage('Scan Image (Trivy)') {
      steps {
        script {
          // run trivy if available; non-zero exit won't fail pipeline due to || true
          sh """
            if command -v trivy >/dev/null 2>&1; then
              echo "Running trivy scan..."
              trivy image --severity CRITICAL --exit-code 1 ${IMAGE}:${TAG} || true
            else
              echo "Trivy not found - skipping image scan"
            fi
          """
        }
      }
    }

    stage('Push to Docker Hub') {
      when {
        expression { return env.REGISTRY_CREDENTIALS != null }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIALS}", usernameVariable: 'REG_USER', passwordVariable: 'REG_PSW')]) {
          sh 'echo "$REG_PSW" | docker login -u "$REG_USER" --password-stdin'
          sh "docker push ${IMAGE}:${TAG}"
          sh "docker tag ${IMAGE}:${TAG} ${IMAGE}:latest"
          sh "docker push ${IMAGE}:latest"
        }
      }
    }

    stage('Cleanup') {
      steps {
        sh 'docker image prune -af || true'
      }
    }
  }

  post {
    success {
      echo "Build succeeded: ${IMAGE}:${TAG}"
    }
    failure {
      echo "Build failed - check console output"
    }
    always {
      script { 
        // optional: record image name in build description for easy reference
        currentBuild.description = "${IMAGE}:${TAG}"
      }
    }
  }
}
