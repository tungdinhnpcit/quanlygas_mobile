class CongNoChuyenXeModel {
  final int chuyenXeId;
  final String maChuyenXe;
  final String ngayXuat;
  final double soTienNo;
  final double daTra;
  final double conNo;

  CongNoChuyenXeModel.fromJson(Map<String, dynamic> j)
      : chuyenXeId = j['chuyenXeId'],
        maChuyenXe = j['maChuyenXe'] ?? '',
        ngayXuat   = j['ngayXuat'] ?? '',
        soTienNo   = (j['soTienNo'] as num).toDouble(),
        daTra      = (j['daTra'] as num).toDouble(),
        conNo      = (j['conNo'] as num).toDouble();
}
