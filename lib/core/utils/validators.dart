String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return null;
}

bool isRequired(String? value) {
  return value == null || value.trim().isEmpty;
}
