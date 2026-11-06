import html

def build_drawio_xml():
    cells = []
    cell_id = 2

    def add_cell(value, style, x, y, width, height, parent="1"):
        nonlocal cell_id
        cid = str(cell_id)
        cell_id += 1
        val_esc = html.escape(value, quote=True)
        cells.append(f'<mxCell id="{cid}" value="{val_esc}" style="{style}" vertex="1" parent="{parent}">')
        cells.append(f'  <mxGeometry x="{x}" y="{y}" width="{width}" height="{height}" as="geometry" />')
        cells.append('</mxCell>')
        return cid

    def add_edge(source_id, target_id, label="", style=""):
        nonlocal cell_id
        cid = str(cell_id)
        cell_id += 1
        val_esc = html.escape(label, quote=True)
        default_style = "edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;"
        full_style = default_style + style
        cells.append(f'<mxCell id="{cid}" value="{val_esc}" style="{full_style}" edge="1" parent="1" source="{source_id}" target="{target_id}">')
        cells.append('  <mxGeometry relative="1" as="geometry" />')
        cells.append('</mxCell>')
        return cid

    # Header / Title
    add_cell(
        '<div style="text-align: left;"><font style="font-size: 22px; font-weight: 800; color: #0f172a;">KIẾN TRÚC AN NINH HẠ TẦNG MICROSERVICES TRÊN AWS</font><br><font style="font-size: 13px; color: #475569; font-weight: 500;">Dual-Gateway Active-Active HA • HAProxy L4 Cross-AZ Failover • Upstream K8s v1.31 • Multi-AZ Ingress • Cilium eBPF CNI • Wazuh SIEM</font></div>',
        "text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;",
        40, 25, 1100, 50
    )

    # AWS Badge
    add_cell(
        '<b>AWS Singapore ap-southeast-1 • VPC 10.0.0.0/16</b>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#16a34a;strokeWidth=2;fontColor=#15803d;fontSize=12;fontStyle=1;",
        1180, 30, 340, 40
    )

    # Header Divider Line
    add_cell(
        '',
        "line;strokeWidth=2;strokeColor=#e2e8f0;html=1;",
        40, 85, 1480, 10
    )

    # Internet Client / Admin Box
    client_box = add_cell(
        '<div style="font-size: 13px; font-weight: 800; color: #0369a1; text-transform: uppercase; margin-bottom: 6px;">INTERNET CLIENT / SYSTEM ADMINISTRATOR</div>'
        '<div style="font-size: 11px; color: #0284c7; font-weight: 600;">'
        '<span style="background: #ffffff; border: 1px solid #bae6fd; border-radius: 4px; padding: 2px 6px; margin: 0 3px;">Web HTTP: <b>80</b></span>'
        '<span style="background: #ffffff; border: 1px solid #bae6fd; border-radius: 4px; padding: 2px 6px; margin: 0 3px;">Web HTTPS: <b>443</b></span>'
        '<span style="background: #ffffff; border: 1px solid #bae6fd; border-radius: 4px; padding: 2px 6px; margin: 0 3px;">Rancher: <b>7443</b></span>'
        '<span style="background: #ffffff; border: 1px solid #bae6fd; border-radius: 4px; padding: 2px 6px; margin: 0 3px;">Wazuh SIEM: <b>8443</b></span>'
        '<span style="background: #ffffff; border: 1px solid #bae6fd; border-radius: 4px; padding: 2px 6px; margin: 0 3px;">Hubble UI: <b>31235</b></span>'
        '<span style="background: #ffffff; border: 1px solid #bae6fd; border-radius: 4px; padding: 2px 6px; margin: 0 3px;">SSH Bastion: <b>22</b></span>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#0284c7;strokeWidth=2;align=center;",
        450, 105, 660, 65
    )

    # AWS NLB Box
    nlb_box = add_cell(
        '<div style="font-size: 13px; font-weight: 800; color: #b45309; text-transform: uppercase;">AWS NETWORK LOAD BALANCER (LAYER 4 TCP - ACTIVE-ACTIVE CROSS-ZONE)</div>'
        '<div style="font-size: 11px; color: #78350f; font-weight: 600; margin-top: 3px;">'
        'DNS: ncs-project-nlb-fa5afa04f4f63ce1.elb.ap-southeast-1.amazonaws.com • Target Groups: Port 80, 443, 7443, 8443'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#fffbeb;strokeColor=#d97706;strokeWidth=2;align=center;",
        380, 205, 800, 65
    )

    # Edge from Client to NLB
    add_edge(client_box, nlb_box, "", "strokeColor=#0284c7;endArrow=classic;strokeWidth=2;")

    # Gateway 1 Box (AZ-a)
    gw1_box = add_cell(
        '<div style="text-align: left; padding: 6px;">'
        '<div style="display: flex; justify-content: space-between; border-bottom: 1px solid #bbf7d0; padding-bottom: 4px; margin-bottom: 6px;">'
        '  <span style="font-size: 13px; font-weight: 800; color: #065f46;">Gateway 1 (pfsense-gateway-1)</span>'
        '  <span style="float: right; font-size: 11px; font-weight: 700; color: #047857; background: #dcfce7; padding: 2px 8px; border-radius: 4px;">AZ ap-southeast-1a • Subnet 10.0.1.0/24</span>'
        '</div>'
        '<table style="width: 100%; font-size: 11px; margin-bottom: 6px;">'
        '  <tr>'
        '    <td style="width: 50%; background: #ffffff; border: 1px solid #cbd5e1; border-radius: 4px; padding: 4px 8px;">'
        '      <span style="color: #64748b; font-size: 9px; font-weight: 700; text-transform: uppercase;">WAN Interface (ens5)</span><br>'
        '      <b>10.0.1.10</b> <span style="color: #0284c7;">(EIP: 13.251.225.100)</span>'
        '    </td>'
        '    <td style="width: 8px;"></td>'
        '    <td style="width: 50%; background: #ffffff; border: 1px solid #cbd5e1; border-radius: 4px; padding: 4px 8px;">'
        '      <span style="color: #64748b; font-size: 9px; font-weight: 700; text-transform: uppercase;">LAN Transit (ens6)</span><br>'
        '      <b>10.0.10.254</b> <span style="color: #16a34a;">(Route 0.0.0.0/0)</span>'
        '    </td>'
        '  </tr>'
        '</table>'
        '<div style="font-size: 10px; font-weight: 600;">'
        '  <span style="background: #dcfce7; border: 1px solid #a7f3d0; border-radius: 4px; padding: 2px 6px; color: #065f46; margin-right: 4px;">Suricata DPI (af-packet)</span>'
        '  <span style="background: #fef3c7; border: 1px solid #f59e0b; border-radius: 4px; padding: 2px 6px; color: #b45309; font-weight: 800; margin-right: 4px;">HAProxy L4 (Active W1 / Backup W2)</span>'
        '  <span style="background: #dcfce7; border: 1px solid #a7f3d0; border-radius: 4px; padding: 2px 6px; color: #065f46; margin-right: 4px;">Wazuh Agent (eve.json)</span>'
        '  <span style="background: #dcfce7; border: 1px solid #a7f3d0; border-radius: 4px; padding: 2px 6px; color: #065f46;">SSH Bastion</span>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#059669;strokeWidth=2;align=left;verticalAlign=top;",
        40, 310, 720, 135
    )

    # Gateway 2 Box (AZ-b)
    gw2_box = add_cell(
        '<div style="text-align: left; padding: 6px;">'
        '<div style="display: flex; justify-content: space-between; border-bottom: 1px solid #bbf7d0; padding-bottom: 4px; margin-bottom: 6px;">'
        '  <span style="font-size: 13px; font-weight: 800; color: #065f46;">Gateway 2 (pfsense-gateway-2)</span>'
        '  <span style="float: right; font-size: 11px; font-weight: 700; color: #047857; background: #dcfce7; padding: 2px 8px; border-radius: 4px;">AZ ap-southeast-1b • Subnet 10.0.2.0/24</span>'
        '</div>'
        '<table style="width: 100%; font-size: 11px; margin-bottom: 6px;">'
        '  <tr>'
        '    <td style="width: 50%; background: #ffffff; border: 1px solid #cbd5e1; border-radius: 4px; padding: 4px 8px;">'
        '      <span style="color: #64748b; font-size: 9px; font-weight: 700; text-transform: uppercase;">WAN Interface (ens5)</span><br>'
        '      <b>10.0.2.10</b> <span style="color: #0284c7;">(EIP: 18.140.131.125)</span>'
        '    </td>'
        '    <td style="width: 8px;"></td>'
        '    <td style="width: 50%; background: #ffffff; border: 1px solid #cbd5e1; border-radius: 4px; padding: 4px 8px;">'
        '      <span style="color: #64748b; font-size: 9px; font-weight: 700; text-transform: uppercase;">LAN Transit (ens6)</span><br>'
        '      <b>10.0.11.254</b> <span style="color: #16a34a;">(Route 0.0.0.0/0)</span>'
        '    </td>'
        '  </tr>'
        '</table>'
        '<div style="font-size: 10px; font-weight: 600;">'
        '  <span style="background: #dcfce7; border: 1px solid #a7f3d0; border-radius: 4px; padding: 2px 6px; color: #065f46; margin-right: 4px;">Suricata DPI (af-packet)</span>'
        '  <span style="background: #fef3c7; border: 1px solid #f59e0b; border-radius: 4px; padding: 2px 6px; color: #b45309; font-weight: 800; margin-right: 4px;">HAProxy L4 (Active W2 / Backup W1)</span>'
        '  <span style="background: #dcfce7; border: 1px solid #a7f3d0; border-radius: 4px; padding: 2px 6px; color: #065f46; margin-right: 4px;">Wazuh Agent (eve.json)</span>'
        '  <span style="background: #dcfce7; border: 1px solid #a7f3d0; border-radius: 4px; padding: 2px 6px; color: #065f46;">HA Standby</span>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#059669;strokeWidth=2;align=left;verticalAlign=top;",
        800, 310, 720, 135
    )

    # Edges from NLB to Gateways
    add_edge(nlb_box, gw1_box, "Phân bổ tải AZ-a", "strokeColor=#059669;endArrow=classic;strokeWidth=2;fontColor=#065f46;fontSize=11;fontStyle=1;")
    add_edge(nlb_box, gw2_box, "Phân bổ tải AZ-b", "strokeColor=#059669;endArrow=classic;strokeWidth=2;fontColor=#065f46;fontSize=11;fontStyle=1;")

    # Transit Divider Banner
    transit_banner = add_cell(
        '<b>▼ Luồng chuyển tiếp nội bộ qua LAN Transit (HAProxy L4 Health Check & Cross-AZ Failover: GW1 → Worker 1 [Backup Worker 2] | GW2 → Worker 2 [Backup Worker 1])</b>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#eff6ff;strokeColor=#3b82f6;strokeWidth=1;dashed=1;fontColor=#1d4ed8;fontSize=11;align=center;",
        40, 465, 1480, 32
    )

    # K8s Cluster Main Container Box
    k8s_container = add_cell(
        '<div style="text-align: left; padding: 4px;">'
        '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">'
        '  <span style="font-size: 13px; font-weight: 800; color: #6b21a8; text-transform: uppercase;">CỤM UPSTREAM KUBERNETES V1.31 (CILIUM EBPF VXLAN DATAPATH)</span>'
        '  <span style="float: right;">'
        '    <span style="background: #ede9fe; color: #5b21b6; border: 1px solid #c4b5fd; border-radius: 12px; padding: 2px 8px; font-size: 10px; font-weight: 700; margin-right: 4px;">Pod Network: 10.244.0.0/16 (UDP 8472)</span>'
        '    <span style="background: #ede9fe; color: #5b21b6; border: 1px solid #c4b5fd; border-radius: 12px; padding: 2px 8px; font-size: 10px; font-weight: 700; margin-right: 4px;">Multi-AZ Dual Ingress (Active-Active)</span>'
        '    <span style="background: #ede9fe; color: #5b21b6; border: 1px solid #c4b5fd; border-radius: 12px; padding: 2px 8px; font-size: 10px; font-weight: 700;">Zero-Trust Network Policies O(1)</span>'
        '  </span>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#faf5ff;strokeColor=#7e22ce;strokeWidth=2;align=left;verticalAlign=top;",
        40, 515, 1480, 315
    )

    # Master Node Card
    master_card = add_cell(
        '<div style="text-align: left; padding: 4px;">'
        '<div style="border-bottom: 1px solid #f1f5f9; padding-bottom: 3px; margin-bottom: 6px;">'
        '  <span style="font-size: 12px; font-weight: 800; color: #b45309;">k8s-master (AZ-a)</span>'
        '  <span style="float: right; font-size: 11px; font-weight: 700; color: #0284c7;">10.0.10.10</span><br>'
        '  <span style="font-size: 9.5px; color: #64748b;">c7i-flex.large (2 vCPU, 4GB RAM) • Taint: NoSchedule (Dedicated Control Plane)</span>'
        '</div>'
        '<table style="width: 100%; font-size: 11px; line-height: 1.5;">'
        '  <tr><td>Control Plane (etcd, apiserver)</td><td style="text-align: right; font-weight: 700; color: #0f172a;">v1.31.14</td></tr>'
        '  <tr style="background: #f3e8ff;"><td><b style="color: #6b21a8;">Rancher Server v2.9</b></td><td style="text-align: right; font-weight: 700; color: #6b21a8;">Port 30443</td></tr>'
        '  <tr><td>Wazuh Agent (K8s Audit Log)</td><td style="text-align: right; font-weight: 700; color: #0f172a;">audit.log</td></tr>'
        '  <tr><td>Control Plane Isolation</td><td style="text-align: right; font-weight: 700; color: #16a34a;">Secured</td></tr>'
        '</table>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#fffdfa;strokeColor=#f59e0b;strokeWidth=1.5;align=left;verticalAlign=top;",
        60, 560, 460, 195
    )

    # Worker 1 Node Card
    worker1_card = add_cell(
        '<div style="text-align: left; padding: 4px;">'
        '<div style="border-bottom: 1px solid #f1f5f9; padding-bottom: 3px; margin-bottom: 6px;">'
        '  <span style="font-size: 12px; font-weight: 800; color: #1d4ed8;">k8s-worker-1 (AZ-a)</span>'
        '  <span style="float: right; font-size: 11px; font-weight: 700; color: #0284c7;">10.0.10.139</span><br>'
        '  <span style="font-size: 9.5px; color: #64748b;">c7i-flex.large (2 vCPU, 4GB RAM) • Private Subnet A</span>'
        '</div>'
        '<table style="width: 100%; font-size: 11px; line-height: 1.5;">'
        '  <tr style="background: #fef08a;"><td><b style="color: #854d0e;">Ingress-NGINX (hostNetwork)</b></td><td style="text-align: right; font-weight: 800; color: #854d0e;">Port 80/443</td></tr>'
        '  <tr><td>Online Boutique Microservices</td><td style="text-align: right; font-weight: 700; color: #0f172a;">frontend, cart</td></tr>'
        '  <tr><td>Online Boutique Microservices</td><td style="text-align: right; font-weight: 700; color: #0f172a;">checkout, email</td></tr>'
        '  <tr><td>Cilium eBPF Datapath & Agent</td><td style="text-align: right; font-weight: 700; color: #0f172a;">v1.16.2</td></tr>'
        '  <tr><td>Wazuh Agent (OS Security)</td><td style="text-align: right; font-weight: 700; color: #16a34a;">Active</td></tr>'
        '</table>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#3b82f6;strokeWidth=1.5;align=left;verticalAlign=top;",
        550, 560, 460, 195
    )

    # Worker 2 Node Card
    worker2_card = add_cell(
        '<div style="text-align: left; padding: 4px;">'
        '<div style="border-bottom: 1px solid #f1f5f9; padding-bottom: 3px; margin-bottom: 6px;">'
        '  <span style="font-size: 12px; font-weight: 800; color: #1d4ed8;">k8s-worker-2 (AZ-b)</span>'
        '  <span style="float: right; font-size: 11px; font-weight: 700; color: #0284c7;">10.0.11.21</span><br>'
        '  <span style="font-size: 9.5px; color: #64748b;">c7i-flex.large (2 vCPU, 4GB RAM) • Private Subnet B</span>'
        '</div>'
        '<table style="width: 100%; font-size: 11px; line-height: 1.5;">'
        '  <tr style="background: #fef08a;"><td><b style="color: #854d0e;">Ingress-NGINX (hostNetwork)</b></td><td style="text-align: right; font-weight: 800; color: #854d0e;">Port 80/443</td></tr>'
        '  <tr><td>Online Boutique Microservices</td><td style="text-align: right; font-weight: 700; color: #0f172a;">payment, redis</td></tr>'
        '  <tr><td>Online Boutique Microservices</td><td style="text-align: right; font-weight: 700; color: #0f172a;">currency, product</td></tr>'
        '  <tr><td>Cilium eBPF Datapath & Agent</td><td style="text-align: right; font-weight: 700; color: #0f172a;">v1.16.2</td></tr>'
        '  <tr><td>Wazuh Agent (OS Security)</td><td style="text-align: right; font-weight: 700; color: #16a34a;">Active</td></tr>'
        '</table>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#3b82f6;strokeWidth=1.5;align=left;verticalAlign=top;",
        1040, 560, 460, 195
    )

    # K8s Bottom Bar (Hubble & NetPol)
    add_cell(
        '<div style="display: flex; justify-content: space-between; align-items: center; width: 100%; font-size: 11px;">'
        '  <span style="color: #581c87; font-weight: 700;">Hubble Observability: Hubble Relay & Hubble UI NodePort 31235 (Quan sát luồng mạng thời gian thực L3, L4, L7)</span>'
        '  <span style="float: right; color: #581c87; font-weight: 700;">CiliumNetworkPolicy: allow-ingress-host-to-frontend • Zero-Trust Micro-segmentation</span>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#a855f7;strokeWidth=1.5;align=left;padding=6;",
        60, 770, 1440, 40
    )

    # Wazuh Dedicated Server Box
    wazuh_box = add_cell(
        '<div style="text-align: left; padding: 4px;">'
        '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">'
        '  <div>'
        '    <span style="font-size: 13px; font-weight: 800; color: #0f766e; text-transform: uppercase;">MÁY CHỦ WAZUH SIEM CHUYÊN BIỆT (DEDICATED SOC SERVER)</span><br>'
        '    <span style="font-size: 10px; color: #475569;">Management Subnet: 10.0.20.0/24 • Instance: t3.large (2 vCPU, 8GB RAM, 50GB gp3)</span>'
        '  </div>'
        '  <div style="float: right;">'
        '    <span style="background: #ffffff; border: 1px solid #cbd5e1; border-radius: 4px; padding: 3px 8px; font-size: 11px; margin-right: 4px;"><b>10.0.20.10</b> <span style="color: #64748b; font-size: 9px;">Private IP</span></span>'
        '    <span style="background: #ffffff; border: 1px solid #0d9488; border-radius: 4px; padding: 3px 8px; font-size: 11px; margin-right: 4px; color: #0f766e;"><b>Wazuh Manager v4.9</b> <span style="font-size: 9px;">SIEM Engine</span></span>'
        '    <span style="background: #ffffff; border: 1px solid #0d9488; border-radius: 4px; padding: 3px 8px; font-size: 11px; margin-right: 4px; color: #0f766e;"><b>OpenSearch Indexer</b> <span style="font-size: 9px;">Security DB</span></span>'
        '    <span style="background: #ffffff; border: 1px solid #0d9488; border-radius: 4px; padding: 3px 8px; font-size: 11px; margin-right: 4px; color: #0f766e;"><b>Wazuh Dashboard</b> <span style="font-size: 9px;">Port 8443</span></span>'
        '    <span style="background: #ffffff; border: 1px solid #0d9488; border-radius: 4px; padding: 3px 8px; font-size: 11px; margin-right: 8px; color: #0f766e;"><b>REST API</b> <span style="font-size: 9px;">Port 55000</span></span>'
        '    <span style="background: #fef2f2; border: 1px solid #ef4444; border-radius: 6px; padding: 4px 10px; font-size: 11px; font-weight: 700; color: #b91c1c;">Thu thập Log TLS 1514 (Suricata eve.json & K8s audit.log từ 5 Agents)</span>'
        '  </div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdfa;strokeColor=#0d9488;strokeWidth=2;align=left;verticalAlign=middle;",
        40, 845, 1480, 80
    )

    # Connections between Gateways and Workers (Active / Backup)
    # GW1 -> Worker 1 (Primary)
    add_edge(gw1_box, worker1_card, "Active L4", "strokeColor=#16a34a;endArrow=classic;strokeWidth=2.5;fontColor=#15803d;fontSize=10;fontStyle=1;")
    # GW1 -> Worker 2 (Backup)
    add_edge(gw1_box, worker2_card, "Backup L4", "strokeColor=#f59e0b;dashed=1;endArrow=classic;strokeWidth=1.5;fontColor=#b45309;fontSize=10;")

    # GW2 -> Worker 2 (Primary)
    add_edge(gw2_box, worker2_card, "Active L4", "strokeColor=#16a34a;endArrow=classic;strokeWidth=2.5;fontColor=#15803d;fontSize=10;fontStyle=1;")
    # GW2 -> Worker 1 (Backup)
    add_edge(gw2_box, worker1_card, "Backup L4", "strokeColor=#f59e0b;dashed=1;endArrow=classic;strokeWidth=1.5;fontColor=#b45309;fontSize=10;")

    # Gateways -> Wazuh SIEM
    add_edge(gw1_box, wazuh_box, "DNAT 8443", "strokeColor=#0d9488;dashed=1;endArrow=classic;strokeWidth=1.5;fontColor=#0f766e;fontSize=10;")

    xml_header = (
        '<mxfile host="app.diagrams.net" modified="2026-11-06T00:45:00.000Z" agent="Antigravity Agent" version="24.0.0" type="device">\n'
        '  <diagram id="ncs-k8s-architecture" name="Kiến Trúc NCS Project K8s">\n'
        '    <mxGraphModel dx="1600" dy="1100" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="1000" math="0" shadow="0">\n'
        '      <root>\n'
        '        <mxCell id="0" />\n'
        '        <mxCell id="1" parent="0" />\n'
    )
    xml_footer = (
        '      </root>\n'
        '    </mxGraphModel>\n'
        '  </diagram>\n'
        '</mxfile>\n'
    )

    return xml_header + '\n'.join('        ' + c for c in cells) + '\n' + xml_footer

if __name__ == '__main__':
    content = build_drawio_xml()
    
    paths = [
        '/home/vinh/Documents/project_ncs/report/images/diagram.drawio',
        '/home/vinh/Documents/project_ncs/report/images/architecture_diagram.drawio'
    ]
    for p in paths:
        with open(p, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Written Draw.io diagram to {p} ({len(content)} bytes)")
