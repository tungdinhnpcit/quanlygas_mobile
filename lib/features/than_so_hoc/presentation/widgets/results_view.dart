// lib/features/than_so_hoc/presentation/widgets/results_view.dart
import 'package:flutter/material.dart';

import '../../../../core/utils/numerology/meanings.dart';
import '../../../../core/utils/numerology/types.dart';

/// Hien thi toan bo ket qua tinh than so hoc.
///
/// [rawBirthDay] la ngay-trong-thang tho (1-31, VD ngay 19/05 -> 19), dung
/// rieng de tra bang y nghia "CS Ngay sinh" -- KHAC voi chi so Ngay sinh da
/// tinh (result.ngaySinh), vi bang y nghia nguon goc tra theo ngay-trong-
/// thang tho chu khong phai chi so da cong don/rut gon (xem muc 8 tai lieu
/// cong thuc).
class NumerologyResultsView extends StatelessWidget {
  final NumerologyResult result;
  final int rawBirthDay;

  const NumerologyResultsView({
    super.key,
    required this.result,
    required this.rawBirthDay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('6 chỉ số chính'),
        _IndexCard(
          title: 'Chỉ số Đường đời',
          value: result.duongDoi.display,
          meaning: duongDoiMeaning(result.duongDoi.display),
        ),
        _IndexCard(
          title: 'Chỉ số Ngày sinh (trong tháng)',
          value: rawBirthDay,
          meaning: ngaySinhMeaning(rawBirthDay),
          subtitle: 'Chỉ số ngày sinh đã cộng dồn: ${result.ngaySinh.display}',
        ),
        _IndexCard(
          title: 'Chỉ số Sứ mệnh (Tên khai sinh)',
          value: result.suMenh.display,
          meaning: tenKhaiSinhMeaning(result.suMenh.display),
        ),
        _IndexCard(
          title: 'Chỉ số Thái độ',
          value: result.thaiDo.display,
          meaning: thaiDoMeaning(result.thaiDo.display),
        ),
        _IndexCard(title: 'Chỉ số Nhân cách / Tương tác', value: result.nhanCach.display),
        _IndexCard(title: 'Chỉ số Linh hồn / Nội tâm', value: result.linhHon.display),
        const SizedBox(height: 8),
        _SectionTitle('Chỉ số bổ trợ'),
        _ExtrasCard(result: result),
        const SizedBox(height: 8),
        _SectionTitle('Danh đồ (từ tên) & Sinh đồ (từ ngày sinh)'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _GridCard(title: 'Danh đồ', grid: result.danhDo)),
            const SizedBox(width: 12),
            Expanded(child: _GridCard(title: 'Sinh đồ', grid: result.sinhDo)),
          ],
        ),
        const SizedBox(height: 8),
        _SectionTitle('Năm / Tháng / Ngày cá nhân'),
        _PersonalCycleCard(result: result),
        const SizedBox(height: 8),
        _SectionTitle('4 đỉnh cao, 4 thử thách & 3 giai đoạn'),
        _PeaksChallengesCard(result: result),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _IndexCard extends StatelessWidget {
  final String title;
  final int value;
  final String? meaning;
  final String? subtitle;

  const _IndexCard({
    required this.title,
    required this.value,
    this.meaning,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 20, child: Text('$value')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (meaning == null) {
      return Card(margin: const EdgeInsets.only(bottom: 8), child: content);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            CircleAvatar(radius: 18, child: Text('$value')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(meaning!),
          ),
        ],
      ),
    );
  }
}

class _ExtrasCard extends StatelessWidget {
  final NumerologyResult result;
  const _ExtrasCard({required this.result});

  String _digitsOrNone(List<int> digits) => digits.isEmpty ? 'Không có' : digits.join(', ');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Chỉ số trưởng thành', '${result.truongThanh.display}'),
            _kv('Tuổi bắt đầu trưởng thành', '${result.tuoiBatDauTruongThanh}'),
            _kv('Chỉ số cân bằng', '${result.canBang.display}'),
            _kv('Kết nối Đường đời - Sứ mệnh', '${result.ketNoiDuongDoiSuMenh}'),
            _kv('Kết nối Linh hồn - Nhân cách', '${result.ketNoiLinhHonNhanCach}'),
            _kv('Chỉ số nội cảm', _digitsOrNone(result.noiCam)),
            _kv('Chỉ số thiếu', _digitsOrNone(result.chiSoThieu)),
            _kv('Chỉ lặp trong 6 CS chính', '${result.chiLapTrong6CSChinh}'),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _GridCard extends StatelessWidget {
  final String title;
  final NumerologyGrid grid;
  const _GridCard({required this.title, required this.grid});

  static const _rows = [
    [3, 6, 9],
    [2, 5, 8],
    [1, 4, 7],
  ];

  @override
  Widget build(BuildContext context) {
    final fullArrows = grid.arrows.entries.where((e) => e.value == ArrowState.full).map((e) => e.key).toList();
    final emptyArrows = grid.arrows.entries.where((e) => e.value == ArrowState.empty).map((e) => e.key).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final row in _rows)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final digit in row)
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        grid.digitCounts[digit]! > 0
                            ? List.filled(grid.digitCounts[digit]!, digit).join('')
                            : '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            if (fullArrows.isNotEmpty)
              Text('Mũi tên: ${fullArrows.join(', ')}', style: const TextStyle(fontSize: 12)),
            if (emptyArrows.isNotEmpty)
              Text('Trống: ${emptyArrows.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _PersonalCycleCard extends StatelessWidget {
  final NumerologyResult result;
  const _PersonalCycleCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _cycleItem('Năm', result.namCaNhan.display)),
            Expanded(child: _cycleItem('Tháng', result.thangCaNhan.display)),
            Expanded(child: _cycleItem('Ngày', result.ngayCaNhan.display)),
          ],
        ),
      ),
    );
  }

  Widget _cycleItem(String label, int value) => Column(
        children: [
          Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
}

class _PeaksChallengesCard extends StatelessWidget {
  final NumerologyResult result;
  const _PeaksChallengesCard({required this.result});

  static const _peakLabels = ['Đỉnh cao 1', 'Đỉnh cao 2', 'Đỉnh cao 3', 'Đỉnh cao 4'];
  static const _challengeLabels = ['Thử thách 1', 'Thử thách 2', 'Thử thách 3', 'Thử thách 4'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(_peakLabels[i])),
                    Text('${result.dinhCao[i].value.display}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    Text('từ tuổi ${result.dinhCao[i].startAge}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            const Divider(height: 20),
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(_challengeLabels[i])),
                    Text('${result.thuThach[i].display}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: Text('Tiền vận: ${result.baGiaiDoan.tienVan}')),
                Expanded(child: Text('Trung vận: ${result.baGiaiDoan.trungVan}')),
                Expanded(child: Text('Hậu vận: ${result.baGiaiDoan.hauVan}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
