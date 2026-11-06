import html

def build_drawio_xml():
    cells = []
    cell_id = 2

    def add_cell(value, style, x, y, width, height, parent="1"):
        nonlocal cell_id
        cid = str(cell_id)
        cell_id += 1
        val_esc = html.escape(value, quote=True) if value else ""
        cells.append(f'<mxCell id="{cid}" value="{val_esc}" style="{style}" vertex="1" parent="{parent}">')
        cells.append(f'  <mxGeometry x="{x}" y="{y}" width="{width}" height="{height}" as="geometry" />')
        cells.append('</mxCell>')
        return cid

    def add_edge(source_id, target_id, label="", style=""):
        nonlocal cell_id
        cid = str(cell_id)
        cell_id += 1
        val_esc = html.escape(label, quote=True) if label else ""
        default_style = "edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=1.5;"
        full_style = default_style + style
        cells.append(f'<mxCell id="{cid}" value="{val_esc}" style="{full_style}" edge="1" parent="1" source="{source_id}" target="{target_id}">')
        cells.append('  <mxGeometry relative="1" as="geometry" />')
        cells.append('</mxCell>')
        return cid

    # Outer canvas border
    add_cell(
        '',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#e2e8f0;strokeWidth=1.2;shadow=0;",
        12, 10, 1416, 800
    )

    # =========================================================================
    # 1. TOP INGRESS FLOW: LAPTOPS -> INTERNET -> AWS NLB (L4 ACTIVE-ACTIVE)
    # =========================================================================
    # Client Laptop
    client_laptop = add_cell(
        '<div style="text-align: center; font-weight: 700; color: #0369a1; font-size: 11px;">'
        '<div style="font-size: 16px; margin-bottom: 2px;">💻</div>Khách hàng Web</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#cbd5e1;strokeWidth=1;align=center;",
        140, 20, 120, 48
    )

    # Cloud: INTERNET
    internet_cloud = add_cell(
        '<div style="text-align: center;">'
        '<b style="font-size: 12px; color: #1e40af;">INTERNET</b><br>'
        '<span style="font-size: 9.5px; font-weight: 700; color: #2563eb;">Public Traffic</span>'
        '</div>',
        "ellipse;shape=cloud;whiteSpace=wrap;html=1;fillColor=#eff6ff;strokeColor=#3b82f6;strokeWidth=1.6;align=center;",
        370, 12, 130, 60
    )

    # Admin / SOC Team
    admin_team = add_cell(
        '<div style="text-align: center; font-weight: 700; color: #4338ca; font-size: 11px;">'
        '<div style="font-size: 16px; margin-bottom: 2px;">🛡️</div>Admin &amp; SOC Team</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#cbd5e1;strokeWidth=1;align=center;",
        620, 20, 130, 48
    )

    # AWS NLB Block
    nlb_block = add_cell(
        '<div style="text-align: left; padding: 2px;">'
        '<div style="display: flex; justify-content: space-between; border-bottom: 1px solid #bbf7d0; padding-bottom: 2px; margin-bottom: 3px;">'
        '  <b style="font-size: 11px; color: #15803d;">AWS Network Load Balancer (NLB L4 - Multi-AZ)</b>'
        '  <span style="float: right; font-size: 9.5px; font-weight: 700; color: #16a34a; background: #dcfce7; padding: 1px 6px; border-radius: 4px;">Active-Active HA</span>'
        '</div>'
        '<div style="font-size: 9px; font-family: monospace; font-weight: 700; color: #15803d;">DNS: ncs-project-nlb-fa5afa04f4f63ce1.elb.ap-southeast-1.amazonaws.com</div>'
        '<div style="font-size: 9px; font-family: monospace; color: #334155;">Ports: 80 (HTTP) • 443 (HTTPS) • 7443 (Rancher) • 8443 (Wazuh SIEM)</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#16a34a;strokeWidth=1.5;align=left;verticalAlign=top;",
        820, 14, 460, 56
    )

    # Arrows in Top Bar
    add_edge(client_laptop, internet_cloud, "", "strokeColor=#059669;strokeWidth=1.5;dashed=1;endArrow=classic;")
    add_edge(admin_team, internet_cloud, "", "strokeColor=#7c3aed;strokeWidth=1.5;dashed=1;endArrow=classic;")
    add_edge(internet_cloud, nlb_block, "", "strokeColor=#0284c7;strokeWidth=2;endArrow=classic;")

    # =========================================================================
    # 2. MAIN CONTAINER: AMAZON VPC (Singapore ap-southeast-1)
    # =========================================================================
    # VPC Container Boundary
    vpc_box = add_cell(
        '<div style="text-align: left; padding: 4px;">'
        '<div style="display: flex; justify-content: space-between; align-items: center;">'
        '  <span style="background: #0f172a; color: #ffffff; padding: 3px 10px; border-radius: 4px; font-size: 11px; font-weight: 800;">Amazon VPC: 10.0.0.0/16 (ncs-project-vpc)</span>'
        '  <span style="float: right; background: #e2e8f0; color: #334155; padding: 2px 8px; border-radius: 10px; font-size: 10px; font-weight: 700;">AWS Region: ap-southeast-1</span>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#94a3b8;strokeWidth=1.5;dashed=1;align=left;verticalAlign=top;",
        36, 82, 920, 570
    )

    # -------------------------------------------------------------------------
    # DUAL EDGE GATEWAYS (ACTIVE-ACTIVE HA)
    # -------------------------------------------------------------------------
    # Gateway 1 (AZ-a)
    gw1 = add_cell(
        '<div style="text-align: left; padding: 4px;">'
        '<div style="background: #0284c7; color: #ffffff; padding: 3px 8px; border-radius: 4px 4px 0 0; margin: -4px -4px 4px -4px; font-size: 10px; font-weight: 800; display: flex; justify-content: space-between;">'
        '  <span>Gateway 1 (AZ-a): ncs-project-gateway-1</span>'
        '  <span style="float: right;">EIP: 13.251.225.100</span>'
        '</div>'
        '<div style="font-family: monospace; font-size: 9.5px; line-height: 1.45;">'
        '  <div><b style="color: #0369a1;">WAN (ens5):</b> 10.0.1.10 (Public AZ-a) • <b style="color: #0369a1;">LAN (ens6):</b> 10.0.10.254</div>'
        '  <div><b>An ninh:</b> Suricata IDS/IPS • Wazuh Agent (eve.json)</div>'
        '  <div><b>Cân bằng tải:</b> <span style="background: #fef3c7; color: #b45309; font-weight: 800; padding: 1px 4px; border-radius: 3px;">HAProxy L4 (Active W1 / Backup W2)</span></div>'
        '  <div><b>Định tuyến:</b> DNAT 8443 (Wazuh SIEM) • <b style="color: #16a34a;">LAN Masquerade SNAT</b></div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#0284c7;strokeWidth=1.5;align=left;verticalAlign=top;",
        52, 114, 430, 92
    )

    # Gateway 2 (AZ-b)
    gw2 = add_cell(
        '<div style="text-align: left; padding: 4px;">'
        '<div style="background: #7c3aed; color: #ffffff; padding: 3px 8px; border-radius: 4px 4px 0 0; margin: -4px -4px 4px -4px; font-size: 10px; font-weight: 800; display: flex; justify-content: space-between;">'
        '  <span>Gateway 2 (AZ-b): ncs-project-gateway-2</span>'
        '  <span style="float: right;">EIP: 18.140.131.125</span>'
        '</div>'
        '<div style="font-family: monospace; font-size: 9.5px; line-height: 1.45;">'
        '  <div><b style="color: #6d28d9;">WAN (ens5):</b> 10.0.2.10 (Public AZ-b) • <b style="color: #6d28d9;">LAN (ens6):</b> 10.0.11.254</div>'
        '  <div><b>An ninh:</b> Suricata IDS/IPS • Wazuh Agent (eve.json)</div>'
        '  <div><b>Cân bằng tải:</b> <span style="background: #fef3c7; color: #b45309; font-weight: 800; padding: 1px 4px; border-radius: 3px;">HAProxy L4 (Active W2 / Backup W1)</span></div>'
        '  <div><b>Định tuyến:</b> DNAT 8443 (Wazuh SIEM) • <b style="color: #16a34a;">LAN Masquerade SNAT</b></div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#7c3aed;strokeWidth=1.5;align=left;verticalAlign=top;",
        510, 114, 430, 92
    )

    # Arrows from NLB to Gateways
    add_edge(nlb_block, gw1, "", "strokeColor=#0284c7;strokeWidth=2;endArrow=classic;")
    add_edge(nlb_block, gw2, "", "strokeColor=#7c3aed;strokeWidth=2;endArrow=classic;")

    # -------------------------------------------------------------------------
    # ZONE 1: AZ-a (10.0.10.0/24) - Master + Worker 1 (NO ROUTE TABLE)
    # -------------------------------------------------------------------------
    zone1_box = add_cell(
        '<div style="text-align: left; padding: 2px;">'
        '<div style="background: #f0f9ff; border-bottom: 1px solid #bae6fd; padding: 3px 8px; font-size: 10px; font-weight: 800; color: #0369a1; border-radius: 4px 4px 0 0; margin: -2px -2px 4px -2px;">'
        'VÙNG AZ-a: Private Subnet 10.0.10.0/24'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#0284c7;strokeWidth=1.2;align=left;verticalAlign=top;",
        52, 214, 430, 268
    )

    # Server 1: k8s-master
    master_node = add_cell(
        '<div style="text-align: left; padding: 3px;">'
        '<div style="background: #e2e8f0; font-size: 9.5px; font-weight: 800; color: #0f172a; padding: 2px 6px; border-radius: 3px; margin-bottom: 4px;">'
        'Node: k8s-master (IP: 10.0.10.10 • c7i-flex.large • 2 vCPU, 4GB RAM)'
        '</div>'
        '<table style="width: 100%; font-size: 9px; border-collapse: separate; border-spacing: 3px;">'
        '  <tr>'
        '    <td style="width: 50%; background: #ffffff; border: 1px solid #93c5fd; border-radius: 3px; padding: 3px;">'
        '      <b style="color: #0f172a;">K8s Control Plane v1.31</b><br><span style="color: #2563eb; font-family: monospace;">kube-apiserver • CoreDNS • Audit</span>'
        '    </td>'
        '    <td style="width: 50%; background: #ffffff; border: 1px solid #c084fc; border-radius: 3px; padding: 3px;">'
        '      <b style="color: #6d28d9;">Rancher Server v2.9</b><br><span style="color: #7c3aed; font-family: monospace;">NodePort 30443 (HAProxy: 7443)</span>'
        '    </td>'
        '  </tr>'
        '  <tr>'
        '    <td style="background: #ffffff; border: 1px solid #f472b6; border-radius: 3px; padding: 3px;">'
        '      <b style="color: #0f172a;">Wazuh Agent</b><br><span style="color: #be185d; font-family: monospace;">Đẩy K8s audit.log về SIEM</span>'
        '    </td>'
        '    <td style="background: #ffffff; border: 1px solid #86efac; border-radius: 3px; padding: 3px;">'
        '      <b style="color: #15803d;">Control Plane Isolation</b><br><span style="color: #16a34a; font-family: monospace;">Taint: NoSchedule (Dedicated)</span>'
        '    </td>'
        '  </tr>'
        '</table>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#cbd5e1;strokeWidth=1;align=left;verticalAlign=top;",
        60, 240, 414, 110
    )

    # Server 2: k8s-worker-1
    worker1_node = add_cell(
        '<div style="text-align: left; padding: 3px;">'
        '<div style="background: #e2e8f0; font-size: 9.5px; font-weight: 800; color: #0f172a; padding: 2px 6px; border-radius: 3px; margin-bottom: 4px;">'
        'Node: k8s-worker-1 (IP: 10.0.10.139 • c7i-flex.large • 2 vCPU, 4GB RAM)'
        '</div>'
        '<div style="font-size: 9px; line-height: 1.45; padding: 0 4px;">'
        '  <div><b style="color: #854d0e; background: #fef08a; padding: 1px 4px; border-radius: 3px;">Ingress-NGINX (HostNetwork):</b> Port 80 (HTTP) &amp; 443 (HTTPS)</div>'
        '  <div><b style="color: #0369a1;">Hạ tầng K8s:</b> Kubelet v1.31 • Cilium eBPF CNI (10.244.0.0/16 VXLAN)</div>'
        '  <div><b style="color: #15803d;">An ninh &amp; Lưu trữ:</b> EBS gp3 • IMDSv2 Token • Wazuh Agent (Active)</div>'
        '  <div><b style="color: #4338ca;">Workloads Online Boutique:</b> frontend, cartservice, checkoutservice, emailservice</div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#cbd5e1;strokeWidth=1;align=left;verticalAlign=top;",
        60, 358, 414, 116
    )

    # -------------------------------------------------------------------------
    # ZONE 2: AZ-b (10.0.11.0/24) - Worker 2 (NO ROUTE TABLE)
    # -------------------------------------------------------------------------
    zone2_box = add_cell(
        '<div style="text-align: left; padding: 2px;">'
        '<div style="background: #faf5ff; border-bottom: 1px solid #e9d5ff; padding: 3px 8px; font-size: 10px; font-weight: 800; color: #7e22ce; border-radius: 4px 4px 0 0; margin: -2px -2px 4px -2px;">'
        'VÙNG AZ-b: Private Subnet 10.0.11.0/24'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#9333ea;strokeWidth=1.2;align=left;verticalAlign=top;",
        510, 214, 430, 268
    )

    # Server 3: k8s-worker-2
    worker2_node = add_cell(
        '<div style="text-align: left; padding: 3px;">'
        '<div style="background: #e2e8f0; font-size: 9.5px; font-weight: 800; color: #0f172a; padding: 2px 6px; border-radius: 3px; margin-bottom: 4px;">'
        'Node: k8s-worker-2 (IP: 10.0.11.21 • c7i-flex.large • 2 vCPU, 4GB RAM)'
        '</div>'
        '<div style="padding: 0 4px;">'
        '  <div style="background: #ffffff; border: 1px solid #854d0e; border-radius: 3px; padding: 3px 6px; margin-bottom: 4px;">'
        '    <b style="color: #854d0e; font-size: 9.5px;">• Ingress-NGINX Multi-AZ (HostNetwork):</b><br>'
        '    <span style="font-size: 9px; color: #713f12;">Port 80 (HTTP) &amp; Port 443 (HTTPS) • Active-Active với Worker 1</span>'
        '  </div>'
        '  <div style="background: #ffffff; border: 1px solid #9333ea; border-radius: 3px; padding: 3px 6px; margin-bottom: 4px;">'
        '    <b style="color: #7e22ce; font-size: 9.5px;">• Hạ tầng K8s Multi-AZ:</b><br>'
        '    <span style="font-size: 9px; color: #334155;">Kubelet v1.31 • Cilium eBPF Kernel Datapath (VXLAN UDP 8472)</span>'
        '  </div>'
        '  <div style="background: #ffffff; border: 1px solid #16a34a; border-radius: 3px; padding: 3px 6px; margin-bottom: 4px;">'
        '    <b style="color: #15803d; font-size: 9.5px;">• An ninh &amp; Lưu trữ AWS:</b><br>'
        '    <span style="font-size: 9px; color: #334155;">EBS gp3 (KMS Mã hóa) • IMDSv2 Token • SG: sg-k8s • Wazuh Agent</span>'
        '  </div>'
        '  <div style="background: #ffffff; border: 1px solid #6366f1; border-radius: 3px; padding: 3px 6px;">'
        '    <b style="color: #4338ca; font-size: 9.5px;">• Workloads Online Boutique (Multi-AZ Replicas):</b><br>'
        '    <span style="font-size: 9px; color: #0f172a;">paymentservice • redis-cart • currencyservice • productcatalogservice</span>'
        '  </div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#cbd5e1;strokeWidth=1;align=left;verticalAlign=top;",
        518, 240, 414, 234
    )

    # -------------------------------------------------------------------------
    # ZONE 3: MANAGEMENT SUBNET (10.0.20.0/24) - WAZUH SIEM (NO ROUTE TABLE)
    # -------------------------------------------------------------------------
    zone3_box = add_cell(
        '<div style="text-align: left; padding: 2px;">'
        '<div style="background: #fdf2f8; border-bottom: 1px solid #fbcfe8; padding: 3px 8px; font-size: 10px; font-weight: 800; color: #be185d; border-radius: 4px 4px 0 0; margin: -2px -2px 4px -2px; display: flex; justify-content: space-between;">'
        '  <span>VÙNG QUẢN TRỊ AN NINH: Management Subnet 10.0.20.0/24 (Cô lập logic)</span>'
        '  <span style="float: right; font-family: monospace; color: #db2777;">SG: ncs-project-sg-wazuh</span>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#db2777;strokeWidth=1.3;align=left;verticalAlign=top;",
        52, 490, 888, 150
    )

    # Wazuh SIEM Server Card
    wazuh_card = add_cell(
        '<div style="text-align: left; padding: 3px;">'
        '<div style="background: #fecdd3; font-size: 9.5px; font-weight: 800; color: #9f1239; padding: 2px 8px; border-radius: 3px; margin-bottom: 4px;">'
        'Máy chủ SOC SIEM Chuyên biệt: ncs-project-wazuh-siem (IP: 10.0.20.10 • t3.large • 2 vCPU, 8GB RAM, 50GB gp3)'
        '</div>'
        '<div style="font-size: 9px; line-height: 1.5; padding: 0 6px;">'
        '  <div><b style="color: #be123c;">Wazuh Manager v4.9 &amp; OpenSearch Indexer:</b> REST API Port 55000 • Wazuh Dashboard Port 8443 • Quản lý 5 Agents Active</div>'
        '  <div><b style="color: #be123c;">Kênh Thu thập Log:</b> TLS Port 1514 (Nhận eve.json từ Gateway 1 &amp; Gateway 2) • K8s Audit Log từ Master &amp; Workers</div>'
        '  <div><b style="color: #be123c;">Tương quan An ninh:</b> Quy chiếu MITRE ATT&amp;CK Matrix • Cảnh báo Real-time SQLi, XSS, Path Traversal</div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#fff1f2;strokeColor=#fda4af;strokeWidth=1;align=left;verticalAlign=top;",
        62, 516, 868, 116
    )

    # =========================================================================
    # 3. RIGHT-SIDE PANELS (NO ROUTE TABLE)
    # =========================================================================
    # CARD 1: KIẾN TRÚC DUAL-GATEWAY HA & HAPROXY L4 (NO ROUTE TABLE)
    card1 = add_cell(
        '<div style="text-align: left; padding: 2px;">'
        '<div style="background: #fef3c7; border-bottom: 1px solid #fde68a; padding: 3px 8px; font-size: 10px; font-weight: 800; color: #92400e; border-radius: 4px 4px 0 0; margin: -2px -2px 4px -2px;">'
        'KIẾN TRÚC DUAL-GATEWAY HA &amp; HAPROXY L4'
        '</div>'
        '<div style="font-size: 9px; line-height: 1.45; padding: 2px 6px;">'
        '  <div style="font-weight: 800; color: #b45309;">AWS NLB CÂN BẰNG TẢI L4:</div>'
        '  <div style="font-family: monospace; color: #451a03; margin-left: 6px;">Lưu lượng Internet phân bổ đều qua Gateway 1 &amp; Gateway 2.<br>Tự động ngắt chuyển mạch trong 15s khi 1 Gateway gặp sự cố.</div>'
        '  <hr style="border: none; border-top: 1px solid #fde68a; margin: 4px 0;">'
        '  <div style="font-weight: 800; color: #b45309;">BỘ CÂN BẰNG TẢI HAPROXY L4 (CROSS-AZ FAILOVER):</div>'
        '  <div style="font-family: monospace; color: #451a03; margin-left: 6px;">'
        '    • GW1: Ưu tiên Worker 1 (Active), dự phòng Worker 2 (Backup).<br>'
        '    • GW2: Ưu tiên Worker 2 (Active), dự phòng Worker 1 (Backup).<br>'
        '    • Active TCP Health Check: <b>inter 2s fall 2 rise 2</b>.<br>'
        '    • Tự động failover chỉ trong 4s, sống sót kể cả khi GW1 &amp; Worker 2 cùng chết!'
        '  </div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#fffbeb;strokeColor=#fcd34d;strokeWidth=1.2;align=left;verticalAlign=top;",
        970, 82, 434, 180
    )

    # CARD 2: BẢNG CỔNG DỊCH VỤ QUA AWS NLB
    card2 = add_cell(
        '<div style="text-align: left; padding: 2px;">'
        '<div style="background: #f3e8ff; border-bottom: 1px solid #e9d5ff; padding: 3px 8px; font-size: 10px; font-weight: 800; color: #6b21a8; border-radius: 4px 4px 0 0; margin: -2px -2px 4px -2px;">'
        'BẢNG CỔNG DỊCH VỤ QUA AWS NLB'
        '</div>'
        '<div style="padding: 2px 6px;">'
        '<table style="width: 100%; font-size: 8.5px; border-collapse: collapse; line-height: 1.4;">'
        '  <tr style="font-weight: 800; color: #6b21a8; border-bottom: 1px solid #d8b4fe;">'
        '    <td>DỊCH VỤ</td><td>CỔNG NLB</td><td>ĐÍCH NỘI BỘ</td><td>GIAO THỨC</td>'
        '  </tr>'
        '  <tr><td>Online Boutique</td><td style="color: #2563eb; font-weight: 700;">Port 80</td><td>Worker:80</td><td style="color: #475569;">HTTP (HAProxy L4)</td></tr>'
        '  <tr><td>Online Boutique</td><td style="color: #2563eb; font-weight: 700;">Port 443</td><td>Worker:443</td><td style="color: #475569;">HTTPS (HAProxy L4)</td></tr>'
        '  <tr><td>Rancher Manager</td><td style="color: #7c3aed; font-weight: 700;">Port 7443</td><td>Master:30443</td><td style="color: #475569;">HTTPS (HAProxy L4)</td></tr>'
        '  <tr><td>Wazuh SIEM API</td><td style="color: #db2777; font-weight: 700;">Port 8443</td><td>Wazuh:443</td><td style="color: #475569;">HTTPS (DNAT SIEM)</td></tr>'
        '  <tr><td>HAProxy Stats</td><td style="color: #b45309; font-weight: 700;">Port 8404</td><td>Gateway:8404</td><td style="color: #475569;">HTTP (Stats Web)</td></tr>'
        '  <tr><td>SSH Bastion GW1</td><td style="color: #059669; font-weight: 700;">Port 22</td><td>13.251.225.100</td><td style="color: #475569;">SSH Direct</td></tr>'
        '  <tr><td>SSH Bastion GW2</td><td style="color: #059669; font-weight: 700;">Port 22</td><td>18.140.131.125</td><td style="color: #475569;">SSH Direct</td></tr>'
        '</table>'
        '<hr style="border: none; border-top: 1px solid #d8b4fe; margin: 3px 0;">'
        '<div style="font-size: 8.5px; font-family: monospace; color: #581c87;">'
        '• Target Groups NLB: 8/8 targets Healthy (Port 80, 443, 7443, 8443)<br>'
        '• Ingress NGINX Multi-AZ Active-Active trên cả 2 Worker nodes'
        '</div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#faf5ff;strokeColor=#c4b5fd;strokeWidth=1.2;align=left;verticalAlign=top;",
        970, 268, 434, 196
    )

    # CARD 3: QUY TẮC AN NINH & PHÒNG THỦ CHUYÊN SÂU
    card3 = add_cell(
        '<div style="text-align: left; padding: 2px;">'
        '<div style="background: #dcfce7; border-bottom: 1px solid #bbf7d0; padding: 3px 8px; font-size: 10px; font-weight: 800; color: #166534; border-radius: 4px 4px 0 0; margin: -2px -2px 4px -2px;">'
        'QUY TẮC AN NINH &amp; PHÒNG THỦ CHUYÊN SÂU'
        '</div>'
        '<div style="font-size: 9px; line-height: 1.45; padding: 2px 6px;">'
        '  <div><span style="color: #16a34a;">●</span> <b>Suricata IDS/IPS biên:</b> DPI phát hiện SQLi, XSS, Path Traversal.</div>'
        '  <div><span style="color: #16a34a;">●</span> <b>HAProxy L4 Stream:</b> TCP Health Check, chống sập dịch vụ chéo vùng.</div>'
        '  <div><span style="color: #16a34a;">●</span> <b>Wazuh SIEM SOC (10.0.20.10):</b> 5 Agents thu thập log thời gian thực.</div>'
        '  <div><span style="color: #16a34a;">●</span> <b>Zero-Trust NetworkPolicy:</b> Cô lập thanh toán gRPC 50051 tuyệt đối.</div>'
        '  <div><span style="color: #16a34a;">●</span> <b>Khóa 100% cổng Internet:</b> Chỉ nhận luồng forward nội bộ từ Gateway.</div>'
        '  <div><span style="color: #16a34a;">●</span> <b>Failover Zero Downtime:</b> Khắc phục thảm họa phân mảnh chéo vùng.</div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#86efac;strokeWidth=1.2;align=left;verticalAlign=top;",
        970, 470, 434, 170
    )

    # =========================================================================
    # 4. BOTTOM SECTION: 3 LUỒNG KẾT NỐI CHÍNH
    # =========================================================================
    bottom_box = add_cell(
        '<div style="text-align: left; padding: 2px;">'
        '<div style="background: #e2e8f0; padding: 3px 10px; font-size: 10.5px; font-weight: 800; color: #0f172a; border-radius: 4px 4px 0 0; margin: -2px -2px 6px -2px;">'
        '3 LUỒNG KẾT NỐI HẠ TẦNG CHÍNH (INBOUND, MANAGEMENT &amp; SOC TELEMETRY)'
        '</div>'
        '<div style="padding: 0 8px; font-size: 9px; line-height: 1.6;">'
        '  <div style="margin-bottom: 4px;">'
        '    <span style="background: #10b981; color: #ffffff; border-radius: 50%; padding: 1px 6px; font-weight: 800; margin-right: 4px;">1</span>'
        '    <span style="background: #ffffff; border: 1px solid #cbd5e1; padding: 2px 6px; border-radius: 3px; font-weight: 700;">Khách hàng Web</span> ➔ '
        '    <span style="background: #eff6ff; border: 1px solid #93c5fd; padding: 2px 6px; border-radius: 3px; color: #1d4ed8; font-weight: 700;">AWS NLB (Port 80/443)</span> ➔ '
        '    <span style="background: #fef3c7; border: 1px solid #f59e0b; padding: 2px 6px; border-radius: 3px; color: #b45309; font-weight: 700;">GW1 hoặc GW2 (HAProxy L4 Check)</span> ➔ '
        '    <span style="background: #f0fdf4; border: 1px solid #16a34a; padding: 2px 6px; border-radius: 3px; color: #15803d; font-weight: 700;">Ingress NGINX (Worker 1 hoặc Worker 2)</span> ➔ '
        '    <span style="background: #ecfdf5; border: 1px solid #10b981; padding: 2px 6px; border-radius: 3px; color: #047857; font-weight: 700;">Frontend Pods (Multi-AZ Workers)</span>'
        '  </div>'
        '  <div style="margin-bottom: 4px;">'
        '    <span style="background: #3b82f6; color: #ffffff; border-radius: 50%; padding: 1px 6px; font-weight: 800; margin-right: 4px;">2</span>'
        '    <span style="background: #ffffff; border: 1px solid #cbd5e1; padding: 2px 6px; border-radius: 3px; font-weight: 700;">Quản trị viên</span> ➔ '
        '    <span style="background: #eff6ff; border: 1px solid #93c5fd; padding: 2px 6px; border-radius: 3px; color: #1d4ed8; font-weight: 700;">AWS NLB (Port 7443)</span> ➔ '
        '    <span style="background: #fef3c7; border: 1px solid #f59e0b; padding: 2px 6px; border-radius: 3px; color: #b45309; font-weight: 700;">GW1 hoặc GW2 (HAProxy L4)</span> ➔ '
        '    <span style="background: #f5f3ff; border: 1px solid #7c3aed; padding: 2px 6px; border-radius: 3px; color: #6d28d9; font-weight: 700;">Rancher NodePort 30443</span> ➔ '
        '    <span style="background: #faf5ff; border: 1px solid #8b5cf6; padding: 2px 6px; border-radius: 3px; color: #7c3aed; font-weight: 700;">Giao diện Rancher Web UI</span>'
        '  </div>'
        '  <div>'
        '    <span style="background: #ec4899; color: #ffffff; border-radius: 50%; padding: 1px 6px; font-weight: 800; margin-right: 4px;">3</span>'
        '    <span style="background: #ffffff; border: 1px solid #cbd5e1; padding: 2px 6px; border-radius: 3px; font-weight: 700;">Suricata &amp; K8s Audit</span> ➔ '
        '    <span style="background: #fff1f2; border: 1px solid #f43f5e; padding: 2px 6px; border-radius: 3px; color: #be123c; font-weight: 700;">eve.json &amp; audit.log</span> ➔ '
        '    <span style="background: #fdf2f8; border: 1px solid #db2777; padding: 2px 6px; border-radius: 3px; color: #be185d; font-weight: 700;">Wazuh Agents (GW1, GW2, Master, Workers)</span> ➔ '
        '    <span style="background: #fce7f3; border: 1px solid #be185d; padding: 2px 6px; border-radius: 3px; color: #9d174d; font-weight: 700;">Mạng Mgmt TLS Port 1514</span> ➔ '
        '    <span style="background: #fdf2f8; border: 1px solid #db2777; padding: 2px 6px; border-radius: 3px; color: #be185d; font-weight: 700;">Wazuh SIEM Server (10.0.20.10)</span>'
        '  </div>'
        '</div>'
        '</div>',
        "rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#cbd5e1;strokeWidth=1.2;align=left;verticalAlign=top;",
        36, 656, 1368, 140
    )

    xml_header = (
        '<mxfile host="app.diagrams.net" modified="2026-11-06T00:52:00.000Z" agent="Antigravity Agent" version="24.0.0" type="device">\n'
        '  <diagram id="ncs-k8s-architecture-v2" name="Kiến Trúc NCS Project K8s">\n'
        '    <mxGraphModel dx="1600" dy="1000" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1440" pageHeight="820" math="0" shadow="0">\n'
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
        print(f"Written Draw.io diagram (old format + HAProxy - route table) to {p} ({len(content)} bytes)")
