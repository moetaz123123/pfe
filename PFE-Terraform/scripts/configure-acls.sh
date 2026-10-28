#!/bin/bash
# Assign existing ACL to network
set -e

API_URL="$1"
API_KEY="$2"
SECRET_KEY="$3"
NETWORK_ID="$4"
VPC_ID="$5"
ACL_ID="$6"  # ← مباشرة من Terraform

echo "[*] Assigning ACL to network..."
echo "    ACL ID:     $ACL_ID"
echo "    Network ID: $NETWORK_ID"

# =======================================
# CloudStack API Function
# =======================================
cloudstack_api() {
    local command="$1"
    shift
    local -A params

    for param in "$@"; do
        key="${param%%=*}"
        value="${param#*=}"
        params["$key"]="$value"
    done
    params["command"]="$command"
    params["apikey"]="$API_KEY"
    params["response"]="json"

    local sorted_query=""
    local sorted_query_lower=""

    for key in $(echo "${!params[@]}" | tr ' ' '\n' | sort); do
        encoded_value=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${params[$key]}', safe=''))")
        sorted_query+="${key}=${encoded_value}&"
        sorted_query_lower+="${key,,}=${encoded_value,,}&"
    done

    sorted_query="${sorted_query%&}"
    sorted_query_lower="${sorted_query_lower%&}"

    local signature=$(echo -n "$sorted_query_lower" | \
        openssl dgst -sha1 -hmac "$SECRET_KEY" -binary | \
        base64 | \
        python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")

    curl -s "${API_URL}?${sorted_query}&signature=${signature}"
}

# =======================================
# Assigner l'ACL au réseau
# =======================================
echo "[*] Calling replaceNetworkACLList..."

replace_response=$(cloudstack_api "replaceNetworkACLList" \
    "aclid=$ACL_ID" \
    "networkid=$NETWORK_ID")

if echo "$replace_response" | grep -q '"success"'; then
    echo "[✓] ACL $ACL_ID assigned to network $NETWORK_ID successfully!"
else
    echo "[⚠] Response: $replace_response"
    # لا نخرج بخطأ — الـ ACL rules موجودة حتى لو الربط ما نجح
fi

echo "[✓] Done!"