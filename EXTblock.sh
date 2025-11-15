#!/bin/bash

# Script to block Chrome extensions with whitelist
# Usage: curl https://raw.githubusercontent.com/yourusername/yourrepo/main/block-chrome-extensions.sh | sudo bash

set -e  # Exit on error

echo "🔒 Configuring Chrome extension policy..."

# Create directory if it doesn't exist
mkdir -p "/Library/Managed Preferences"

# Create the plist file
cat > /tmp/chrome-policy.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ExtensionInstallBlocklist</key>
    <array>
        <string>*</string>
    </array>
    <key>ExtensionInstallAllowlist</key>
    <array>
        <string>efaidnbmnnnibpcajpcglclefindmkaj</string>
        <string>aapbdbdomjkkjkaonfhkkikfgjllcleb</string>
        <string>kbfnbcaeplbcioakkpcpgfkobkghlhen</string>
        <string>ddkjiahejlhfcafbddmgiahcphecmpfh</string>
    </array>
</dict>
</plist>
EOF

# Move to correct location
mv /tmp/chrome-policy.plist "/Library/Managed Preferences/com.google.Chrome.plist"

# Set correct permissions
chmod 644 "/Library/Managed Preferences/com.google.Chrome.plist"
chown root:wheel "/Library/Managed Preferences/com.google.Chrome.plist"

echo "✅ Chrome extension policy configured successfully!"
echo "📝 Policy location: /Library/Managed Preferences/com.google.Chrome.plist"
echo "🔄 Please restart Chrome and verify at chrome://policy"
