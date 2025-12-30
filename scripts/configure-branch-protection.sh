#!/bin/bash
# Script to configure branch protection rules for install-arch repository

set -euo pipefail

OWNER="tzervas"
REPO="install-arch"
BRANCHES=("main" "dev" "testing" "documentation")

echo "Configuring branch protection for $REPO..."

for branch in "${BRANCHES[@]}"; do
    echo "Setting protection for branch: $branch"

    # JSON payload for branch protection
    PROTECTION_DATA='{
        "required_status_checks": {
            "strict": true,
            "contexts": []
        },
        "enforce_admins": true,
        "required_pull_request_reviews": {
            "required_approving_review_count": 1,
            "require_code_owner_reviews": true,
            "dismiss_stale_reviews": true
        },
        "restrictions": null,
        "allow_force_pushes": false,
        "allow_deletions": false,
        "block_creations": false
    }'

    # Use gh api to set protection
    if gh api repos/$OWNER/$REPO/branches/$branch/protection -X PUT -H "Accept: application/vnd.github+json" --input - <<< "$PROTECTION_DATA"; then
        echo "✅ Successfully configured protection for $branch"
    else
        echo "❌ Failed to configure protection for $branch"
        exit 1
    fi
done

echo "Branch protection configuration complete!"
echo "All branches now require:"
echo "- Pull request reviews (1 approval)"
echo "- Code owner reviews"
echo "- Status checks to pass"
echo "- No force pushes or deletions"
echo "- Admin enforcement"