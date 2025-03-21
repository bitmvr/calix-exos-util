#!/usr/bin/env bash


# Secrets are loaded in as environment variables.
CALIX_USERNAME="$CALIX_USERNAME"
CALIX_PASSWORD="$CALIX_PASSWORD"

COOKIE_JAR='calix-cookies.txt'
ENDPOINT="https://192.168.1.1"

__get_nonce(){
    curl --silent \
         --insecure \
         --location "${ENDPOINT}/get_nonce.cmd" \
         --header "Content-Type: application/x-www-form-urlencoded"
}

__set_auth(){
    nonce="$1"
    echo -n "${CALIX_USERNAME}:${nonce}:${CALIX_PASSWORD}"
}

nonce="$(__get_nonce)"
auth_plain="$(__set_auth "${nonce}")"
auth="$(echo -n "$(__set_auth "${nonce}")" | sha256)"
login_payload="Username=${CALIX_USERNAME}&auth=${auth}&nonce=${nonce}"

__get_session_cookie(){
    curl \
        --cookie-jar "$COOKIE_JAR" \
        --silent \
        --insecure \
        --request POST "${ENDPOINT}/login.cgi" \
        --data "${login_payload}" \
        --header "Content-Type: application/x-www-form-urlencoded"
}

__get_ipv4_address(){
    curl \
        --cookie "$COOKIE_JAR" \
        --silent \
        --insecure \
        --request POST "${ENDPOINT}/status_connection.cmd" \
        --data-raw 'action=getStatus' \
        --header 'Content-Type: application/x-www-form-urlencoded;charset=utf-8;' \
        | jq --raw-output '.gateway[] | select(.param == "IPv4 IP Address") | .value'
}

main(){
    __get_session_cookie
    __get_ipv4_address
}

main
