const pptxgen = require('/tmp/node_modules/pptxgenjs');
const fs = require('fs');

const pres = new pptxgen();
pres.layout = 'LAYOUT_16x9'; // 10 x 5.625 inches
pres.author = 'NCS Project Team';
pres.title = 'Thiết Kế & Triển Khai Hạ Tầng An Ninh Microservices Trên AWS';

const C = {
  lightBg: 'F8FAFC',
  cardBg: 'FFFFFF',
  cardBorder: 'CBD5E1',
  primary: '0F172A',
  brandBlue: '0284C7',
  brandDarkBlue: '1E3A8A',
  accentGreen: '10B981',
  textDark: '0F172A',
  textMuted: '334155',
  screenshotBg: 'F1F5F9',
  screenshotBorder: '94A3B8'
};

const diagramImgPath = '/home/vinh/Documents/project_ncs/report/images/architecture_diagram.png';
const hasDiagramImg = fs.existsSync(diagramImgPath);

// Helper: Add Clean Header (Only Main Title, NO subtitle, NO category pill, NO footer)
function addHeader(slide, title) {
  // Accent bar left
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0.6, y: 0.45, w: 0.12, h: 0.45,
    fill: { color: C.brandBlue }, line: { color: C.brandBlue }
  });

  // Main Title Only
  slide.addText(title, {
    x: 0.85, y: 0.45, w: 8.5, h: 0.48,
    fontSize: 20, bold: true, color: C.primary,
    fontFace: 'Arial', valign: 'middle'
  });
}

// Helper: Add Screenshot Placeholder Box (Clean, no tiny footer)
function addScreenshotBox(slide, x, y, w, h, boxTitle, instructions) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x, y, w, h,
    rectRadius: 0.08,
    fill: { color: C.screenshotBg },
    line: { color: C.screenshotBorder, width: 1.5, dashType: 'dash' }
  });

  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: x + 0.2, y: y + 0.2, w: w - 0.4, h: 0.4,
    rectRadius: 0.05,
    fill: { color: 'E2E8F0' },
    line: { color: 'CBD5E1', width: 1 }
  });

  slide.addText(`📷 KHUNG DÁN ẢNH: ${boxTitle.toUpperCase()}`, {
    x: x + 0.2, y: y + 0.2, w: w - 0.4, h: 0.4,
    fontSize: 9.5, bold: true, color: C.brandDarkBlue, align: 'center',
    fontFace: 'Arial', valign: 'middle'
  });

  let textRows = instructions.map(inst => ({
    text: inst + '\n',
    options: { fontSize: 10, color: C.textDark, bullet: true, fontFace: 'Arial' }
  }));

  slide.addText(textRows, {
    x: x + 0.25, y: y + 0.75, w: w - 0.5, h: h - 0.9,
    fontFace: 'Arial', margin: 0.05
  });
}

// -------------------------------------------------------------
// SLIDE 1: COVER SLIDE (LIGHT MODE)
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };

  // Big Title Card
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.8, y: 0.8, w: 8.4, h: 2.1, rectRadius: 0.1,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1.5 }
  });

  s.addText('THIẾT KẾ & TRIỂN KHAI HẠ TẦNG\nAN NINH MICROSERVICES TRÊN AWS', {
    x: 1.1, y: 1.0, w: 7.8, h: 1.1,
    fontSize: 25, bold: true, color: C.primary, fontFace: 'Arial', align: 'center'
  });

  s.addText('Multi-AZ Defense-in-Depth • Dual-Gateway HA • Cilium eBPF CNI • Wazuh SIEM SOC', {
    x: 1.1, y: 2.2, w: 7.8, h: 0.4,
    fontSize: 12, bold: true, color: C.brandBlue, fontFace: 'Arial', align: 'center'
  });

  // Feature pills (Light Cards)
  const pills = [
    'AWS NLB Active-Active',
    'Suricata IDS/IPS DPI',
    'HAProxy L4 Stream HA',
    'Upstream K8s v1.31',
    'Hubble eBPF Observability',
    'Google Online Boutique'
  ];
  pills.forEach((p, idx) => {
    const col = idx % 3;
    const row = Math.floor(idx / 3);
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: 0.8 + col * 2.85, y: 3.2 + row * 0.55, w: 2.7, h: 0.42,
      rectRadius: 0.08,
      fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
    });
    s.addText('✓ ' + p, {
      x: 0.8 + col * 2.85, y: 3.2 + row * 0.55, w: 2.7, h: 0.42,
      fontSize: 10, color: C.brandDarkBlue, align: 'center', bold: true, valign: 'middle'
    });
  });

  s.addText('Sinh viên thực hiện: Nhóm NCS Project    |    Hạ tầng triển khai thực tế trên AWS', {
    x: 0.8, y: 4.6, w: 8.4, h: 0.4,
    fontSize: 11, color: C.textMuted, fontFace: 'Arial', align: 'center', bold: true
  });

  s.addNotes('Kính chào thầy cô và các bạn. Hôm nay em xin trình bày đồ án về Thiết kế và triển khai hạ tầng an ninh mạng cho hệ thống Microservices trên môi trường đám mây AWS với mô hình phòng thủ đa lớp Defense-in-Depth.');
}

// -------------------------------------------------------------
// SLIDE 2: ĐẶT VẤN ĐỀ & MỤC TIÊU DỰ ÁN
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Đặt Vấn Đề & Mục Tiêu Dự Án');

  // Left Box: Thách thức
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: 'FEF2F2' }, line: { color: 'FCA5A5', width: 1.5 }
  });
  s.addText('⚠️ THÁCH THỨC ĐẶT RA', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.35,
    fontSize: 12, bold: true, color: 'B91C1C'
  });
  s.addText([
    { text: 'Bề mặt tấn công lớn: ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Microservices phân tán nhiều cổng/giao thức khiến việc kiểm soát luồng gói tin phức tạp.\n\n', options: { fontSize: 10 } },
    { text: 'Nguy cơ Single Point of Failure: ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Nếu chỉ có 1 Gateway hoặc 1 AZ, toàn bộ hệ thống sập khi hạ tầng vùng gặp sự cố.\n\n', options: { fontSize: 10 } },
    { text: 'Thiếu kiểm soát luồng nội bộ: ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Mạng phẳng trong K8s cho phép kẻ tấn công sau khi chiếm 1 pod có thể leo thang toàn cụm.\n\n', options: { fontSize: 10 } },
    { text: 'Rời rạc trong giám sát: ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Log mạng, log OS và log K8s nằm phân tán, thiếu khả năng tương quan cảnh báo thời gian thực.', options: { fontSize: 10 } }
  ], { x: 0.8, y: 1.7, w: 3.8, h: 3.3 });

  // Right Box: Mục tiêu
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 5.2, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: 'F0FDF4' }, line: { color: '86EFAC', width: 1.5 }
  });
  s.addText('🎯 MỤC TIÊU HỆ THỐNG ĐẠT ĐƯỢC', {
    x: 5.4, y: 1.3, w: 3.8, h: 0.35,
    fontSize: 12, bold: true, color: '15803D'
  });
  s.addText([
    { text: 'Khả năng chịu lỗi cao (Multi-AZ HA): ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Triển khai Dual-Gateway Active-Active qua 2 AZs cân bằng tải qua AWS NLB L4.\n\n', options: { fontSize: 10 } },
    { text: 'Phòng thủ chiều sâu (Defense-in-Depth): ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Kiểm tra gói tin sâu (DPI) bằng Suricata IDS/IPS tại mạng biên; HAProxy L4 chuyển tiếp an toàn.\n\n', options: { fontSize: 10 } },
    { text: 'An ninh Zero-Trust với Cilium eBPF: ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Áp dụng NetworkPolicy cô lập nghiêm ngặt từng microservice, quan sát qua Hubble UI.\n\n', options: { fontSize: 10 } },
    { text: 'Giám sát tập trung (SOC): ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Wazuh SIEM thu thập log đa tầng từ 5 Agents, cảnh báo tấn công tự động theo MITRE ATT&CK.', options: { fontSize: 10 } }
  ], { x: 5.4, y: 1.7, w: 3.8, h: 3.3 });

  s.addNotes('Slide này nêu bật lý do ra đời của đề tài: giải quyết thách thức về tính sẵn sàng cao và an ninh mạng đa lớp cho ứng dụng microservices phân tán.');
}

// -------------------------------------------------------------
// SLIDE 3: KIẾN TRÚC TOPO TỔNG THỂ
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Sơ Đồ Topo Tổng Thể (Dựa Trên Draw.io Chuẩn)');

  if (hasDiagramImg) {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: 0.6, y: 1.15, w: 3.3, h: 4.0, rectRadius: 0.08,
      fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
    });
    s.addText('CÁC PHÂN VÙNG CHÍNH', {
      x: 0.75, y: 1.3, w: 3.0, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
    });
    s.addText([
      { text: '1. Vùng Biên (Internet Facing):\n', options: { bold: true, fontSize: 9.5 } },
      { text: 'Cổng 80, 443, 7443, 8443 phân tải vào 2 Gateway qua AWS NLB.\n\n', options: { fontSize: 9 } },
      { text: '2. Dual-Gateway (Multi-AZ):\n', options: { bold: true, fontSize: 9.5 } },
      { text: 'GW1 (AZ-a: 10.0.1.10) & GW2 (AZ-b: 10.0.2.10) chạy Suricata DPI + HAProxy L4.\n\n', options: { fontSize: 9 } },
      { text: '3. Cụm K8s Nội Bộ:\n', options: { bold: true, fontSize: 9.5 } },
      { text: 'Master (10.0.10.10), Worker1 (10.0.10.139), Worker2 (10.0.11.21) chạy Cilium eBPF.\n\n', options: { fontSize: 9 } },
      { text: '4. Phân Vùng Wazuh SIEM:\n', options: { bold: true, fontSize: 9.5 } },
      { text: 'Subnet 10.0.20.0/24 độc lập, thu thập TLS 1514 từ 5 Agents.', options: { fontSize: 9 } }
    ], { x: 0.75, y: 1.65, w: 3.0, h: 3.3 });

    s.addImage({
      path: diagramImgPath,
      x: 4.1, y: 1.15, w: 5.3, h: 4.0
    });
  } else {
    addScreenshotBox(s, 0.6, 1.15, 8.8, 4.0, 'Sơ Đồ Kiến Trúc Hệ Thống', [
      'Chèn ảnh xuất từ file: report/images/architecture_diagram.drawio',
      'Thể hiện rõ: Internet Client -> AWS NLB -> Gateway 1 & 2 -> K8s Cluster -> Wazuh Subnet'
    ]);
  }

  s.addNotes('Đây là sơ đồ kiến trúc chuẩn từ file architecture_diagram.drawio. Toàn bộ lưu lượng Internet đi qua AWS NLB, rẽ vào 2 Gateway trang bị Suricata IDS và HAProxy L4 trước khi vào cụm K8s hoặc Wazuh.');
}

// -------------------------------------------------------------
// SLIDE 4: QUY TRÌNH & LỘ TRÌNH TRIỂN KHAI 5 BƯỚC
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Lộ Trình Triển Khai Hệ Thống (5 Bước)');

  const steps = [
    { num: '01', title: 'Hạ Tầng AWS IaC', desc: 'Terraform tạo VPC 10.0.0.0/16, 5 Subnets trên 2 AZs, 5 EC2 Instances, Dual-ENI, AWS NLB và VPC Flow Logs.' },
    { num: '02', title: 'Gateway & Tường Lửa', desc: 'Cấu hình Netplan Policy Routing, HAProxy L4 Active/Backup, và cài đặt Suricata IDS/IPS nhận diện tấn công Web.' },
    { num: '03', title: 'K8s & Cilium eBPF', desc: 'Khởi tạo cụm K8s v1.31 qua Kubeadm, cài đặt Cilium eBPF CNI Kernel-mode và kích hoạt Hubble UI giám sát luồng mạng.' },
    { num: '04', title: 'App & Quản Trị', desc: 'Triển khai Google Online Boutique (11 microservices), Ingress-NGINX, chính sách Zero-Trust, HPA và Rancher Server.' },
    { num: '05', title: 'Wazuh SIEM SOC', desc: 'Dựng Wazuh SIEM 10.0.20.10, cài 5 Wazuh Agents trên toàn bộ máy chủ, tương quan log Suricata eve.json & K8s audit.' }
  ];

  steps.forEach((st, idx) => {
    const x = 0.6 + idx * 1.8;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: 1.25, w: 1.65, h: 3.8, rectRadius: 0.08,
      fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1.5 }
    });

    s.addShape(pres.shapes.OVAL, {
      x: x + 0.5, y: 1.5, w: 0.65, h: 0.65,
      fill: { color: C.brandDarkBlue }, line: { color: C.brandBlue, width: 2 }
    });
    s.addText(st.num, {
      x: x + 0.5, y: 1.5, w: 0.65, h: 0.65,
      fontSize: 12, bold: true, color: 'FFFFFF', align: 'center', valign: 'middle'
    });

    s.addText(st.title, {
      x: x + 0.1, y: 2.35, w: 1.45, h: 0.5,
      fontSize: 11, bold: true, color: C.primary, align: 'center'
    });

    s.addText(st.desc, {
      x: x + 0.1, y: 2.95, w: 1.45, h: 1.9,
      fontSize: 9, color: C.textMuted, align: 'center'
    });
  });

  s.addNotes('Quy trình gồm 5 bước bài bản: từ khởi tạo hạ tầng bằng Terraform, cấu hình mạng biên Gateway, dựng K8s với Cilium eBPF, triển khai microservices, và cuối cùng là giám sát với Wazuh SIEM.');
}

// -------------------------------------------------------------
// SLIDE 5: BƯỚC 1 — HẠ TẦNG MẠNG AWS
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Hạ Tầng Mạng Multi-AZ (VPC, Subnets, Route Tables)');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('THIẾT KẾ PHÂN VÙNG MẠNG AWS', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• Amazon VPC: ', options: { bold: true, fontSize: 10.5 } },
    { text: 'CIDR 10.0.0.0/16 trên Region Singapore (ap-southeast-1).\n\n', options: { fontSize: 10 } },
    { text: '• 5 Subnets trên 2 Availability Zones:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - public-wan-a (10.0.1.0/24): Gateway 1 WAN + NLB Node 1\n  - public-wan-b (10.0.2.0/24): Gateway 2 WAN + NLB Node 2\n  - private-k8s-a (10.0.10.0/24): K8s Master & Worker 1\n  - private-k8s-b (10.0.11.0/24): K8s Worker 2\n  - private-mgmt-a (10.0.20.0/24): Wazuh SIEM Server\n\n', options: { fontSize: 9.5 } },
    { text: '• Bảng định tuyến (Route Tables):\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Public RT: Trỏ 0.0.0.0/0 ra Internet Gateway (IGW).\n  - Private RT: Định tuyến nội bộ an toàn, không có đường ra trực tiếp.\n\n', options: { fontSize: 9.5 } },
    { text: '• VPC Flow Logs: ', options: { bold: true, fontSize: 10.5 } },
    { text: 'Ghi nhận toàn bộ lưu lượng mạng đẩy về AWS CloudWatch.', options: { fontSize: 10 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'AWS VPC & Subnets Console', [
    'Nguồn: AWS Console -> VPC -> Subnets',
    'Chụp danh sách 5 Subnets hiển thị rõ Name, CIDR IPv4 và Availability Zone.',
    'Nguồn phụ: AWS Console -> VPC -> Route Tables (Public/Private RT).',
    'Nguồn phụ: CloudWatch -> Log Groups (nhóm vpc-flow-logs).'
  ]);

  s.addNotes('Tại bước 1, chúng em khởi tạo toàn bộ VPC và 5 Subnets bằng Terraform. Việc phân vùng rõ ràng đảm bảo các node K8s nằm hoàn toàn trong subnet riêng, không bị lộ IP Public.');
}

// -------------------------------------------------------------
// SLIDE 6: BƯỚC 1 (TIẾP) — COMPUTE & NLB
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Máy Chủ EC2 & Cân Bằng Tải AWS NLB Active-Active');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('HẠ TẦNG COMPUTE & LOAD BALANCER', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• 5 EC2 Instances hoạt động:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Gateway 1 & 2: Cấu hình Dual-ENI (WAN ens5 & LAN ens6), gán 2 Elastic IPs (13.251.225.100, 18.140.131.125).\n  - k8s-master (10.0.10.10): c7i-flex.large\n  - k8s-worker-1 & 2 (10.0.10.139, 10.0.11.21): t3.small\n  - wazuh-siem (10.0.20.10): t3.small\n\n', options: { fontSize: 9.5 } },
    { text: '• AWS Network Load Balancer (NLB L4):\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Triển khai Active-Active trên cả 2 Subnets WAN.\n  - Lắng nghe công khai các cổng: 80, 443, 7443, 8443.\n  - Target Groups: Health check kiểm tra liên tục IP WAN của 2 Gateways.', options: { fontSize: 9.5 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'AWS EC2 & NLB Target Groups Console', [
    'Nguồn: AWS Console -> EC2 -> Instances',
    'Chụp bảng danh sách 5 máy chủ ở trạng thái Running kèm Name tag & Private IP.',
    'Nguồn: AWS Console -> EC2 -> Load Balancers (chi tiết NLB, DNS Name).',
    'Nguồn: AWS Console -> EC2 -> Target Groups (trạng thái Healthy của 2 Gateways).'
  ]);

  s.addNotes('Đây là giao diện AWS EC2 và NLB thực tế sau khi áp dụng Terraform. Hai Gateway hoạt động ở chế độ Active-Active, được NLB kiểm tra sức khỏe liên tục để tự động failover.');
}

// -------------------------------------------------------------
// SLIDE 7: BƯỚC 2 — DUAL-GATEWAY & SURICATA
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Thiết Lập Dual-Gateway, HAProxy L4 & Suricata IDS/IPS');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('CẤU HÌNH GATEWAY CHUYÊN SÂU', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• Netplan Policy Routing & IPTables:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Chống định tuyến bất đối xứng giữa card WAN ens5 và LAN ens6.\n  - DNAT cổng 8443 từ WAN vào máy chủ Wazuh SIEM 10.0.20.10:443.\n\n', options: { fontSize: 9.5 } },
    { text: '• HAProxy L4 (Chế độ TCP Stream):\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Cổng 80 & 443: GW1 ưu tiên Worker 1, dự phòng Worker 2; trên GW2 đảo ngược để tối ưu độ trễ AZ.\n  - Dashboard thống kê tình trạng node trực tiếp tại cổng 8404.\n\n', options: { fontSize: 9.5 } },
    { text: '• Suricata IDS/IPS DPI:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Lắng nghe af-packet trên card WAN ens5.\n  - Bộ luật local.rules bắt SQLi, XSS, Path Traversal, Sensitive Probe.', options: { fontSize: 9.5 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'HAProxy Stats Dashboard & Suricata Status', [
    'Nguồn: Trình duyệt vào http://<GATEWAY_IP>:8404/haproxy?stats',
    'Chụp bảng trạng thái HAProxy hiển thị các hàng xanh của http_nodes và https_nodes.',
    'Nguồn: Terminal chạy systemctl status suricata (active running).',
    'Nguồn: Terminal xem nội dung cat /etc/suricata/rules/local.rules.'
  ]);

  s.addNotes('Ở tầng Gateway, HAProxy L4 đóng vai trò cầu nối phân phối lưu lượng vào K8s, trong khi Suricata quét từng gói tin đi qua WAN để phát hiện ngay các mẫu tấn công độc hại.');
}

// -------------------------------------------------------------
// SLIDE 8: BƯỚC 3 — K8S V1.31 & CILIUM EBPF
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Khởi Tạo Upstream K8s v1.31 & CNI Cilium eBPF');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('CÔNG NGHỆ NỀN TẢNG KUBERNETES', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• Upstream Kubernetes v1.31:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Khởi tạo bằng Kubeadm v1beta4 trên Ubuntu 22.04 LTS.\n  - Bật K8s Audit Policy: ghi lại mọi yêu cầu gửi tới API Server vào audit.log phục vụ SOC.\n\n', options: { fontSize: 9.5 } },
    { text: '• Cilium eBPF CNI v1.16.2:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Xử lý gói tin trực tiếp trong Linux Kernel mà không cần tra cứu iptables hàng ngàn dòng.\n  - Hỗ trợ Zero-Trust NetworkPolicy, mã hóa dữ liệu pod-to-pod và quan sát mạng sâu.\n  - Cấu hình tunnel protocol VXLAN liên kết Master và 2 Workers.', options: { fontSize: 9.5 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'K8s Nodes & Cilium Status CLI', [
    'Nguồn: Terminal Master chạy kubectl get nodes -o wide',
    'Hiển thị 1 Master và 2 Workers đều ở trạng thái Ready kèm K8s version v1.31.',
    'Nguồn: Terminal chạy cilium status',
    'Hiển thị trạng thái Cilium: OK, Hubble: OK, eBPF Maps memory và nodes healthy.'
  ]);

  s.addNotes('Cụm K8s được triển khai với phiên bản v1.31 mới nhất. Điểm nhấn là việc thay thế kube-proxy bằng Cilium eBPF, giúp tăng tốc độ mạng và hỗ trợ chính sách an ninh chi tiết.');
}

// -------------------------------------------------------------
// SLIDE 9: BƯỚC 3 (TIẾP) — CILIUM HUBBLE UI
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Giám Sát Luồng Mạng Chuyên Sâu Với Cilium Hubble UI');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('TÍNH NĂNG GIÁM SÁT EBPF HUBBLE', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• Service Dependency Graph:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Tự động vẽ sơ đồ tương tác giữa 11 microservices theo thời gian thực.\n  - Nhận diện rõ luồng gọi HTTP và gRPC giữa các pod.\n\n', options: { fontSize: 9.5 } },
    { text: '• Giám sát lưu lượng L3/L4/L7:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Theo dõi tốc độ gói tin (Packets/s), độ trễ (Latency).\n  - Phát hiện ngay các gói tin bị từ chối (DROPPED) khi vi phạm chính sách NetworkPolicy.\n\n', options: { fontSize: 9.5 } },
    { text: '• Giao diện Web cổng 31235:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Hubble UI NodePort 31235 cho phép lọc theo namespace online-boutique dễ dàng.', options: { fontSize: 9.5 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'Giao Diện Cilium Hubble UI (Port 31235)', [
    'Nguồn: Trình duyệt vào http://<K8S_MASTER_IP>:31235/',
    'Chọn namespace online-boutique trên thanh dropdown.',
    'Chụp biểu đồ Service Map: Frontend -> CartService, CheckoutService,...',
    'Chụp bảng Flows bên dưới hiển thị các dòng màu xanh FORWARDED và màu đỏ DROPPED.'
  ]);

  s.addNotes('Hubble UI đem lại khả năng quan sát mạng mà các giải pháp trước đây không có: nhìn rõ từng cuộc gọi gRPC giữa các pod và kiểm tra tính hiệu quả của các chính sách cách ly.');
}

// -------------------------------------------------------------
// SLIDE 10: BƯỚC 4 — ONLINE BOUTIQUE & ZERO TRUST
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Triển Khai Google Online Boutique & Chính Sách Zero-Trust');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('KIẾN TRÚC ỨNG DỤNG & AN NINH POD', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• Google Online Boutique (11 Microservices):\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Đa ngôn ngữ (Go, C#, Node.js, Python, Java) giao tiếp qua gRPC.\n  - Frontend tiếp nhận request người dùng qua Ingress-NGINX (80/443).\n\n', options: { fontSize: 9.5 } },
    { text: '• Cơ chế Sẵn Sàng & Tự Động Co Giãn:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - HPA tự động scale Frontend, Cart, Checkout khi tải CPU/RAM tăng.\n  - PodDisruptionBudget (PDB) đảm bảo dịch vụ không sập khi drain node.\n\n', options: { fontSize: 9.5 } },
    { text: '• Chính sách Zero-Trust NetworkPolicy:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Cách ly paymentservice: chỉ duy nhất checkoutservice được phép gọi vào cổng 50051.', options: { fontSize: 9.5 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'Web Online Boutique & K8s Pods', [
    'Nguồn: Trình duyệt vào http://<NLB_DNS>/ hoặc https://boutique.lab/',
    'Chụp trang chủ cửa hàng Online Boutique (danh mục sản phẩm, banner).',
    'Nguồn: Terminal chạy kubectl get pods -n online-boutique',
    'Hiển thị danh sách 11 microservices ở trạng thái Running kèm HPA, Netpol.'
  ]);

  s.addNotes('Ứng dụng thương mại điện tử Online Boutique chạy hoàn chỉnh với đầy đủ các dịch vụ. Dịch vụ PaymentService quan trọng được khóa chặt bằng chính sách Zero-Trust.');
}

// -------------------------------------------------------------
// SLIDE 11: BƯỚC 4 (TIẾP) — RANCHER SERVER
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Quản Trị Cụm K8s Tập Trung Với Rancher Server');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('TÍNH NĂNG QUẢN TRỊ RANCHER', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• Triển khai Rancher Server qua Helm:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Hoạt động trong namespace cattle-system trên K8s Master.\n  - Expose qua NodePort 30443, NLB điều hướng qua cổng 7443.\n\n', options: { fontSize: 9.5 } },
    { text: '• Quản trị Vận hành Toàn Diện:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Giám sát sức khỏe 3 Nodes (Master, Worker 1, Worker 2).\n  - Quản lý vòng đời Workloads, ConfigMaps, Secrets và Volumes trực quan.\n  - Theo dõi tỷ lệ sử dụng CPU, RAM thực tế của toàn cụm.\n\n', options: { fontSize: 9.5 } },
    { text: '• Phân quyền RBAC:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Hỗ trợ phân quyền truy cập theo từng dự án cho đội ngũ Dev và SecOps.', options: { fontSize: 9.5 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'Giao Diện Rancher Dashboard (Port 7443)', [
    'Nguồn: Trình duyệt vào https://<NLB_DNS>:7443/ hoặc qua IP Gateway 1.',
    'Chụp trang Cluster Overview: Hiển thị 3 Nodes, thanh đo CPU/Memory và trạng thái cụm.',
    'Chụp trang Workloads trong namespace online-boutique (các deployment màu xanh).'
  ]);

  s.addNotes('Rancher Server giúp chuẩn hóa quy trình vận hành Kubernetes trong môi trường doanh nghiệp, cung cấp góc nhìn trực quan về tài nguyên.');
}

// -------------------------------------------------------------
// SLIDE 12: BƯỚC 5 — WAZUH SIEM SOC
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Hệ Thống Wazuh SIEM SOC & Tích Hợp 5 Agents');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('KIẾN TRÚC GIÁM SÁT AN NINH SOC', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• Máy chủ Wazuh SIEM 10.0.20.10:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Đặt trong Subnet Quản trị riêng biệt, truy cập qua cổng 8443.\n  - Tích hợp Wazuh Indexer (OpenSearch) và Dashboard trực quan.\n\n', options: { fontSize: 9.5 } },
    { text: '• 5 Wazuh Agents Active:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Gateway 1 & 2: Thu thập log Suricata eve.json.\n  - K8s Master: Thu thập audit.log từ API Server.\n  - K8s Worker 1 & 2: Giám sát toàn vẹn file (FIM), tiến trình và log OS.\n\n', options: { fontSize: 9.5 } },
    { text: '• Tương quan sự kiện MITRE ATT&CK:\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Tự động đối chiếu hành vi tấn công theo khung tiêu chuẩn quốc tế.', options: { fontSize: 9.5 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'Giao Diện Wazuh Dashboard (Port 8443)', [
    'Nguồn: Trình duyệt vào https://<NLB_DNS>:8443/ hoặc qua IP Gateway 1.',
    'Chụp trang Wazuh Dashboard -> Agents: Hiển thị 5 Agents đều có trạng thái Active màu xanh.',
    'Chụp trang Security Events: Biểu đồ tổng quan sự kiện an ninh và ma trận MITRE ATT&CK.'
  ]);

  s.addNotes('Wazuh SIEM là trái tim an ninh của hệ thống. 5 Agent kết nối mã hóa liên tục đẩy log về, giúp phát hiện sớm các nguy cơ tấn công từ mạng biên cho tới bên trong cluster.');
}

// -------------------------------------------------------------
// SLIDE 13: KIỂM THỬ THỰC NGHIỆM
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Mô Phỏng Tấn Công Web & Cảnh Báo An Ninh Tự Động');

  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1 }
  });
  s.addText('KỊCH BẢN TẤN CÔNG & KẾT QUẢ', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.3, fontSize: 11, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '• Kịch bản 1: SQL Injection (UNION SELECT)\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - curl -s "http://13.251.225.100/?id=1%27%20UNION%20SELECT%20..."\n  - Suricata: Bắt rule 1000001, ghi nhận category "Web Application Attack".\n\n', options: { fontSize: 9.5 } },
    { text: '• Kịch bản 2: Directory Traversal (/etc/passwd)\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - curl -s "http://13.251.225.100/../../../../etc/passwd"\n  - Suricata: Bắt rule 1000003, ghi nhận flow TCP và source IP chính xác.\n\n', options: { fontSize: 9.5 } },
    { text: '• Kịch bản 3: XSS & Thăm dò file nhạy cảm (.env, .git)\n', options: { bold: true, fontSize: 10.5 } },
    { text: '  - Suricata ghi nhận alert trong eve.json tức thì (< 1 giây).\n  - Wazuh Indexer đẩy cảnh báo mức độ High lên màn hình trực ban SOC.', options: { fontSize: 9.5 } }
  ], { x: 0.8, y: 1.65, w: 3.8, h: 3.3 });

  addScreenshotBox(s, 5.0, 1.15, 4.4, 4.0, 'Log Suricata eve.json & Cảnh Báo Wazuh', [
    'Nguồn: Terminal chạy lệnh test curl và xem tail -n 20 /var/log/suricata/eve.json.',
    'Chụp log JSON hiển thị event_type: alert, signature: ATTACK SQL Injection.',
    'Nguồn: Wazuh Dashboard -> Modules -> Security Events -> Events table.',
    'Chụp chi tiết dòng sự kiện cảnh báo SQL Injection hoặc Directory Traversal màu đỏ/vàng.'
  ]);

  s.addNotes('Đây là slide thực nghiệm chứng minh hệ thống hoạt động thực tế. Khi chúng em gửi payload SQLi hay Path Traversal, Suricata lập tức phát hiện và Wazuh hiển thị cảnh báo ngay trên Dashboard.');
}

// -------------------------------------------------------------
// SLIDE 14: TỔNG KẾT (LIGHT MODE)
// -------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.lightBg };
  addHeader(s, 'Kết Quả Đạt Được & Định Hướng Phát Triển');

  // Left Box: Kết quả
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1.5 }
  });
  s.addText('🎉 KẾT QUẢ ĐẠT ĐƯỢC', {
    x: 0.8, y: 1.3, w: 3.8, h: 0.35, fontSize: 12, bold: true, color: C.brandDarkBlue
  });
  s.addText([
    { text: '✓ Sẵn Sàng Cao Multi-AZ: ', options: { bold: true, fontSize: 10.5, color: C.primary } },
    { text: 'Hệ thống vận hành song song trên 2 AZs, tự động cân bằng tải và failover qua AWS NLB.\n\n', options: { fontSize: 10, color: C.textMuted } },
    { text: '✓ Phòng Thủ Đa Lớp: ', options: { bold: true, fontSize: 10.5, color: C.primary } },
    { text: 'Kết hợp Security Group, Suricata DPI, HAProxy L4 và Cilium eBPF Zero-Trust.\n\n', options: { fontSize: 10, color: C.textMuted } },
    { text: '✓ Giám Sát SOC Tập Trung: ', options: { bold: true, fontSize: 10.5, color: C.primary } },
    { text: 'Wazuh SIEM tương quan đa nguồn (Suricata, K8s Audit, OS Log) từ 5 Agents.\n\n', options: { fontSize: 10, color: C.textMuted } },
    { text: '✓ Vận Hành Thực Tế: ', options: { bold: true, fontSize: 10.5, color: C.primary } },
    { text: '11 microservices Google Online Boutique chạy ổn định kèm co giãn HPA.', options: { fontSize: 10, color: C.textMuted } }
  ], { x: 0.8, y: 1.7, w: 3.8, h: 3.3 });

  // Right Box: Hướng phát triển
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 5.2, y: 1.15, w: 4.2, h: 4.0, rectRadius: 0.08,
    fill: { color: C.cardBg }, line: { color: C.cardBorder, width: 1.5 }
  });
  s.addText('🚀 ĐỊNH HƯỚNG NÂNG CẤP', {
    x: 5.4, y: 1.3, w: 3.8, h: 0.35, fontSize: 12, bold: true, color: 'D97706'
  });
  s.addText([
    { text: '1. Nâng cấp Suricata Inline IPS: ', options: { bold: true, fontSize: 10.5, color: C.primary } },
    { text: 'Chuyển từ chỉ cảnh báo (IDS) sang chủ động Drop gói tin tấn công tại card mạng (IPS).\n\n', options: { fontSize: 10, color: C.textMuted } },
    { text: '2. Tích hợp Quản Lý Bí Mật AWS KMS: ', options: { bold: true, fontSize: 10.5, color: C.primary } },
    { text: 'Sử dụng AWS Secrets Manager và External Secrets Operator cho cụm K8s.\n\n', options: { fontSize: 10, color: C.textMuted } },
    { text: '3. Siết Chặt Pod Security Standards: ', options: { bold: true, fontSize: 10.5, color: C.primary } },
    { text: 'Nâng mức PSA từ baseline lên restricted cho toàn bộ microservices.\n\n', options: { fontSize: 10, color: C.textMuted } },
    { text: '4. Tích hợp Tự Động Phản Ứng (SOAR): ', options: { bold: true, fontSize: 10.5, color: C.primary } },
    { text: 'Wazuh Active Response tự động chặn IP nguồn tấn công trên iptables của Gateway.', options: { fontSize: 10, color: C.textMuted } }
  ], { x: 5.4, y: 1.7, w: 3.8, h: 3.3 });

  s.addNotes('Em xin chân thành cảm ơn thầy cô và hội đồng đã chú ý lắng nghe bài thuyết trình. Nhóm rất mong nhận được những câu hỏi và ý kiến đóng góp từ thầy cô.');
}

const outputPath = '/home/vinh/Documents/project_ncs/presentation_ncs.pptx';
pres.writeFile({ fileName: outputPath }).then(() => {
  console.log(`PowerPoint slide deck created successfully at: ${outputPath}`);
}).catch(err => {
  console.error('Error generating presentation:', err);
  process.exit(1);
});
