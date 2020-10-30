#!/bin/sh
registration_url="https://github.com/${GITHUB_OWNER}"
if [ -z "${GITHUB_REPOSITORY}" ]; then
    token_url="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"
    echo ${token_url}
else
    token_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
    echo ${token_url}
    registration_url="${registration_url}/${GITHUB_REPOSITORY}"
fi

echo "Requesting token at '${token_url}'"

#curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url}
payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url})

export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)

if [ -z "${RUNNER_NAME}" ]; then
    RUNNER_NAME=$(hostname)
fi


echo ./config.sh \
    --name "${RUNNER_NAME}" \
    --token "${RUNNER_TOKEN}" \
    --url "${registration_url}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace


./config.sh \
    --name "${RUNNER_NAME}" \
    --token "${RUNNER_TOKEN}" \
    --url "${registration_url}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace

remove() {
    payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${token_url%/registration-token}/remove-token)
    export REMOVE_TOKEN=$(echo $payload | jq .token --raw-output)

    ./config.sh remove --unattended --token "${REMOVE_TOKEN}"
}

trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM

ls

 ./run.sh  &
# sudo ./svc.sh install && sudo ./svc.sh start 
# sudo ./svc.sh status
wait $!
