function whatsmyip
    echo -n "Internal IP: "
    ip -o -4 addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1
    echo -n "External IP: "
    curl -fsS ifconfig.me; or echo "unavailable"
end