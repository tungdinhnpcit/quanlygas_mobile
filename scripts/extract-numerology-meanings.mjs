// scripts/extract-numerology-meanings.mjs
//
// Script Node chay MOT LAN, doc bang y nghia tu file nguon
// "D:\Work\ThanSoHoc\TSH Hien Mira _ Tong hop thong tin cac chi so.xlsx"
// va sinh ra lib/core/utils/numerology/meanings_data.dart (const Map).
//
// Chay: node scripts/extract-numerology-meanings.mjs
// Yeu cau: package "xlsx" (npm install xlsx --no-save neu chua co trong project nay,
// hoac chay bang node co san package xlsx, vi du trong gas_fe/node_modules).

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import XLSX from 'xlsx';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SOURCE_XLSX =
  'D:/Work/ThanSoHoc/TSH Hiền Mira _ Tổng hợp thông tin các chỉ số.xlsx';
const OUTPUT_DART = path.join(
  __dirname,
  '../lib/core/utils/numerology/meanings_data.dart'
);

function readSheet(wb, sheetName) {
  const ws = wb.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(ws, { header: 1 });
  const out = {};
  // Header thuc su o dong index 4 (0-based); du lieu bat dau tu dong 5.
  rows.slice(5).forEach((r) => {
    if (!r || r[1] === undefined) return;
    const m = /Chỉ số (\d+)/.exec(String(r[1]));
    if (!m) return;
    const num = parseInt(m[1], 10);
    out[num] = (r[2] || '').toString().trim();
  });
  return out;
}

function esc(s) {
  return String(s)
    .replaceAll('\\', '\\\\')
    .replaceAll("'", "\\'")
    .replaceAll('\r\n', '\n')
    .replaceAll('\n', '\\n')
    .replaceAll('\r', '');
}

function mapLiteral(obj) {
  const keys = Object.keys(obj)
    .map(Number)
    .sort((a, b) => a - b);
  const lines = keys.map((k) => `    ${k}: '${esc(obj[k])}',`);
  return '{\n' + lines.join('\n') + '\n  }';
}

const wb = XLSX.readFile(SOURCE_XLSX);
const data = {
  duongDoi: readSheet(wb, '1. CS Đường đời'), // 1-11, 22, 33
  ngaySinh: readSheet(wb, '2. CS Ngày sinh'), // 1-31
  tenKhaiSinh: readSheet(wb, '3. CS Tên Khai sinh'), // 1-11
  thaiDo: readSheet(wb, '8. CS Thái độ'), // 1-11, 22, 33
};

let out = '';
out += '// lib/core/utils/numerology/meanings_data.dart\n';
out +=
  '// Du lieu duoc trich xuat tu "TSH Hien Mira _ Tong hop thong tin cac chi so.xlsx"\n';
out +=
  '// bang script scripts/extract-numerology-meanings.mjs. Mot so so trong file\n';
out += '// nguon khong co van ban dien giai (chuoi rong) -- UI can tu xu ly fallback.\n\n';
out += 'const Map<int, String> duongDoiMeanings = ' + mapLiteral(data.duongDoi) + ';\n\n';
out += 'const Map<int, String> ngaySinhMeanings = ' + mapLiteral(data.ngaySinh) + ';\n\n';
out +=
  'const Map<int, String> tenKhaiSinhMeanings = ' + mapLiteral(data.tenKhaiSinh) + ';\n\n';
out += 'const Map<int, String> thaiDoMeanings = ' + mapLiteral(data.thaiDo) + ';\n';

fs.writeFileSync(OUTPUT_DART, out, 'utf8');
console.log('Da sinh', OUTPUT_DART);
