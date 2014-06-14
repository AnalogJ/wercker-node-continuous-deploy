########################################################################################################################
# Environment
########################################################################################################################

echo "Configuring git"
git config --global user.email "pleasemailus@wercker.com"
git config --global user.name "wercker"

#task0 clean the working directory from the test builds (node_modules, etc are removed)
git clean -d -x -f

if [ "$WERCKER_NODE_CONTINUOUS_DEPLOY_DEV_BRANCH" = "$WERCKER_GIT_BRANCH" ]; then
    echo "Starting dev branch tasks for $WERCKER_NODE_CONTINUOUS_DEPLOY_DEV_BRANCH"

    #task1 run automated rdocs
    if [ -n "$WERCKER_NODE_CONTINUOUS_DEPLOY_RDOC" ]; then
        echo "[ Generating automated rdocs for commit ]"
        npm config set prefix ~/.npm
        export PATH=$HOME/.npm/bin:$PATH
        npm install -g smartcomments
        smartcomments -g
        echo " - checking if any changes occured by smartcomments using git diff"
        set +e
        output=$(git diff --exit-code);
        if [ $? -ne 0 ]; then
            echo " - found changes, commiting"
            git commit -am "automated rdocs"
        fi
        set -e
    fi

    #task2 bump version
    if [ -n "$WERCKER_NODE_CONTINUOUS_DEPLOY_VERSION_BUMP" ]; then

        echo "[ Automatically bumping version ]"
        LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
        echo " - latest tag: $LATEST_TAG"
        echo " - checking the diff between the latest tag and the current version."
        set +e
        output=$(git diff $LATEST_TAG HEAD --exit-code);
        if [ $? -ne 0 ]; then
            echo " - A difference exists between the current branch $WERCKER_GIT_BRANCH and tag $LATEST_TAG"
            echo " - bumping version. Incrementing $WERCKER_NODE_CONTINUOUS_DEPLOY_VERSION_BUMP"
            #bump the version
            npm version $WERCKER_NODE_CONTINUOUS_DEPLOY_VERSION_BUMP -m "automated version bump"
        else
            echo "skipping, no commits since latest tag."
        fi
        set -e
    fi

    #task3 push to github
    if [ -n "$WERCKER_NODE_CONTINUOUS_DEPLOY_PUSH" ] && [ -n "$WERCKER_NODE_CONTINUOUS_DEPLOY_GITHUB_ACCESS_TOKEN" ]; then
        echo "[ Pushing changes to github ]"
        REMOTE="https://$WERCKER_NODE_CONTINUOUS_DEPLOY_GITHUB_ACCESS_TOKEN@github.com/$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY.git"
        echo " - pushing to authorized github remote"
        git push $REMOTE HEAD:$WERCKER_GIT_BRANCH --tags
    fi
    #task4 create pull request
    if [ -n "$WERCKER_NODE_CONTINUOUS_DEPLOY_PR" ] && [ -n "$WERCKER_NODE_CONTINUOUS_DEPLOY_GITHUB_ACCESS_TOKEN" ]; then
        echo "[ Creating pull request from $WERCKER_NODE_CONTINUOUS_DEPLOY_DEV_BRANCH -> $WERCKER_NODE_CONTINUOUS_DEPLOY_DEV_BRANCH for $WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY ]"
        curl --user "$WERCKER_NODE_CONTINUOUS_DEPLOY_GITHUB_ACCESS_TOKEN:x-oauth-basic" \
           --request POST \
           --data '{"head": "'"$WERCKER_NODE_CONTINUOUS_DEPLOY_DEV_BRANCH"'", "base": "'"$WERCKER_NODE_CONTINUOUS_DEPLOY_DEPLOY_BRANCH"'","title":"automated pull request from '"$WERCKER_GIT_BRANCH"' branch."}' \
           https://api.github.com/repos/$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY/pulls
    fi



elif [ "$WERCKER_NODE_CONTINUOUS_DEPLOY_DEPLOY_BRANCH" = "$WERCKER_GIT_BRANCH" ]; then
    echo "[ Starting deploy branch tasks for $WERCKER_NODE_CONTINUOUS_DEPLOY_DEPLOY_BRANCH ]"

    #task1 npm publish
    if [ -n "$WERCKER_NODE_CONTINUOUS_DEPLOY_NPM_PUBLISH" ]; then
        echo "[ Generating .npmrc file ]"
        touch .npmrc
        echo "_auth = $WERCKER_NODE_CONTINUOUS_DEPLOY_NPM_AUTH\nemail = $WERCKER_NODE_CONTINUOUS_DEPLOY_NPM_EMAIL" >> .npmrc
        echo "Publishing package"
        cat .npmrc
        npm publish --verbose
    fi

else
    echo "unknown branch exiting."
fi