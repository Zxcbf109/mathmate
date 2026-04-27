/// 视频资料库 - 存储BV号，自动生成播放URL
/// 按学段和知识点分类
library;

class VideoResource {
  final String title;       // 知识点标题
  final String grade;       // 学段：小学/初中/高中
  final String module;      // 模块：如"方程与不等式"、"函数"等
  final String bvId;        // B站视频BV号（如 BV1qE411H7Uv）
  final String uploader;    // UP主

  const VideoResource({
    required this.title,
    required this.grade,
    required this.module,
    required this.bvId,
    required this.uploader,
  });

  /// 自动生成B站视频播放URL
  String get url => bvId.isEmpty
      ? ''
      : 'https://www.bilibili.com/video/$bvId/';
}

final List<VideoResource> allVideoResources = <VideoResource>[
  // ========== 初中数学 ==========
  // 数与式
  const VideoResource(
    title: '有理数合集',
    grade: '初中',
    module: '数与式',
    bvId: 'BV1qE411H7Uv',
    uploader: '一数',
  ),
  const VideoResource(
    title: '初一数学170讲',
    grade: '初中',
    module: '数与式',
    bvId: 'BV1eT411N7xP',
    uploader: '一点老师',
  ),

  // 方程与不等式
  const VideoResource(
    title: '一元二次方程与韦达定理',
    grade: '初中',
    module: '方程与不等式',
    bvId: 'BV1qE411H7Uv',
    uploader: '一数',
  ),
  const VideoResource(
    title: '方程系列',
    grade: '初中',
    module: '方程与不等式',
    bvId: 'BV1eT411N7xP',
    uploader: '一点老师',
  ),

  // 函数初步
  const VideoResource(
    title: '一次/二次/反比例函数合集',
    grade: '初中',
    module: '函数初步',
    bvId: 'BV1qE411H7Uv',
    uploader: '一数',
  ),
  const VideoResource(
    title: '函数系列',
    grade: '初中',
    module: '函数初步',
    bvId: 'BV1eT411N7xP',
    uploader: '一点老师',
  ),

  // 几何与图形
  const VideoResource(
    title: '全等/相似三角形合集 & 圆专题',
    grade: '初中',
    module: '几何与图形',
    bvId: 'BV1qE411H7Uv',
    uploader: '一数',
  ),
  const VideoResource(
    title: '几何辅助线技巧',
    grade: '初中',
    module: '几何与图形',
    bvId: 'BV1eT411N7xP',
    uploader: '一点老师',
  ),

  // 数据统计与概率
  const VideoResource(
    title: '数据分析与概率',
    grade: '初中',
    module: '数据统计与概率',
    bvId: 'BV1qE411H7Uv',
    uploader: '一数',
  ),

  // ========== 高中数学 ==========
  // 集合、逻辑与不等式
  const VideoResource(
    title: '集合与逻辑入门',
    grade: '高中',
    module: '集合、逻辑与不等式',
    bvId: 'BV1qE411H7Uv',
    uploader: '一数',
  ),
  const VideoResource(
    title: '不等式同步讲解',
    grade: '高中',
    module: '集合、逻辑与不等式',
    bvId: 'BV1oM4y117LP',
    uploader: '一数',
  ),
  const VideoResource(
    title: '核心概念梳理',
    grade: '高中',
    module: '集合、逻辑与不等式',
    bvId: 'BV1Z5411j7jB',
    uploader: '王梦抒',
  ),
  const VideoResource(
    title: '集合+逻辑基础',
    grade: '高中',
    module: '集合、逻辑与不等式',
    bvId: 'BV1iZ4y1x7Zk',
    uploader: '铭哥套路高考数学',
  ),
  const VideoResource(
    title: '基本不等式技巧',
    grade: '高中',
    module: '集合、逻辑与不等式',
    bvId: 'BV1EP4y1R7fz',
    uploader: '云凌Sapphire',
  ),
  const VideoResource(
    title: '高考数学复习大全',
    grade: '高中',
    module: '集合、逻辑与不等式',
    bvId: 'BV1EJ411y7J6',
    uploader: '鲲哥带你学数学',
  ),
  const VideoResource(
    title: '数学思想与方法',
    grade: '高中',
    module: '集合、逻辑与不等式',
    bvId: 'BV1jx41127Ky',
    uploader: '数学超人math',
  ),

  // 函数体系
  const VideoResource(
    title: '函数性质合集',
    grade: '高中',
    module: '函数体系',
    bvId: 'BV1nL41187k7',
    uploader: '一数',
  ),
  const VideoResource(
    title: '函数与导数综合',
    grade: '高中',
    module: '函数体系',
    bvId: 'BV1jJ411274s',
    uploader: '佟大大还是ETT',
  ),
  const VideoResource(
    title: '生活化函数案例',
    grade: '高中',
    module: '函数体系',
    bvId: 'BV1Z5411j7jB',
    uploader: '王梦抒',
  ),
  const VideoResource(
    title: '函数性质速解',
    grade: '高中',
    module: '函数体系',
    bvId: 'BV1iZ4y1x7Zk',
    uploader: '铭哥套路高考数学',
  ),
  const VideoResource(
    title: '函数拔高专题',
    grade: '高中',
    module: '函数体系',
    bvId: 'BV1EJ411y7J6',
    uploader: '鲲哥带你学数学',
  ),

  // 三角函数
  const VideoResource(
    title: '正弦/余弦定理',
    grade: '高中',
    module: '三角函数',
    bvId: 'BV1nL41187k7',
    uploader: '一数',
  ),
  const VideoResource(
    title: '三角函数母题精讲',
    grade: '高中',
    module: '三角函数',
    bvId: 'BV1hC4y1j7xK',
    uploader: '赵礼显老师',
  ),
  const VideoResource(
    title: '恒等变换技巧',
    grade: '高中',
    module: '三角函数',
    bvId: 'BV1iZ4y1x7Zk',
    uploader: '赵礼显老师',
  ),
  const VideoResource(
    title: '三角函数基础',
    grade: '高中',
    module: '三角函数',
    bvId: 'BV1Z5411j7jB',
    uploader: '王梦抒',
  ),
  const VideoResource(
    title: '诱导公式记忆法',
    grade: '高中',
    module: '三角函数',
    bvId: 'BV1rk4y1A7mV',
    uploader: '铭哥套路高考数学',
  ),
  const VideoResource(
    title: '三角函数拔高',
    grade: '高中',
    module: '三角函数',
    bvId: 'BV1EJ411y7J6',
    uploader: '鲲哥带你学数学',
  ),

  // 向量与复数
  const VideoResource(
    title: '平面向量合集',
    grade: '高中',
    module: '向量与复数',
    bvId: 'BV1nL41187k7',
    uploader: '一数',
  ),
  const VideoResource(
    title: '复数专题',
    grade: '高中',
    module: '向量与复数',
    bvId: 'BV1jJ411274s',
    uploader: '佟大大还是ETT',
  ),
  const VideoResource(
    title: '向量与复数的巧算',
    grade: '高中',
    module: '向量与复数',
    bvId: 'BV1iZ4y1x7Zk',
    uploader: '铭哥套路高考数学',
  ),
  const VideoResource(
    title: '向量拔高专题',
    grade: '高中',
    module: '向量与复数',
    bvId: 'BV1EJ411y7J6',
    uploader: '鲲哥带你学数学',
  ),

  // 立体几何
  const VideoResource(
    title: '立体几何全讲解',
    grade: '高中',
    module: '立体几何',
    bvId: 'BV1nL41187k7',
    uploader: '一数',
  ),
  const VideoResource(
    title: '几何体计算',
    grade: '高中',
    module: '立体几何',
    bvId: 'BV1oM4y117LP',
    uploader: '一数',
  ),
  const VideoResource(
    title: '空间向量妙用',
    grade: '高中',
    module: '立体几何',
    bvId: 'BV1jJ411274s',
    uploader: '佟大大还是ETT',
  ),
  const VideoResource(
    title: '线面平行讲解',
    grade: '高中',
    module: '立体几何',
    bvId: 'BV1rk4y1A7mV',
    uploader: '铭哥套路高考数学',
  ),
  const VideoResource(
    title: '空间垂直关系',
    grade: '高中',
    module: '立体几何',
    bvId: 'BV1EP4y1R7fz',
    uploader: '云凌Sapphire',
  ),
  const VideoResource(
    title: '立体几何拔高',
    grade: '高中',
    module: '立体几何',
    bvId: 'BV1EJ411y7J6',
    uploader: '鲲哥带你学数学',
  ),

  // 解析几何
  const VideoResource(
    title: '直线与圆合集',
    grade: '高中',
    module: '解析几何',
    bvId: 'BV1nL41187k7',
    uploader: '一数',
  ),
  const VideoResource(
    title: '圆锥曲线大全',
    grade: '高中',
    module: '解析几何',
    bvId: 'BV1jJ411274s',
    uploader: '佟大大还是ETT',
  ),
  const VideoResource(
    title: '圆锥曲线二级结论',
    grade: '高中',
    module: '解析几何',
    bvId: 'BV1hC4y1j7xK',
    uploader: '赵礼显老师',
  ),
  const VideoResource(
    title: '导数与圆锥曲线综合',
    grade: '高中',
    module: '解析几何',
    bvId: 'BV1hC4y1j7xK',
    uploader: '赵礼显老师',
  ),
  const VideoResource(
    title: '大题第一问秒杀',
    grade: '高中',
    module: '解析几何',
    bvId: 'BV1iZ4y1x7Zk',
    uploader: '铭哥套路高考数学',
  ),
  const VideoResource(
    title: '解析几何拔高',
    grade: '高中',
    module: '解析几何',
    bvId: 'BV1EJ411y7J6',
    uploader: '鲲哥带你学数学',
  ),

  // 数列
  const VideoResource(
    title: '等差与等比数列',
    grade: '高中',
    module: '数列',
    bvId: 'BV1nL41187k7',
    uploader: '一数',
  ),
  const VideoResource(
    title: '错位相减法',
    grade: '高中',
    module: '数列',
    bvId: 'BV1jJ411274s',
    uploader: '佟大大还是ETT',
  ),
  const VideoResource(
    title: '零基础学数列',
    grade: '高中',
    module: '数列',
    bvId: 'BV1Z5411j7jB',
    uploader: '王梦抒',
  ),
  const VideoResource(
    title: '数列求通项公式',
    grade: '高中',
    module: '数列',
    bvId: 'BV1rk4y1A7mV',
    uploader: '铭哥套路高考数学',
  ),
  const VideoResource(
    title: '数列拔高专题',
    grade: '高中',
    module: '数列',
    bvId: 'BV1EJ411y7J6',
    uploader: '鲲哥带你学数学',
  ),

  // 导数及其应用
  const VideoResource(
    title: '导数综合讲解',
    grade: '高中',
    module: '导数及其应用',
    bvId: 'BV1nL41187k7',
    uploader: '一数',
  ),
  const VideoResource(
    title: '导数大题拆解',
    grade: '高中',
    module: '导数及其应用',
    bvId: 'BV1jJ411274s',
    uploader: '佟大大还是ETT',
  ),
  const VideoResource(
    title: '极值点偏移专题',
    grade: '高中',
    module: '导数及其应用',
    bvId: 'BV1Z5411j7jB',
    uploader: '王梦抒',
  ),
  const VideoResource(
    title: '导数与不等式证明',
    grade: '高中',
    module: '导数及其应用',
    bvId: 'BV1hC4y1j7xK',
    uploader: '赵礼显老师',
  ),
  const VideoResource(
    title: '导数拔高专题',
    grade: '高中',
    module: '导数及其应用',
    bvId: 'BV1EJ411y7J6',
    uploader: '鲲哥带你学数学',
  ),

  // 概率统计与排列组合
  const VideoResource(
    title: '排列组合合集',
    grade: '高中',
    module: '概率统计与排列组合',
    bvId: 'BV1nL41187k7',
    uploader: '一数',
  ),
  const VideoResource(
    title: '随机变量的期望方差',
    grade: '高中',
    module: '概率统计与排列组合',
    bvId: 'BV1jJ411274s',
    uploader: '佟大大还是ETT',
  ),
  const VideoResource(
    title: '生活化案例讲解',
    grade: '高中',
    module: '概率统计与排列组合',
    bvId: 'BV1Z5411j7jB',
    uploader: '王梦抒',
  ),
  const VideoResource(
    title: '条件概率讲解',
    grade: '高中',
    module: '概率统计与排列组合',
    bvId: 'BV1iZ4y1x7Zk',
    uploader: '铭哥套路高考数学',
  ),
  const VideoResource(
    title: '概率统计拔高',
    grade: '高中',
    module: '概率统计与排列组合',
    bvId: 'BV1jx41127Ky',
    uploader: '数学超人math',
  ),
];

/// 按学段获取视频资源
List<VideoResource> getVideoResourcesByGrade(String grade) {
  return allVideoResources
      .where((r) => r.grade == grade)
      .toList();
}

/// 按模块获取视频资源
List<VideoResource> getVideoResourcesByModule(String module) {
  return allVideoResources
      .where((r) => r.module == module)
      .toList();
}

/// 获取所有学段
List<String> getAllGrades() {
  return allVideoResources.map((r) => r.grade).toSet().toList();
}

/// 获取指定学段的所有模块
List<String> getModulesByGrade(String grade) {
  return allVideoResources
      .where((r) => r.grade == grade)
      .map((r) => r.module)
      .toSet()
      .toList();
}
