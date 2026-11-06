import os
import subprocess

with open('/home/vinh/Documents/project_ncs/old_diagram.svg', 'r', encoding='utf-8') as f:
    svg = f.read()

# 1. Update Gateway 1
old_gw1_routing = """        <text x="0" y="40" class="code" fill="#0f172a"><tspan font-weight="bold">Định tuyến:</tspan> DNAT 80,443,7443,8443 • <tspan font-weight="bold" fill="#16a34a">LAN Masquerade</tspan></text>
        <text x="0" y="54" class="code" fill="#64748b">Route Table AZ-a Default Gateway: 10.0.10.254 (Egress NAT)</text>"""

new_gw1_routing = """        <text x="0" y="40" class="code" fill="#0f172a"><tspan font-weight="bold">Cân bằng tải:</tspan> <tspan font-weight="bold" fill="#b45309">HAProxy L4 (Active W1 / Backup W2)</tspan></text>
        <text x="0" y="54" class="code" fill="#0f172a"><tspan font-weight="bold">Định tuyến:</tspan> DNAT 8443 (Wazuh SIEM) • <tspan font-weight="bold" fill="#16a34a">LAN Masquerade SNAT</tspan></text>"""

svg = svg.replace(old_gw1_routing, new_gw1_routing)

# 2. Update Gateway 2
old_gw2_routing = """        <text x="0" y="40" class="code" fill="#0f172a"><tspan font-weight="bold">Định tuyến:</tspan> DNAT 80,443,7443,8443 • <tspan font-weight="bold" fill="#16a34a">LAN Masquerade</tspan></text>
        <text x="0" y="54" class="code" fill="#64748b">Route Table AZ-b Default Gateway: 10.0.11.254 (Egress NAT)</text>"""

new_gw2_routing = """        <text x="0" y="40" class="code" fill="#0f172a"><tspan font-weight="bold">Cân bằng tải:</tspan> <tspan font-weight="bold" fill="#b45309">HAProxy L4 (Active W2 / Backup W1)</tspan></text>
        <text x="0" y="54" class="code" fill="#0f172a"><tspan font-weight="bold">Định tuyến:</tspan> DNAT 8443 (Wazuh SIEM) • <tspan font-weight="bold" fill="#16a34a">LAN Masquerade SNAT</tspan></text>"""

svg = svg.replace(old_gw2_routing, new_gw2_routing)

# 3. Remove Route Table from Zone Headers
svg = svg.replace("VÙNG AZ-a: Private Subnet 10.0.10.0/24 (Route: via 10.0.10.254)", "VÙNG AZ-a: Private Subnet 10.0.10.0/24")
svg = svg.replace("VÙNG AZ-b: Private Subnet 10.0.11.0/24 (Route: via 10.0.11.254)", "VÙNG AZ-b: Private Subnet 10.0.11.0/24")

# 4. Remove Route table on Worker 2
old_w2_route = '<text x="10" y="118" class="code" fill="#64748b">Route Table: Default 0.0.0.0/0 trỏ LAN Gateway 2 (10.0.11.254)</text>'
new_w2_route = '<text x="10" y="118" class="code" fill="#854d0e"><tspan font-weight="bold">Ingress-NGINX:</tspan> Port 80/443 (HostNetwork Active-Active)</text>'
svg = svg.replace(old_w2_route, new_w2_route)

# 5. Update Worker 1 & Worker 2 specs to c7i-flex.large
svg = svg.replace("Node: k8s-worker-1 (IP: 10.0.10.139 • t3.small • 2 vCPU, 2GB RAM)", "Node: k8s-worker-1 (IP: 10.0.10.139 • c7i-flex.large • 2 vCPU, 4GB RAM)")
svg = svg.replace("Node: k8s-worker-2 (IP: 10.0.11.21 • t3.small • 2 vCPU, 2GB RAM)", "Node: k8s-worker-2 (IP: 10.0.11.21 • c7i-flex.large • 2 vCPU, 4GB RAM)")

# 6. Update Card 1: Remove Route Table section and add HAProxy Failover
old_card1_route = """        <text x="0" y="100" font-size="9.5" font-weight="800" fill="#b45309">PHÂN TÁCH ROUTE PER-AZ:</text>
        <text x="8" y="113" class="code" fill="#451a03">AZ-a ra Internet qua GW1 (10.0.10.254) • AZ-b qua GW2 (10.0.11.254)</text>
        <text x="8" y="125" class="code" fill="#451a03">Tách biệt máy chủ Wazuh SIEM trong Management Subnet (10.0.20.10)</text>"""

new_card1_route = """        <text x="0" y="100" font-size="9.5" font-weight="800" fill="#b45309">HAPROXY L4 CROSS-AZ FAILOVER:</text>
        <text x="8" y="113" class="code" fill="#451a03">GW1 Active W1 / Backup W2 • GW2 Active W2 / Backup W1.</text>
        <text x="8" y="125" class="code" fill="#451a03">TCP check 2s fall 2: Tự động chuyển mạch 4s khi sập Node.</text>"""

svg = svg.replace(old_card1_route, new_card1_route)

# 7. Update Card 2: Ports table destinations
svg = svg.replace("Master:80", "Worker:80 ")
svg = svg.replace("Master:443", "Worker:443")
svg = svg.replace("HTTP (Ingress)", "HTTP (HAProxy)")
svg = svg.replace("HTTPS (TLS)", "HTTPS (HAProxy)")

# 8. Update Bottom Connection Flows
svg = svg.replace("GW1 hoặc GW2 (DNAT + LAN MASQ)", "GW1 hoặc GW2 (HAProxy L4)")
svg = svg.replace("Ingress NGINX (Master:80/443)", "Ingress NGINX (Worker 1 hoặc 2)")
svg = svg.replace("GW1 hoặc GW2 (DNAT 7443)", "GW1 hoặc GW2 (HAProxy L4)")

# Save modified SVG
output_svg = '/home/vinh/Documents/project_ncs/docs/architecture_diagram.svg'
os.makedirs(os.path.dirname(output_svg), exist_ok=True)
with open(output_svg, 'w', encoding='utf-8') as f:
    f.write(svg)

# Render to PNG
output_png = '/home/vinh/Documents/project_ncs/report/images/architecture_diagram.png'
cmd = [
    'google-chrome', '--headless', '--disable-gpu',
    f'--screenshot={output_png}',
    '--window-size=1440,820',
    output_svg
]
subprocess.run(cmd, check=True)
print("Updated architecture_diagram.svg and rendered architecture_diagram.png successfully!")
