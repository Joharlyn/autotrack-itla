# AutoTrack ITLA

Aplicación móvil desarrollada en Flutter para la gestión integral de vehículos, como parte de la práctica final de Aplicaciones Móviles en ITLA.

## Autor

**Joharlyn Steven Gonzalez Zabala**
**Matrícula:** 2023-0181
**Correo:** [joharlyn041@gmail.com](mailto:joharlyn041@gmail.com)

## Descripción

La aplicación permite registrar vehículos, gestionar mantenimientos, combustible, aceite, estado de gomas, gastos e ingresos, además de consultar noticias automotrices, videos educativos, un foro comunitario y un catálogo de vehículos.

## Tecnologías utilizadas

* Flutter
* Dart
* Android Studio Emulator
* VS Code
* API REST Vehículos ITLA

## Módulos implementados

### Sin login

* Inicio / Dashboard
* Registro y activación
* Noticias automotrices
* Videos educativos
* Catálogo de vehículos
* Foro comunitario (solo lectura)
* Acerca de

### Con login

* Iniciar sesión
* Recuperar contraseña
* Mi perfil
* Cambio de foto de perfil
* Mis vehículos
* Crear, editar y cambiar foto de vehículo
* Mantenimientos
* Combustible y aceite
* Estado de gomas
* Gastos e ingresos
* Foro autenticado
* Crear temas y responder

## Estructura general del proyecto

* `lib/app` → configuración general y rutas
* `lib/core` → tema, constantes, red y sesión
* `lib/features` → módulos principales
* `lib/shared` → widgets y utilidades compartidas
* `assets` → imágenes e íconos

## Ejecución

1. Instalar dependencias con `flutter pub get`
2. Ejecutar la app en emulador Android
3. Iniciar sesión o usar los módulos públicos según disponibilidad del backend

## Observaciones

Algunos endpoints marcados como públicos en el enunciado presentan restricciones de autenticación en el comportamiento real del backend. La aplicación fue adaptada para manejar correctamente esos casos sin romper la experiencia del usuario.
