// Jenkinsfile - build image, push to Docker Hub, and deploy to k3s
pipeline {
  agent any

  environment {
    DOCKER_USER = "bijuindrat"                      // change if different
    IMAGE = "${DOCKER_USER}/demo-service"
    REGISTRY_CREDENTIALS = 'dockerhub-creds'     // Jenkins credential id for Docker Hub
    // Optionally: If you uploaded kubeconfig to Jenkins as "Secret file" credential,
    // set KUBECONFIG_CRED_ID = 'k3s-kubeconfig' and uncomment the withCredentials block below.
    KUBECONFIG_ON_DISK = '/var/lib/jenkins/.kube/config'
    TAG = "${env.BUILD_NUMBER}"
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '50', daysToKeepStr: '30'))
    timestamps()
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install & Test') {
      steps {
        sh 'npm ci'
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

    stage('Scan Image (optional Trivy)') {
      steps {
        script {
          sh '''
            if command -v trivy >/dev/null 2>&1; then
              echo "Running trivy scan..."
              trivy image --severity CRITICAL --exit-code 1 ${IMAGE}:${TAG} || echo "Trivy found issues (non-fatal for now)"
            else
              echo "Trivy not found - skipping scan"
            fi
          '''
        }
      }
    }

    stage('Push to Docker Hub') {
      when { expression { return env.REGISTRY_CREDENTIALS != null } }
      steps {
        withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIALS}", usernameVariable: 'REG_USER', passwordVariable: 'REG_PSW')]) {
          sh 'echo "$REG_PSW" | docker login -u "$REG_USER" --password-stdin'
          sh "docker push ${IMAGE}:${TAG}"
          sh "docker tag ${IMAGE}:${TAG} ${IMAGE}:latest"
          sh "docker push ${IMAGE}:latest"
        }
      }
    }

    stage('Deploy to k3s') {
      steps {
        script {
          // Option A: Use kubeconfig we copied to Jenkins home on disk
          if (fileExists(env.KUBECONFIG_ON_DISK)) {
            echo "Using on-disk kubeconfig: ${env.KUBECONFIG_ON_DISK}"
            sh "kubectl --kubeconfig=${env.KUBECONFIG_ON_DISK} apply -f k8s/deployment.yaml"
            sh "kubectl --kubeconfig=${env.KUBECONFIG_ON_DISK} apply -f k8s/service.yaml"
            sh "kubectl --kubeconfig=${env.KUBECONFIG_ON_DISK} rollout status deployment/demo-service --timeout=120s"
          } else {
            // Option B: If you stored kubeconfig as a Jenkins 'Secret file' (credentials), use it:
            echo "On-disk kubeconfig not found. Trying to use secret file credential (KUBECONFIG_CRED_ID)."
            // Uncomment the block below if you configured a Secret file credential with ID 'k3s-kubeconfig'
            /*
            withCredentials([file(credentialsId: 'k3s-kubeconfig', variable: 'KCFG')]) {
              sh 'kubectl --kubeconfig=$KCFG apply -f k8s/deployment.yaml'
              sh 'kubectl --kubeconfig=$KCFG apply -f k8s/service.yaml'
              sh 'kubectl --kubeconfig=$KCFG rollout status deployment/demo-service --timeout=120s'
            }
            */
            error("No kubeconfig available on disk. Upload kubeconfig to ${env.KUBECONFIG_ON_DISK} or configure a Secret file credential named 'k3s-kubeconfig'.")
          }
        }
      }
    }

    stage('Cleanup') {
      steps { sh 'docker image prune -af || true' }
    }
  }

  post {
    success {
      echo "Pipeline succeeded. Deployed ${IMAGE}:${TAG}"
      script {
        currentBuild.description = "${IMAGE}:${TAG}"
      }
    }
    failure {
      echo "Pipeline failed - check console output"
    }
  }
}
