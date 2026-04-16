3er sprint — HUs 
HU10 — Visualizar Modo Oscuro
ID: HU10
Título: Visualizar Modo Oscuro
Descripción: Como usuario, quiero poder cambiar entre modo claro y modo oscuro en la aplicación y que mi preferencia se recuerde entre sesiones, para adaptar la experiencia visual a mis preferencias o condiciones de iluminación.
Criterios de Aceptación:
* La aplicación cuenta con un ThemeData oscuro correctamente aplicado en todas las pantallas.
* Existe un control accesible para cambiar entre modo claro y oscuro desde la app.
* La preferencia de tema se guarda con SharedPreferences y se aplica al reabrir la app.
* Todos los textos, fondos e íconos son legibles en ambos modos.
Tareas:
* Task 1: Implementar ThemeData oscuro completo en la aplicación Flutter y agregar toggle Claro/Oscuro accesible desde pantalla Inicio, persistiendo la preferencia con SharedPreferences para que se recuerde entre sesiones.
* Task 2: Verificar la legibilidad y consistencia visual de todos los elementos (textos, fondos, íconos, cards, chips) en modo oscuro en todas las pantallas de la aplicación.


HU11 — Visualizar Pantallas de Introducción
ID: HU11
Título: Visualizar Pantallas de Introducción
Descripción: Como nuevo usuario, quiero ver una pantalla de bienvenida con slides explicativos la primera vez que abro la aplicación, para entender rápidamente qué funcionalidades ofrece el Glosario Informático.
Criterios de Aceptación:
* La pantalla de onboarding se muestra únicamente la primera vez que el usuario abre la app.
* El onboarding tiene 3 slides con título, imagen ilustrativa y descripción de cada función principal.
* El usuario puede avanzar entre slides con swipe o botón Siguiente.
* Existe un botón Saltar para omitir el onboarding y acceder directamente a la app.
* En aperturas posteriores la app va directamente a pantalla Inicio sin mostrar onboarding.
Tareas:
* Task 1: Crear pantalla de Onboarding con 3 slides (Buscar, Favoritos, Sugerir) con diseño visual atractivo, navegación entre slides por swipe o botón Siguiente, y botones Saltar y Comenzar que navegan a pantalla Inicio.
* Task 2: Implementar lógica de primera apertura usando SharedPreferences para mostrar el Onboarding únicamente la primera vez que el usuario ejecuta la app, redirigiendo directamente a Inicio en aperturas posteriores.


HU12 — Visualizar Estadísticas Globales
ID: HU12
Título: Visualizar Estadísticas Globales
Descripción: Como usuario, quiero visualizar cuáles son los términos más consultados por todos los usuarios de la aplicación para descubrir los conceptos más relevantes y orientar mi aprendizaje.
Criterios de Aceptación:
* El contador de vistas se incrementa en Supabase cada vez que cualquier usuario abre el detalle de un término.
* La pantalla Inicio incluye una sección con los 5 términos más consultados globalmente ordenados de mayor a menor.
* La sección se actualiza cada vez que se recarga la pantalla Inicio.
Tareas:
* Task 1: Implementar contador global de vistas en tabla terminos de Supabase (incremento al abrir detalle) y crear sección en pantalla Inicio que consulte y muestre los 5 términos con más vistas globales ordenados descendentemente.
* Task 2: Optimizar la consulta de términos más consultados para que no impacte el tiempo de carga general de la pantalla Inicio, usando carga asíncrona independiente de los otros componentes.


HU13 — Visualizar Indicadores Visuales
ID: HU13
Título: Visualizar Indicadores Visuales
Descripción: Como usuario, quiero que la aplicación muestre indicadores visuales mientras carga datos y mensajes amigables cuando no hay conexión, para tener siempre información del estado de la app y nunca ver pantallas en blanco.
Criterios de Aceptación:
* Todas las pantallas con listas muestran un skeleton o indicador de carga mientras se obtienen datos de Supabase.
* Si no hay conexión a internet se muestra una pantalla de error con mensaje amigable y botón Reintentar.
* Al presionar Reintentar la pantalla vuelve a intentar cargar los datos desde BD.
* No existen pantallas en blanco sin contexto visual para el usuario.
Tareas:
* Task 1: Implementar widget de error sin conexión con mensaje amigable y botón Reintentar, aplicarlo en todas las pantallas que consumen datos de Supabase y verificar comportamiento en modo avión y al recuperar conectividad.
* Task 2: Agregar indicadores de carga (skeleton o shimmer) en todas las pantallas con listas (Búsqueda, Favoritos, Historial, Inicio) para eliminar pantallas en blanco mientras se obtienen datos.




HU14 — Inicio de sesión con Google
ID: HU14
Título: Inicio de sesión con Google
Descripción: Como usuario, quiero poder iniciar sesión opcionalmente con mi cuenta de Google, para acceder a funcionalidades personalizadas y sincronizar mi diccionario personal entre dispositivos sin obligación de crear una cuenta.
Criterios de Aceptación:
* La aplicación funciona completamente sin autenticación (usuario anónimo por dispositivo).
* Existe un botón accesible "Iniciar sesión con Google" en la pantalla Inicio o en un menú principal.
* Al tocar el botón se abre el flujo nativo de autenticación de Google.
* Tras autenticarse exitosamente se guarda el token de sesión en Supabase Auth.
* El usuario autenticado puede ver su nombre/email en la UI (ej: header o menú).
* Existe un botón para cerrar sesión que borra los datos de autenticación.
* La sesión persiste entre cierres y aperturas de la app.
* El usuario puede cambiar entre sesión anónima y autenticada sin pérdida de datos previos.
* Tareas:
* Task 1: Configurar Google OAuth en Supabase Console (credenciales de Google Cloud), agregar dependencia `google_sign_in` si es necesaria y documentar el setup.
* Task 2: Implementar botón "Iniciar sesión con Google" en pantalla Inicio, conectar al flujo de autenticación de Supabase y guardar el estado de sesión en un Provider de autenticación global.
* Task 3: Implementar lógica de persistencia de sesión con recuperación automática al abrir la app, mostrar nombre/email del usuario autenticado en UI y crear botón de cerrar sesión que limpie el estado de autenticación.






HU-15: Crear un término personal
Descripción: Como usuario autenticado quiero crear una definición propia para guardar un concepto nuevo en mi diccionario personal.
Criterios de Aceptación:
* Dado un usuario no autenticado, el botón "Agregar término personal" se muestra deshabilitado en la pantalla de Inicio/Búsqueda.
* Dado un usuario autenticado, al visualizar la pantalla de Inicio/Búsqueda se habilita el botón "Agregar término personal".
* Al hacer clic en "Agregar término personal" se abre el formulario de creación.
* Al visualizar el formulario, se muestra el campo obligatorio "Nombre del término" con un límite máximo de 100 caracteres.
* Al ingresar texto en "Nombre del término", se muestra un contador de caracteres que se actualiza en tiempo real.
* Al visualizar el formulario, se muestra el campo obligatorio "Definición" con un límite máximo de 500 caracteres.
* Al visualizar el formulario, se muestra el campo opcional "Categoría" con formato desplegable.
* Al ejecutar la acción de guardar con los campos obligatorios completos, el sistema asocia el término al identificador del usuario actual en la base de datos (Supabase).
Tareas:
* Task 1: Crear la tabla terminos_personales en Supabase con los campos definidos (id, user_id, nombre, definición, categoría, timestamps).
* Task 2: Configurar la política RLS (Row Level Security) en Supabase para permitir la inserción (INSERT) únicamente a usuarios autenticados.
* Task 3: Desarrollar la interfaz del formulario de creación, incluyendo validaciones de texto y el contador de caracteres reactivo.
* Task 4: Implementar la lógica del cliente para enviar los datos del formulario a Supabase, asegurando la vinculación automática con el user_id de la sesión actual.
HU-16: Consultar Diccionario Personal
Descripción: Como usuario autenticado quiero acceder a la sección "Mi Diccionario" para visualizar todos los términos personales que he creado.
Criterios de Aceptación:
* Dado un usuario autenticado, al ingresar a la pantalla de Inicio/Búsqueda se visualiza la sección "Mi Diccionario".
* En la sección "Mi Diccionario" se listan los términos creados exclusivamente por el usuario actual.
* Las tarjetas de los términos en "Mi Diccionario" muestran un diseño visual distinto al de los términos globales.
* Dado un inicio de sesión en un dispositivo nuevo con la misma cuenta, el sistema sincroniza automáticamente los términos personales previamente creados.
* Dado un usuario que cierra su sesión, la sección "Mi Diccionario" y sus términos se ocultan inmediatamente de la interfaz del dispositivo.
Tareas:
* Task 1: Configurar la política RLS en Supabase para la lectura (SELECT), restringiendo que cada usuario solo pueda consultar sus propios registros (auth.uid() = user_id).
* Task 2: Desarrollar el componente visual de la sección "Mi Diccionario" y el diseño de la tarjeta (card) diferenciada.
* Task 3: Implementar la consulta (query) a Supabase para recuperar el listado y poblar la interfaz.
* Task 4: Configurar el manejador de estado de autenticación para limpiar de la memoria local y ocultar la sección de términos si el usuario ejecuta un cierre de sesión (logout).
HU-17: Ver detalle de un término personal
Descripción: Como usuario autenticado quiero acceder a la vista de detalle de un término personal para leer su información completa.
Criterios de Aceptación:
* Al hacer clic sobre un término en la sección "Mi Diccionario", el sistema navega a la vista de detalle de dicho término.
* Al cargar la vista de detalle, se muestra el nombre del término.
* Al cargar la vista de detalle, se muestra el texto completo de la definición.
* Al cargar la vista de detalle, se muestra la categoría asociada.
* Al cargar la vista de detalle, se visualiza un ícono específico indicando que es un término personal.
Tareas:
* Task 1: Diseñar e implementar la pantalla de detalle específica para los términos personales.
* Task 2: Configurar la navegación (routing) para que al tocar la tarjeta en el listado se pasen los parámetros o el ID hacia la pantalla de detalle.
* Task 3: Integrar el ícono o distintivo visual ("badge") que marca el término como personal.
HU-18: Editar un término personal
Descripción: Como usuario autenticado quiero modificar un término de mi diccionario personal para actualizar su nombre, definición o categoría.
Criterios de Aceptación:
* Dado un término personal, al visualizar su vista de detalle se muestra el botón "Editar".
* Dado un término global, al visualizar su vista de detalle se oculta el botón "Editar".
* Al hacer clic en el botón "Editar", se abre el formulario de edición con los datos actuales del término precargados.
* Al ejecutar la acción de guardar en el formulario de edición, el sistema actualiza la información del término en la base de datos.
* Al actualizarse la información, los cambios se sincronizan para reflejarse en los demás dispositivos autenticados.
Tareas:
* Task 1: Configurar la política RLS en Supabase para la modificación (UPDATE), asegurando que el user_id coincida.
* Task 2: Adaptar/reutilizar el componente del formulario de creación para que funcione en modo "Edición" e inyectar los datos existentes en los campos.
* Task 3: Implementar la petición de actualización a Supabase al guardar los cambios.
* Task 4: Configurar las suscripciones en tiempo real (real-time listeners) de Supabase en la aplicación para detectar y actualizar la vista si el registro es modificado desde otro dispositivo.
HU-19: Eliminar un término personal
Descripción: Como usuario autenticado quiero eliminar un término de mi diccionario personal para retirar conceptos que ya no necesito.
Criterios de Aceptación:
* Al hacer clic en el botón "Eliminar" desde la vista de detalle de un término personal, se visualiza una ventana emergente de confirmación.
* Al hacer clic en "Cancelar" dentro de la ventana de confirmación, la ventana se cierra.
* Al hacer clic en "Cancelar" dentro de la ventana de confirmación, el término se mantiene intacto en la base de datos.
* Al hacer clic en "Confirmar" dentro de la ventana de confirmación, el término se elimina permanentemente de la base de datos.
* Al confirmarse la eliminación, el sistema cierra la vista de detalle y retorna automáticamente a la pantalla anterior.
Tareas:
* Task 1: Configurar la política RLS en Supabase para el borrado (DELETE) sobre registros propios.
* Task 2: Implementar el componente visual de la ventana de confirmación (Modal/Dialog).
* Task 3: Desarrollar la lógica que envía la petición de borrado a Supabase.
* Task 4: Configurar el enrutamiento para que, tras un borrado exitoso, la aplicación expulse al usuario de la vista de detalle y refresque el listado principal.


HU20 — Gestionar sugerencias de términos
ID: HU16
Título: Gestionar sugerencias de términos
Descripción: Como administrador de la aplicación, quiero acceder a un panel donde pueda ver todas las sugerencias de términos enviadas por los usuarios, revisarlas y decidir si agregarlas al glosario o rechazarlas, para mantener la calidad del contenido y gestionar el crecimiento colaborativo de la base de datos.
Criterios de Aceptación:
* El panel de admin es accesible únicamente para usuarios con rol de administrador en Supabase Auth.
* El panel muestra una lista de todas las sugerencias pendientes (no procesadas) ordenadas por fecha descendente.
* Cada sugerencia muestra: nombre del término, descripción, dispositivo/usuario que la sugirió, fecha de creación y estado actual.
* El botón "Aprobar" agrega el término sugerido a la tabla terminos con categoría "Sugerido" o categoría seleccionada por el admin.
* El botón "Rechazar" marca la sugerencia como rechazada sin agregarla al glosario.
* Las sugerencias procesadas (aprobadas o rechazadas) se trasladan a una sección de historial y no aparecen en pendientes.
* Un filtro permite ver: Todas, Pendientes, Aprobadas, Rechazadas.
* Existe un campo de búsqueda para filtrar sugerencias por término.
* Al aprobar una sugerencia se registra quién la aprobó y cuándo en un campo aprobado_por y aprobado_en.
* Se muestra un contador visual del total de sugerencias pendientes.
Tareas:
* Task 1: Crear pantalla de Panel de Admin con autenticación por rol en Supabase, tabla con lista de todas las sugerencias pendientes ordenadas por fecha descendente y botones de acciones (Aprobar/Rechazar) en cada sugerencia.
* Task 2: Implementar lógica de aprobación que inserte la sugerencia aprobada en tabla terminos con todos los campos necesarios (nombre, definición, categoría, vistas=0, imagen_url=null) y actualice estado en tabla sugerencias a "aprobada".
* Task 3: Implementar filtros (Todas, Pendientes, Aprobadas, Rechazadas), buscador de términos, historial de sugerencias procesadas y contador visual de pendientes en la cabecera del panel.
* Task 4: Agregar campos estado y aprobado_por a tabla sugerencias en Supabase, implementar lógica de rechazo que marque sugerencias como "rechazada" sin eliminarlas y verificar permisos de admin mediante RLS policies.