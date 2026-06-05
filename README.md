# Diccing - Diccionario de Términos de Ingeniería

Aplicación móvil desarrollada en Flutter diseñada para la consulta, aprendizaje y gestión de términos relacionados con la ingeniería de sistemas e informática. La plataforma permite a los usuarios buscar conceptos técnicos, administrar un diccionario personal y contribuir con nuevas definiciones al diccionario global.

## Características Principales

*   **Búsqueda y Exploración:** Acceso rápido y estructurado a definiciones técnicas.
*   **Gestión de Tema:** Soporte integral para modo claro y oscuro, conservando las preferencias del usuario de forma persistente.
*   **Diccionario Personal:** Autenticación de usuarios (incluyendo el inicio de sesión con Google) para habilitar la creación, edición y eliminación de términos propios en la sección "Mi Diccionario".
*   **Estadísticas Globales:** Visualización de los conceptos más consultados y de mayor relevancia para la comunidad.
*   **Sistema de Sugerencias:** Interfaz que permite a los usuarios proponer nuevos términos para su revisión e incorporación al diccionario general.
*   **Interacción y Difusión:** Funcionalidad integrada para compartir definiciones fácilmente.
*   **Experiencia de Usuario Continua:** Implementación de indicadores de carga y manejo adecuado de estados durante la ausencia de conexión a internet.
*   **Panel de Administración:** Módulo dedicado a la gestión y moderación de las sugerencias aportadas por los usuarios.

## Tecnologías y Dependencias

*   **Framework:** [Flutter](https://flutter.dev/) (SDK >= 3.9.0)
*   **Base de Datos y Autenticación:** [Supabase](https://supabase.com/) (`supabase_flutter`)
*   **Persistencia Local:** `shared_preferences` (utilizado para conservar la configuración visual y el estado de la pantalla de introducción).
*   **Librerías Adicionales:**
    *   `share_plus`: Integración para compartir contenido nativamente.
    *   `cupertino_icons`: Set de iconografía estándar de iOS.
    *   Tipografías personalizadas: Inter y Angkor.

## Estructura del Proyecto

El código fuente principal se encuentra en la carpeta `lib/`:

*   `baseDeDatos/`: Configuración del cliente y conexión con los servicios de Supabase.
*   `logica/`: Implementación de la lógica de negocio y controladores de la aplicación.
*   `pantallas/`: Vistas principales de la interfaz de usuario (Inicio, Búsqueda, Favoritos, Detalles de Términos, etc.).
*   `provider/`: Gestión del estado global y reactividad de la aplicación.
*   `services/`: Integración con servicios externos y herramientas de terceros.
*   `widgets/`: Componentes modulares y reutilizables de la interfaz (tarjetas, botones, indicadores visuales de carga).

## Configuración y Ejecución

Para compilar y ejecutar este proyecto en un entorno de desarrollo local, es necesario contar con el SDK de Flutter instalado y configurado correctamente.

1.  **Clonar el repositorio:**
    ```bash
    git clone <url-del-repositorio>
    ```

2.  **Instalar las dependencias del proyecto:**
    ```bash
    flutter pub get
    ```

3.  **Configurar los servicios en la nube:**
    Es imprescindible establecer las credenciales del proyecto de Supabase. Ingrese la URL del entorno y la clave pública (Anon Key) en el archivo de conexión correspondiente (`lib/baseDeDatos/conexion.dart`).

4.  **Ejecutar la aplicación:**
    ```bash
    flutter run
    ```
