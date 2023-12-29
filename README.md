# backup.sh
 > script de gestión de copias de seguridad

 1. [Introducción.](#introducción)
 2. [Estructura del Script.](#estructura-del-script)
    * [Menús Interactivos.](#menús-interactivos)
    * [Operaciones de Copias de Seguridad.](#operaciones-de-copias-de-seguridad)
    * [Configuración Automática.](#configuración-automática)
3. [Detalles Técnicos.](#detalles-técnicos)
    * [Manipulación de Archivos y Directorios.](#manipulación-de-archivos-y-directorios)
    * [Interacción con el Usuario.](#interacción-con-el-usuario)
    * [Gestión de Configuraciones.](#gestión-de-configuraciones)
    * [Ejecución Automática.](#ejecución-automática)
4. [Ejecución Automática.](#ejecución-automática)
5. [Conclusiones.](#conclusiones)
6. [Recomendaciones.](#recomendaciones)

# Introducción.

El siguiente documento técnico describe un script Bash diseñado para la gestión de copias de seguridad en sistemas Linux. El script proporciona una interfaz gráfica interactiva que permite al usuario realizar diversas operaciones relacionadas con copias de seguridad, incluyendo la creación, eliminación y visualización de copias de seguridad para usuarios y grupos. Además, se incluye la capacidad de configurar la ejecución automática de copias de seguridad.

# Estructura del Script.

El script está organizado en varias secciones. Las secciones más relevantes son:

## Menús Interactivos.

El script utiliza una estructura de menú interactiva para facilitar la navegación y selección de opciones por parte del usuario. Los menús están organizados jerárquicamente y abarcan las diferentes operaciones que se pueden llevar a cabo.

## Operaciones de Copias de Seguridad.

Las operaciones principales relacionadas con las copias de seguridad incluyen la creación, eliminación y visualización de copias. El script ofrece opciones para seleccionar usuarios, grupos y fechas específicas para realizar dichas operaciones.

## Configuración Automática.

Se incluye una sección dedicada a la configuración automática de copias de seguridad. El script permite visualizar, crear, modificar y borrar configuraciones automáticas para usuarios y grupos.

# Detalles Técnicos.

## Manipulación de Archivos y Directorios.

El script interactúa con el sistema de archivos para crear, eliminar y manipular directorios y archivos de copias de seguridad. Se utiliza el comando `tar` para la creación de las copias. Todas las acciones relacionadas con las copias de seguridad quedan registradas en el archivo `.backup.log`.

## Interacción con el Usuario.

El script emplea varias funciones para interactuar con el usuario, todas ellas basadas en el comando `zenity`. Estas funciones facilitan la presentación de información y la selección de opciones.

## Gestión de Configuraciones.

La gestión de configuraciones automáticas se realiza a través de un archivo de configuración `.backup.conf`. Este archivo es utilizado para la ejecución automática de copias de seguridad y almacena información sobre usuarios, grupos, número de copias y días entre copias.

# Ejecución Automática.

El script incluye una lógica para gestionar de manera automática las copias de seguridad. Esta lógica incluye la ejecución del script con el nombre `autobackup.sh` de manera automática a través del archivo `.profile`.

# Conclusiones.

El script proporciona una solución integral para el administrador de sistemas en entornos Linux, con una interfaz interactiva que facilita la gestión de copias de seguridad de los usuarios del sistema. El uso adecuado de este script puede mejorar la eficiencia y la confiabilidad de las operaciones de copia de seguridad.

# Recomendaciones.

* Revisar y entender el script completamente antes de su uso.
* Modificar configuraciones predeterminadas para adaptarlas a las necesidades específicas de cada sistema.
* Modificar el archivo `sudoers` para excluir al script de las peticiones de contraseña añadiendo:
```
usuario    ALL=(ALL) NOPASSWD: /ruta/al/script/backup.sh
usuario    ALL=(ALL) NOPASSWD: /ruta/al/script/autobackup.sh
```

> Este documento proporciona una visión general del script y sus características clave. Se recomienda revisar el código fuente directamente para obtener detalles más específicos.
