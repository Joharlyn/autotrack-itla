class ApiErrorHelper {
  static bool isAuthError(Object error) {
    final text = error.toString().toLowerCase();

    return text.contains('token no valido') ||
        text.contains('token no válido') ||
        text.contains('expirado') ||
        text.contains('unauthorized') ||
        text.contains('401');
  }

  static String moduleAccessMessage({
    required String moduleName,
    required bool isLoggedIn,
  }) {
    if (isLoggedIn) {
      return 'El servidor rechazó tu sesión al intentar cargar $moduleName. Cierra sesión e inicia de nuevo.';
    }

    return 'Este módulo aparece como parte del bloque sin login de la tarea, pero el servidor actual exige iniciar sesión para cargar $moduleName.';
  }
}
