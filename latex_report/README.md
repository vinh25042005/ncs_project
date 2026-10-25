# HƯỚNG DẪN BIÊN DỊCH BÁO CÁO PROJECT K8S (LATEX / OVERLEAF)

Thư mục này chứa toàn bộ mã nguồn LaTeX của báo cáo kỹ thuật **"BÁO CÁO PROJECT K8S"** được tổ chức theo cấu trúc đa mô-đun (modular) chuẩn học thuật.

---

## 1. Cấu Trúc Dự Án
```text
latex_report/
├── main.tex                    # File cấu hình chính, định nghĩa kiểu dáng, trang bìa, mục lục
├── references.bib              # Danh mục tài liệu tham khảo chuẩn BibTeX
├── images/
│   └── architecture_diagram.png # Sơ đồ kiến trúc hạ tầng mạng AWS Enterprise
├── chapters/
│   ├── ch1_architecture.tex    # Chương 1: Kiến trúc & Topology hệ thống (VPC, Subnet, Route, Port Mapping)
│   ├── ch2_components.tex      # Chương 2: Các thành phần triển khai & Vai trò (Lý do cần, nhiệm vụ)
│   ├── ch3_deployment.tex      # Chương 3: Chi tiết quy trình triển khai (Terraform, Gateway, K8s, Rancher, Wazuh)
│   ├── ch4_testing.tex         # Chương 4: Đánh giá & Kiểm thử tính năng (5 kịch bản thực tế kèm log/status)
│   └── ch5_conclusion.tex      # Chương 5: Kết luận & Hướng phát triển trong tương lai
└── README.md                   # Tài liệu hướng dẫn biên dịch
```

---

## 2. Hướng Dẫn Tải Lên & Biên Dịch Trên Overleaf (Khuyên Dùng)

1. Tải file nén sẵn có ở thư mục gốc repository:
   **`bao_cao_project_k8s_overleaf.zip`**
2. Đăng nhập vào [Overleaf](https://www.overleaf.com/).
3. Tại trang tổng quan Projects, bấm **New Project** $\rightarrow$ chọn **Upload Project**.
4. Kéo thả hoặc chọn file `bao_cao_project_k8s_overleaf.zip` để tải lên.
5. Overleaf sẽ tự động giải nén và mở dự án.
6. Đảm bảo cấu hình trình biên dịch (ở góc trên bên trái menu **Menu** $\rightarrow$ **Compiler**):
   - **Compiler**: `pdfLaTeX` (Mặc định)
   - **TeX Live Version**: `2024` hoặc `2023`
   - **Main document**: `main.tex`
7. Bấm nút xanh **Recompile** (hoặc `Ctrl + Enter`) để xuất file PDF hoàn chỉnh.

---

## 3. Hướng Dẫn Biên Dịch Cục Bộ Bằng TeX Live (Nếu Cài Sẵn Trên Máy)

Chạy các lệnh sau trong thư mục `latex_report`:
```bash
# Biên dịch lần 1
pdflatex main.tex

# Xử lý tài liệu tham khảo BibTeX
bibtex main

# Biên dịch lần 2 & 3 để hoàn thiện liên kết chéo và số trang mục lục
pdflatex main.tex
pdflatex main.tex
```
File PDF đầu ra sẽ được tạo tại `main.pdf`.
