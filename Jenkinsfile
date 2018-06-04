node {
  try {
    stage('checkout') {
      checkout scm
    }
    stage('get-config') {
      echo "Git params" 
      echo "=========="
      sh(' git config -l ')
      echo "Enviroment variables" 
      echo "=========="
      sh(' env ')
      echo "SSH config" 
      echo "=========="
      sh(' cat $HOME/.ssh/config ')
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
