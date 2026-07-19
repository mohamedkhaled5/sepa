class ExamModel {
  String? id;

  bool? isPresent;
  String? examName;
  String? date;
  double? currentDegree;
  double? maxDegree;

  ExamModel({
    this.id,
    this.isPresent,
    this.examName,
    this.date,
    this.currentDegree,
    this.maxDegree,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isPresent': isPresent,
      'examName': examName,
      'date': date,
      'currentDegree': currentDegree,
      'maxDegree': maxDegree,
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'],
      isPresent: map['isPresent'],
      examName: map['examName'],
      date: map['date'],
      currentDegree: map['currentDegree'],
      maxDegree: map['maxDegree'],
    );
  }
}
