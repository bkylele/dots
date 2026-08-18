# Homelab Configuration: `wapol`

This document outlines the setup and operation of the `wapol` NixOS homelab. It is designed to be a minimal, Docker-free NAS and VPN gateway running on an older laptop.

## 🛠 Core Services
- **VPN**: Pure WireGuard (Self-hosted, no 3rd party account needed).
- **NAS (Native)**: Samba (SMB/CIFS) for native Windows/Linux drive mapping.
- **NAS (Web)**: Filebrowser for a "Google Drive-like" web interface.
- **Management**: Cockpit for web-based hardware monitoring and terminal access.
- **Discovery**: Avahi (mDNS) for easy `wapol.local` access on the local network.

---

## 🚀 Post-Installation Checklist
After the initial NixOS installation, you **must** perform these steps to make the system fully functional:

### 1. WireGuard Key Generation
The configuration expects keys at `/var/lib/wireguard/`. Run these commands:
```bash
sudo mkdir -p /var/lib/wireguard
sudo chmod 700 /var/lib/wireguard
wg genkey | sudo tee /var/lib/wireguard/private.key | wg pubkey | sudo tee /var/lib/wireguard/public.key
```
*Take note of the `public.key` content for your client devices.*

### 2. Router Configuration
- **Ethernet**: Plug the laptop into your router via Ethernet to bypass "Wireless Client Isolation."
- **Port Forwarding**: Forward **UDP Port 51820** to the laptop's local IP address to allow VPN access from outside.
- **DHCP Reservation**: (Optional but recommended) Set a "Static Lease" in your router so the laptop's IP address never changes.

### 3. Initialize Filebrowser
- Log in to `http://wapol.local:8080` (Default: `admin` / `admin`).
- Change the admin password and create user accounts for your family.

---

## 📂 How to Access the NAS

### Option A: At Home (Local Network)
Use the hostname `wapol.local` for convenience.
- **Web Interface**: [http://wapol.local:8080](http://wapol.local:8080)
- **Windows Explorer**: Type `\\wapol.local\public` in the address bar.
- **Linux File Manager**: Connect to `smb://wapol.local/public`.

### Option B: Away from Home (WireGuard VPN)
Ensure your WireGuard app is connected to `10.0.0.1`. To route all your internet traffic through the homelab (Full Tunnel) and enable Ad-Blocking:
1.  **Client Config**: Set `AllowedIPs = 0.0.0.0/0, ::/0` in your peer settings.
2.  **DNS Config**: Set `DNS = 10.0.0.1` in your client's `[Interface]` section.
- **Web Interface (Filebrowser)**: [http://10.0.0.1:8080](http://10.0.0.1:8080)
- **Web Interface (AdGuard Home)**: [http://10.0.0.1:3000](http://10.0.0.1:3000)
- **Windows Explorer**: Type `\\10.0.0.1\public`.

---

## 🛡 Ad-Blocking (AdGuard Home)
AdGuard Home acts as a network-wide ad blocker.
1.  **Initial Setup**: When you first access [http://wapol.local:3000](http://wapol.local:3000), follow the setup wizard.
2.  **Network Interfaces**: During setup, ensure it listens on `All Interfaces` or specifically `wg0`.
3.  **Upstream DNS**: In the AdGuard settings, it is recommended to set your upstream DNS to a privacy-focused provider like `https://dns.quad9.net/dns-query`.
4.  **Verification**: Once the client is connected to the VPN with the `DNS = 10.0.0.1` setting, visit a site like `canyoublockit.com` to test.

---

## 🖥 System Management (Cockpit)
Cockpit allows you to check CPU usage, temperature, and run terminal commands from your browser.
- **Local**: [https://wapol.local:9090](https://wapol.local:9090)
- **Remote**: [https://10.0.0.1:9090](https://10.0.0.1:9090)
- **Credentials**: Use your system user (`brian`) and password.
- *Note: You will see a "Privacy Warning" in your browser because of the self-signed SSL certificate. It is safe to click "Advanced" -> "Proceed".*

---

## 📝 Maintenance Notes
- **Lid Behavior**: The laptop is configured to **ignore** the lid switch. You can close the lid and the server will stay active 24/7.
- **Storage Path**: All shared files are stored in `/srv/nas/public`.
- **User Permissions**: Samba is currently in "Guest" mode (no password required for the shared folder). System changes via Cockpit require the `brian` user password.
