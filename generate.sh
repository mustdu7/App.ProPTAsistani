#!/bin/bash
# Projeyi oluştur ve entitlements'ı koru
xcodegen generate

# App Groups entitlements (xcodegen bunları sıfırlıyor)
cat > ProPTAsistani/ProPTAsistani.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.must.proptasistani</string>
    </array>
</dict>
</plist>
EOF

cat > ProPTWidgetExtension.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.must.proptasistani</string>
    </array>
</dict>
</plist>
EOF

echo "✅ Proje oluşturuldu, entitlements korundu."
