import subprocess
import os

html_content = """<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
  body { background: #ffffff; padding: 24px 30px; width: 1560px; height: 960px; }
  
  /* Header */
  .header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 16px; border-bottom: 2px solid #e2e8f0; padding-bottom: 12px; }
  .title-group h1 { font-size: 20px; font-weight: 800; color: #0f172a; text-transform: uppercase; letter-spacing: 0.5px; }
  .title-group p { font-size: 12px; color: #475569; margin-top: 3px; font-weight: 500; }
  .aws-badge { background: #f0fdf4; border: 1.5px solid #16a34a; border-radius: 20px; padding: 6px 14px; font-size: 11px; font-weight: 700; color: #15803d; }

  /* Client Box */
  .client-bar { background: #f8fafc; border: 2px solid #0284c7; border-radius: 12px; padding: 8px 16px; text-align: center; margin: 0 auto 10px auto; width: 660px; }
  .client-title { font-size: 12px; font-weight: 800; color: #0369a1; text-transform: uppercase; margin-bottom: 5px; }
  .ports-list { display: flex; justify-content: center; gap: 8px; }
  .port-pill { background: #ffffff; border: 1px solid #bae6fd; border-radius: 6px; padding: 3px 8px; font-size: 10px; font-weight: 600; color: #0284c7; }
  .port-pill span { font-weight: 700; color: #0f172a; }

  /* Flow arrows */
  .down-arrow { text-align: center; font-size: 14px; color: #0284c7; line-height: 14px; margin-bottom: 6px; }

  /* NLB Box */
  .nlb-box { background: #fffbeb; border: 2px solid #d97706; border-radius: 12px; padding: 8px 16px; text-align: center; margin: 0 auto 10px auto; width: 760px; }
  .nlb-title { font-size: 13px; font-weight: 800; color: #b45309; text-transform: uppercase; }
  .nlb-desc { font-size: 10px; color: #78350f; font-weight: 600; margin-top: 2px; }

  /* Gateways row */
  .gateways-container { display: flex; justify-content: space-between; gap: 20px; margin-bottom: 12px; }
  .gw-card { flex: 1; background: #f0fdf4; border: 2px solid #059669; border-radius: 12px; padding: 10px 14px; }
  .gw-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; padding-bottom: 5px; border-bottom: 1px solid #bbf7d0; }
  .gw-title { font-size: 12px; font-weight: 800; color: #065f46; }
  .gw-az { font-size: 10px; font-weight: 700; color: #047857; background: #dcfce7; padding: 2px 7px; border-radius: 5px; }
  .gw-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 6px; }
  .gw-col { background: #ffffff; border: 1px solid #cbd5e1; border-radius: 6px; padding: 5px 8px; font-size: 10px; }
  .gw-col strong { display: block; color: #0f172a; font-size: 9px; text-transform: uppercase; margin-bottom: 2px; }
  .gw-features { display: flex; gap: 6px; font-size: 9.5px; font-weight: 600; color: #065f46; }
  .gw-feat { background: #dcfce7; border-radius: 4px; padding: 2px 6px; border: 1px solid #a7f3d0; }
  .gw-feat.haproxy { background: #fef3c7; border-color: #f59e0b; color: #b45309; font-weight: 700; }

  /* Transit divider */
  .transit-banner { text-align: center; font-size: 11px; font-weight: 700; color: #1d4ed8; background: #eff6ff; border: 1px dashed #3b82f6; border-radius: 6px; padding: 4px; margin-bottom: 12px; }

  /* K8s Subnet Box */
  .k8s-box { background: #faf5ff; border: 2px solid #7e22ce; border-radius: 12px; padding: 10px 14px; margin-bottom: 12px; }
  .k8s-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
  .k8s-title { font-size: 13px; font-weight: 800; color: #6b21a8; text-transform: uppercase; }
  .k8s-tags { display: flex; gap: 6px; }
  .k8s-tag { font-size: 10px; font-weight: 700; padding: 2px 8px; border-radius: 12px; background: #ede9fe; color: #5b21b6; border: 1px solid #c4b5fd; }

  .nodes-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 14px; }
  .node-card { background: #ffffff; border: 1.5px solid #cbd5e1; border-radius: 8px; padding: 9px 11px; }
  .node-card.master { border-color: #f59e0b; background: #fffdfa; }
  .node-card.worker { border-color: #3b82f6; }
  .node-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; border-bottom: 1px solid #f1f5f9; padding-bottom: 4px; }
  .node-name { font-size: 12px; font-weight: 800; color: #0f172a; }
  .node-ip { font-size: 11px; font-weight: 800; color: #1d4ed8; font-family: monospace; }
  .node-sub { font-size: 9.5px; color: #64748b; margin-bottom: 6px; font-weight: 600; }
  .node-body { font-size: 10px; line-height: 1.5; color: #1e293b; }
  .highlight-row { background: #fef08a; padding: 2px 4px; border-radius: 4px; font-weight: 700; color: #854d0e; display: flex; justify-content: space-between; margin-bottom: 3px; }
  .normal-row { display: flex; justify-content: space-between; margin-bottom: 2px; }
  .normal-row span:first-child { color: #475569; }
  .normal-row span:last-child { font-weight: 700; }

  /* Hubble and Policy bar */
  .observability-bar { margin-top: 10px; background: #ffffff; border: 1.5px solid #9333ea; border-radius: 8px; padding: 6px 12px; display: flex; justify-content: space-between; font-size: 10px; font-weight: 700; color: #581c87; }

  /* Wazuh SIEM Box */
  .wazuh-box { background: #f0fdfa; border: 2px solid #0d9488; border-radius: 12px; padding: 9px 14px; display: flex; justify-content: space-between; align-items: center; }
  .wazuh-left h3 { font-size: 12px; font-weight: 800; color: #115e59; text-transform: uppercase; }
  .wazuh-left p { font-size: 10px; color: #0f766e; font-weight: 500; }
  .wazuh-pills { display: flex; gap: 8px; }
  .wazuh-pill { background: #ffffff; border: 1.5px solid #5eead4; border-radius: 6px; padding: 4px 8px; font-size: 10px; text-align: center; }
  .wazuh-pill strong { display: block; color: #0f766e; font-size: 10.5px; }
  .wazuh-pill span { color: #334155; font-size: 9px; font-weight: 600; }
</style>
</head>
<body>

<div class="header">
  <div class="title-group">
    <h1>KIẾN TRÚC AN NINH HẠ TẦNG MICROSERVICES TRÊN AWS</h1>
    <p>Dual-Gateway Active-Active HA • HAProxy L4 Cross-AZ Failover • Upstream K8s v1.31 • Multi-AZ Ingress • Cilium eBPF CNI • Wazuh SIEM</p>
  </div>
  <div class="aws-badge">AWS Singapore ap-southeast-1 • VPC 10.0.0.0/16</div>
</div>

<!-- CLIENT / ADMIN -->
<div class="client-bar">
  <div class="client-title">Internet Client / System Administrator</div>
  <div class="ports-list">
    <div class="port-pill">Web HTTP: <span>80</span></div>
    <div class="port-pill">Web HTTPS: <span>443</span></div>
    <div class="port-pill">Rancher: <span>7443</span></div>
    <div class="port-pill">Wazuh SIEM: <span>8443</span></div>
    <div class="port-pill">Hubble UI: <span>31235</span></div>
    <div class="port-pill">SSH Bastion: <span>22</span></div>
  </div>
</div>

<div class="down-arrow">▼</div>

<!-- AWS NLB -->
<div class="nlb-box">
  <div class="nlb-title">AWS Network Load Balancer (Layer 4 TCP - Active-Active Cross-Zone)</div>
  <div class="nlb-desc">DNS: ncs-project-nlb-fa5afa04f4f63ce1.elb.ap-southeast-1.amazonaws.com • Target Groups: Port 80, 443, 7443, 8443</div>
</div>

<div style="display:flex; justify-content:space-around; font-size:10px; font-weight:700; color:#047857; margin-bottom:4px;">
  <span>↙ Phân bổ tải AZ-a</span>
  <span>Phân bổ tải AZ-b ↘</span>
</div>

<!-- DUAL GATEWAY -->
<div class="gateways-container">
  <!-- GW 1 -->
  <div class="gw-card">
    <div class="gw-header">
      <div class="gw-title">Gateway 1 (pfsense-gateway-1)</div>
      <div class="gw-az">AZ ap-southeast-1a • Subnet 10.0.1.0/24</div>
    </div>
    <div class="gw-grid">
      <div class="gw-col">
        <strong>WAN Interface (ens5)</strong>
        10.0.1.10 (EIP: 13.251.225.100)
      </div>
      <div class="gw-col">
        <strong>LAN Transit (ens6)</strong>
        10.0.10.254 (Route 0.0.0.0/0)
      </div>
    </div>
    <div class="gw-features">
      <div class="gw-feat">Suricata DPI (af-packet)</div>
      <div class="gw-feat haproxy">HAProxy L4 (Active W1 / Backup W2)</div>
      <div class="gw-feat">Wazuh Agent (eve.json)</div>
      <div class="gw-feat">SSH Bastion</div>
    </div>
  </div>

  <!-- GW 2 -->
  <div class="gw-card">
    <div class="gw-header">
      <div class="gw-title">Gateway 2 (pfsense-gateway-2)</div>
      <div class="gw-az">AZ ap-southeast-1b • Subnet 10.0.2.0/24</div>
    </div>
    <div class="gw-grid">
      <div class="gw-col">
        <strong>WAN Interface (ens5)</strong>
        10.0.2.10 (EIP: 18.140.131.125)
      </div>
      <div class="gw-col">
        <strong>LAN Transit (ens6)</strong>
        10.0.11.254 (Route 0.0.0.0/0)
      </div>
    </div>
    <div class="gw-features">
      <div class="gw-feat">Suricata DPI (af-packet)</div>
      <div class="gw-feat haproxy">HAProxy L4 (Active W2 / Backup W1)</div>
      <div class="gw-feat">Wazuh Agent (eve.json)</div>
      <div class="gw-feat">HA Standby</div>
    </div>
  </div>
</div>

<div class="transit-banner">
  ▼ Luồng chuyển tiếp nội bộ qua LAN Transit (HAProxy L4 Health Check & Cross-AZ Failover: GW1 &rarr; Worker 1 [Backup Worker 2] | GW2 &rarr; Worker 2 [Backup Worker 1])
</div>

<!-- K8S CLUSTER -->
<div class="k8s-box">
  <div class="k8s-header">
    <div class="k8s-title">CỤM UPSTREAM KUBERNETES v1.31 (Cilium eBPF VXLAN Datapath)</div>
    <div class="k8s-tags">
      <div class="k8s-tag">Pod Network: 10.244.0.0/16 (UDP 8472)</div>
      <div class="k8s-tag">Multi-AZ Dual Ingress (Active-Active)</div>
      <div class="k8s-tag">Zero-Trust Network Policies O(1)</div>
    </div>
  </div>

  <div class="nodes-grid">
    <!-- MASTER -->
    <div class="node-card master">
      <div class="node-head">
        <div class="node-name">k8s-master (AZ-a)</div>
        <div class="node-ip">10.0.10.10</div>
      </div>
      <div class="node-sub">c7i-flex.large (2 vCPU, 4GB RAM) • Taint: NoSchedule (Dedicated Control Plane)</div>
      <div class="node-body">
        <div class="normal-row">
          <span>Control Plane (etcd, apiserver)</span>
          <span>v1.31.14</span>
        </div>
        <div class="highlight-row" style="background:#f3e8ff; color:#6b21a8;">
          <span>Rancher Server v2.9</span>
          <span>Port 30443</span>
        </div>
        <div class="normal-row">
          <span>Wazuh Agent (K8s Audit Log)</span>
          <span>audit.log</span>
        </div>
        <div class="normal-row" style="margin-top:4px; font-size:9.5px; color:#16a34a; font-weight:700;">
          <span>Control Plane Isolation</span>
          <span>Secured</span>
        </div>
      </div>
    </div>

    <!-- WORKER 1 -->
    <div class="node-card worker">
      <div class="node-head">
        <div class="node-name">k8s-worker-1 (AZ-a)</div>
        <div class="node-ip">10.0.10.139</div>
      </div>
      <div class="node-sub">c7i-flex.large (2 vCPU, 4GB RAM) • Private Subnet A</div>
      <div class="node-body">
        <div class="highlight-row">
          <span>Ingress-NGINX (hostNetwork)</span>
          <span>Port 80/443</span>
        </div>
        <div class="normal-row">
          <span>Online Boutique Microservices</span>
          <span>frontend, cart</span>
        </div>
        <div class="normal-row">
          <span>Online Boutique Microservices</span>
          <span>checkout, email</span>
        </div>
        <div class="normal-row">
          <span>Cilium eBPF Datapath & Agent</span>
          <span>v1.16.2</span>
        </div>
        <div class="normal-row">
          <span>Wazuh Agent (OS Security)</span>
          <span>Active</span>
        </div>
      </div>
    </div>

    <!-- WORKER 2 -->
    <div class="node-card worker">
      <div class="node-head">
        <div class="node-name">k8s-worker-2 (AZ-b)</div>
        <div class="node-ip">10.0.11.21</div>
      </div>
      <div class="node-sub">c7i-flex.large (2 vCPU, 4GB RAM) • Private Subnet B</div>
      <div class="node-body">
        <div class="highlight-row">
          <span>Ingress-NGINX (hostNetwork)</span>
          <span>Port 80/443</span>
        </div>
        <div class="normal-row">
          <span>Online Boutique Microservices</span>
          <span>payment, redis</span>
        </div>
        <div class="normal-row">
          <span>Online Boutique Microservices</span>
          <span>currency, product</span>
        </div>
        <div class="normal-row">
          <span>Cilium eBPF Datapath & Agent</span>
          <span>v1.16.2</span>
        </div>
        <div class="normal-row">
          <span>Wazuh Agent (OS Security)</span>
          <span>Active</span>
        </div>
      </div>
    </div>
  </div>

  <div class="observability-bar">
    <div>Hubble Observability: Hubble Relay & Hubble UI NodePort 31235 (Quan sát luồng mạng thời gian thực L3, L4, L7)</div>
    <div>CiliumNetworkPolicy: allow-ingress-host-to-frontend • Zero-Trust Micro-segmentation</div>
  </div>
</div>

<!-- WAZUH SIEM -->
<div class="wazuh-box">
  <div class="wazuh-left">
    <h3>MÁY CHỦ WAZUH SIEM CHUYÊN BIỆT (Dedicated SOC Server)</h3>
    <p>Management Subnet: 10.0.20.0/24 • Instance: t3.large (2 vCPU, 8GB RAM, 50GB gp3)</p>
  </div>
  <div class="wazuh-pills">
    <div class="wazuh-pill">
      <strong>10.0.20.10</strong>
      <span>Private IP</span>
    </div>
    <div class="wazuh-pill">
      <strong>Wazuh Manager v4.9</strong>
      <span>SIEM Engine</span>
    </div>
    <div class="wazuh-pill">
      <strong>OpenSearch Indexer</strong>
      <span>Security Database</span>
    </div>
    <div class="wazuh-pill">
      <strong>Wazuh Dashboard</strong>
      <span>Port 8443</span>
    </div>
    <div class="wazuh-pill">
      <strong>REST API</strong>
      <span>Port 55000</span>
    </div>
    <div class="wazuh-pill" style="border-color:#f43f5e; background:#fff1f2;">
      <strong style="color:#be123c;">Thu thập Log TLS 1514</strong>
      <span>Suricata eve.json & K8s audit.log từ 5 Agents</span>
    </div>
  </div>
</div>

</body>
</html>
"""

html_path = "/home/vinh/Documents/project_ncs/diagram.html"
png_path = "/home/vinh/Documents/project_ncs/report/images/architecture_diagram.png"

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_content)

cmd = [
    "google-chrome",
    "--headless",
    "--disable-gpu",
    "--no-sandbox",
    "--hide-scrollbars",
    "--force-device-scale-factor=1.5",
    "--window-size=1560,960",
    f"--screenshot={png_path}",
    html_path
]

subprocess.run(cmd, check=True)
os.remove(html_path)
print("Updated architecture_diagram.png successfully with HAProxy L4!")
