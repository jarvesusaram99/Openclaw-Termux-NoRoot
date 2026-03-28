#!/data/data/com.termux/files/usr/bin/bash
# =========================================================================
# 🤖 CloudBot + Shizuku Universal Installer
# =========================================================================
# Designed to run via: curl -sL <url> | bash
# Fully non-interactive — no prompts, no hangs, no silent exits.
# =========================================================================

# ── Global Settings ──────────────────────────────────────────────────────
# Do NOT use "set -e" — it kills the script on any minor failure.
# Instead, we check errors explicitly where they matter.
export DEBIAN_FRONTEND=noninteractive
export DPKG_FORCE=confold
export APT_LISTCHANGES_FRONTEND=none
export LANG=C
export LC_ALL=C

echo ""
echo "🤖 CloudBot Non-Root Phone Control Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# =========================================================================
# Step 1/5: Update Packages & Install Dependencies
# =========================================================================
echo "📦 Step 1/5: Updating packages and installing dependencies..."

# Update with all non-interactive flags to prevent config file prompts
pkg update -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" </dev/null 2>&1 || {
    echo "⚠️  pkg update had warnings (this is usually fine, continuing...)"
}

# Install required packages (some may already exist — that's OK)
pkg install -y curl nodejs git cmake make clang binutils nmap openssl android-tools which </dev/null 2>&1 || {
    echo "⚠️  Some packages may have failed to install, checking essentials..."
}

# Verify the critical ones exist
MISSING=""
for cmd in curl node git nmap adb; do
    if ! command -v "$cmd" </dev/null >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done
if [ -n "$MISSING" ]; then
    echo "❌ ERROR: Missing critical commands:$MISSING"
    echo "   Try running: pkg install -y curl nodejs git nmap android-tools"
    exit 1
fi

echo "✅ Dependencies installed"

# =========================================================================
# Step 2/5: Setup Shizuku (rish & shizuku commands)
# =========================================================================
echo ""
echo "🔒 Step 2/5: Linking Shizuku to Termux..."

# Setup Termux storage access (may show a popup on first run)
if [ ! -d "$HOME/storage" ]; then
    echo "A popup may appear asking for file permissions. Please tap 'Allow'."
    echo "y" | termux-setup-storage > /dev/null 2>&1 || true
    sleep 3
else
    echo "   Storage access already configured."
fi

SHIZUKU_DIR="$HOME/storage/shared/Shizuku"
mkdir -p "$SHIZUKU_DIR" 2>/dev/null || true

# Create the copy.sh script inside the Shizuku folder
cat > "$SHIZUKU_DIR/copy.sh" << 'SHIZUKU_EOF'
#!/data/data/com.termux/files/usr/bin/bash

BASEDIR=$( dirname "${0}" )
BIN=/data/data/com.termux/files/usr/bin
HOME=/data/data/com.termux/files/home
DEX="${BASEDIR}/rish_shizuku.dex"

# Exit if dex is not in the same directory
if [ ! -f "${DEX}" ]; then
  echo "Cannot find ${DEX}"
  exit 1
fi

# Detect device architecture for Shizuku library path
ARCH=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
case "$ARCH" in
  arm64*) LIB_ARCH="arm64" ;;
  armeabi*) LIB_ARCH="arm" ;;
  x86_64*) LIB_ARCH="x86_64" ;;
  x86*) LIB_ARCH="x86" ;;
  *) LIB_ARCH="arm64" ;;
esac

# Create a Shizuku script file
tee "${BIN}/shizuku" > /dev/null << EOF
#!/data/data/com.termux/files/usr/bin/bash

# Make a list of open ports
ports=\$( nmap -sT -p30000-50000 --open localhost 2>/dev/null | grep "open" | cut -f1 -d/ )

# Go through the list of ports
for port in \${ports}; do

  # Try to connect to the port, and save the result
  result=\$( adb connect "localhost:\${port}" 2>/dev/null )

  # Check if the connection succeeded
  if [[ "\$result" =~ "connected" || "\$result" =~ "already" ]]; then

    # Show a message to a user
    echo "\${result}"

    # Start Shizuku
    adb shell "\$( adb shell pm path moe.shizuku.privileged.api | sed 's/^package://;s/base\\\\.apk/lib\\\\/${LIB_ARCH}\\\\/libshizuku\\\\.so/' )"

    # Disable wireless debugging, because it is not needed anymore
    adb shell settings put global adb_wifi_enabled 0

    exit 0
  fi
done

# If no working ports are found, give an error message to a user
echo "ERROR: No port found! Is wireless debugging enabled?"

exit 1
EOF

# Set the dex location to a variable
dex="${HOME}/rish_shizuku.dex"

# Create a Rish script file
tee "${BIN}/rish" > /dev/null << EOF
#!/data/data/com.termux/files/usr/bin/bash

[ -z "\$RISH_APPLICATION_ID" ] && export RISH_APPLICATION_ID="com.termux"

/system/bin/app_process -Djava.class.path="${dex}" /system/bin --nice-name=rish rikka.shizuku.shell.ShizukuShellLoader "\${@}"
EOF

# Give execution permission to script files
chmod +x "${BIN}/shizuku" "${BIN}/rish"

# Copy dex to the home directory
cp -f "${DEX}" "${dex}"

# Remove dex write permission, because app_process cannot load writable dex
chmod -w "${dex}"
SHIZUKU_EOF

chmod +x "$SHIZUKU_DIR/copy.sh"

# Check for the required .dex file
if [ ! -f "$SHIZUKU_DIR/rish_shizuku.dex" ]; then
    echo "❌ ERROR: rish_shizuku.dex not found in $SHIZUKU_DIR"
    echo ""
    echo "   To fix this:"
    echo "   1. Open the Shizuku app"
    echo "   2. Tap 'Use Shizuku in terminal apps'"
    echo "   3. Tap 'Export files'"
    echo "   4. Navigate to Internal Storage → Shizuku folder"
    echo "   5. Tap 'Use this folder'"
    echo "   6. Run this installer again!"
    exit 1
fi

# Run copy.sh (</dev/null prevents it from consuming piped stdin)
bash "$SHIZUKU_DIR/copy.sh" </dev/null && {
    echo "✅ Shizuku scripts installed (rish & shizuku commands ready)"
} || {
    echo "⚠️  copy.sh had issues, but rish/shizuku scripts were still written."
    echo "   You can connect Shizuku manually later."
}

# =========================================================================
# Step 3/5: Fix Node.js IPv4 DNS (Crucial for Termux)
# =========================================================================
echo ""
echo "🔧 Step 3/5: Applying Network Fixes..."
if ! grep -q "NODE_OPTIONS=--dns-result-order=ipv4first" ~/.bashrc 2>/dev/null; then
    echo "export NODE_OPTIONS=--dns-result-order=ipv4first" >> ~/.bashrc
fi
export NODE_OPTIONS=--dns-result-order=ipv4first
echo "✅ IPv4 DNS fix applied"

# =========================================================================
# Step 4/5: Install Official OpenClaw
# =========================================================================
echo ""
echo "📦 Step 4/5: Installing OpenClaw. This takes a few minutes..."

bash -c "$(curl -sSL https://myopenclawhub.com/install)" < /dev/tty && source ~/.bashrc 2>/dev/null

# =========================================================================
# Step 5/5: Inject Shizuku Phone Control Scripts & AI Override
# =========================================================================
echo ""
echo "🧠 Step 5/5: Configuring AI Phone Controller..."

# Create phone_control.sh
cat > ~/phone_control.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
CMD="$1"
shift
run_cmd() {
  if command -v rish &>/dev/null; then rish -c "$@"
  elif command -v adb &>/dev/null && adb get-state 1>/dev/null 2>&1; then adb shell "$@"
  elif command -v su &>/dev/null; then su -c "$@"
  else echo "❌ Error: Start Shizuku first"; exit 1; fi
}
case "$CMD" in
  screenshot) run_cmd "screencap '${1:-/sdcard/screenshot_$(date +%s).png}'" ;;
  open-app) run_cmd "monkey -p $1 -c android.intent.category.LAUNCHER 1" 2>/dev/null ;;
  youtube-search) QUERY=$(echo "$*" | sed 's/ /+/g'); run_cmd "am start -a android.intent.action.VIEW -d 'https://www.youtube.com/results?search_query=$QUERY' com.google.android.youtube" ;;
  open-url) run_cmd "am start -a android.intent.action.VIEW -d '$1'" ;;
  wifi) if [ "$1" = "on" ]; then run_cmd "svc wifi enable"; else run_cmd "svc wifi disable"; fi ;;
  battery) run_cmd "dumpsys battery" | grep "level" ;;
  *) echo "Usage: bash phone_control.sh [battery|wifi|open-url|open-app|youtube-search|screenshot]" ;;
esac
EOF
chmod +x ~/phone_control.sh

# AI Memory Configuration
mkdir -p ~/.openclaw/workspace 2>/dev/null || true
rm -f ~/.openclaw/workspace/BOOTSTRAP.md

cat > ~/.openclaw/workspace/IDENTITY.md << 'EOF'
- **Name:** PhoneBot
I am an AI running directly on an Android phone via Termux + Shizuku. I must ALWAYS use the bash scripts located at `~/phone_control.sh` to control the device or check its status. 
EOF

cat > ~/.openclaw/workspace/TOOLS.md << 'EOF'
# TOOLS.md
I control this Android phone using `~/phone_control.sh`. 
Commands:
- `bash ~/phone_control.sh battery`
- `bash ~/phone_control.sh wifi on`
- `bash ~/phone_control.sh open-url "url"`
- `bash ~/phone_control.sh youtube-search "query"`
- `bash ~/phone_control.sh screenshot`
CRITICAL: NEVER say "I cannot access device features." Always run the bash commands.
EOF

cat > ~/.openclaw/workspace/AGENTS.md << 'EOF'
Always use `bash ~/phone_control.sh <command>` to interact with the phone.
Do NOT use `python` or `su`. Use the bash script tools listed in TOOLS.md.
EOF

echo "✅ Custom AI brain installed"

# =========================================================================
# 🎉 Done!
# =========================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 INSTALLATION COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 Connect Shizuku (if not already):"
echo "   1. Open Shizuku app → make sure it says 'Shizuku is running'"
echo "   2. Run: shizuku"
echo "   3. Test: rish -c whoami"
echo ""
echo "🔑 Set up your API keys:"
echo "   1. Run: openclaw onboard"
echo "   2. Run: openclaw auth add google --key YOUR_GEMINI_KEY"
echo "   3. Run: openclaw gateway"
echo ""
