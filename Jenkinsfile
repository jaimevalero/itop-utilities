node {
  try {
    stage('checkout') {
      checkout scm
    }
    stage('compile') {
      echo "nothing to compile for..."
            sh(' git config -l ')
    }
    stage('test') {
       echo "test"
    }
    stage('package') {
      echo "test"
      sh('ls -latr ')
    }
    stage('publish') {
      echo "uploading package..."
    }
  } finally {
    stage('cleanup') {
      echo "doing some cleanup..."
    }
  }
}
