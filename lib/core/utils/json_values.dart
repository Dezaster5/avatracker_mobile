// Толерантное чтение JSON: backend присылает числа и числами, и строками.

/// Целое из числа (дробная часть отбрасывается) или строки.
int? jsonInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}');

/// Число с плавающей точкой из числа или строки.
double? jsonDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? ''}');
