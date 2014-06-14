wercker-node-continuous-deploy
==============================

Continuous Deployment script for nodejs/npm based applications.

options
=======
dev_branch: "name of the development branch"
deploy_branch: "name of the deployment branch (usually master)"


bump_version: ["major","minor","patch"]
commit: true,
commitMessage: 'Release v%VERSION%',
commitFiles: ['package.json'],
createTag: true,
tagName: 'v%VERSION%',
tagMessage: 'Version %VERSION%',
push: true,
pushTo: 'upstream',
gitDescribeOptions: '--tags --always --abbrev=1 --dirty=-d'