/// Типы отметок (ТЗ, раздел 8) и их подписи.
String markTypeLabel(String? markType) {
  switch (markType) {
    case 'check_in':
      return 'Приход';
    case 'check_out':
      return 'Уход';
    case 'presence':
    case 'extra':
      return 'Проверка присутствия';
    case 'weekend_work':
      return 'Работа в выходной';
    case 'unscheduled':
      return 'Внеплановая отметка';
    case 'late':
      return 'Опоздание';
    default:
      return markType ?? '';
  }
}
