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

## Menús Interactivos.

El script utiliza una estructura de menú interactiva para facilitar la navegación y selección de opciones por parte del usuario. Los menús están organizados jerárquicamente y abarcan las diferentes operaciones que se pueden llevar a cabo.

## Operaciones de Copias de Seguridad.

Las operaciones principales relacionadas con las copias de seguridad incluyen la creación, eliminación y visualización de copias. El script ofrece opciones para seleccionar usuarios, grupos y fechas específicas para realizar dichas operaciones.

## Configuración Automática.

Se incluye una sección dedicada a la configuración automática de copias de seguridad. El script permite visualizar, crear, modificar y borrar configuraciones automáticas para usuarios y grupos.

# Detalles Técnicos.

## Manipulación de Archivos y Directorios.

El script interactúa con el sistema de archivos para crear, eliminar y manipular directorios y archivos de copias de seguridad. Se utiliza el comando `tar` para la creación de las copias. Todas las acciones relacionadas con las copias de seguridad quedan registradas en el archivo `.backup.log`.  
La manipulación de las copias de seguridad está definida en sus funciones correspondientes. De este modo durante la ejecución del script solo hay que controlar que las variables que se manejen sean las mismas que en las funciones.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/bcc13b3c-642d-4b5a-a33f-7b388c6ff6d3)

![image](https://github.com/abelgc84/backup.sh/assets/146434908/ada948ae-5294-40da-8c7a-35bb4cb2e8be)

![image](https://github.com/abelgc84/backup.sh/assets/146434908/759e317b-1f5e-4251-abb7-acf83dd04ac8)

Estas funciones hacen una llamada a la función de generar_log, la cual genera un log en función del parámetro que se le haya pasado.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/0ead1989-4996-4d35-9e82-a14a6288663c)

## Interacción con el Usuario.

El script emplea varias funciones para interactuar con el usuario, todas ellas basadas en el comando `zenity`. Estas funciones facilitan la presentación de información y la selección de opciones.  
Las funciones con zenity funcionan en relación a los parámetros que se pasen. Siendo los primeros parámetros los títulos de las ventanas, columnas u otras opciones de la ventana zenity. Y la cadena de parámetros restantes serán los datos que se presenten en la ventana. Por ejemplo la función zenity, y su llamada, para la ventana de menú estándar del script sería así.
```
mostrar_menu () {
    titulo="$1"
    shift
    columna1="$1"
    shift
    columna2="$1"
    shift
    zenity --title "$titulo" \
           --width="500" \
           --height="500" \
           --list \
           --column "$columna1" \
           --column "$columna2" \
           "$@"
}

MENU=$(mostrar_menu "Backup.sh" "Opción" "Menú" \
    1 "Crear copia de seguridad." \
    2 "Restaurar copia de seguridad." \
    3 "Borrar copia de seguridad." \
    4 "Visualizar copias de seguridad." \
    5 "Configurar ejecución automática." \
    6 "Salir.")
```

Hay muchas más funciones para la creación de ventanas con zenity. Todas tienen un funcionamiento similar, se recomienda revisar la sección inicial del script donde se declaran las funciones para profundizar en ellas.

## Gestión de Configuraciones.

La gestión de configuraciones automáticas se realiza a través de un archivo de configuración `.backup.conf`. Este archivo es utilizado para la ejecución automática de copias de seguridad y almacena información sobre usuarios, grupos, número de copias y días entre copias.  
El archivo de configuración se crea al entrar por primera vez en el menú de configuración. Así mismo se crea un enlace simbólico del script y es añadido al archivo .profile, siendo la ejecución del script a través del nombre del enlace lo que desencadenará la ejecución automática.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/dc56bdaf-4602-4109-a3b3-16ae318cb0cd)

Las funciones para crear, o modificar, configuraciones simplemente recogen los datos necesarios a través de formularios zenity y los almacena en el archivo. Teniendo en cuenta que se hayan introducido datos, dando un mensaje de error en caso de haberse saltado alguno de los datos necesarios.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/c1814084-d229-45fe-aed0-ad4e1d75bc21)

# Ejecución Automática.

El script incluye una lógica para gestionar de manera automática las copias de seguridad. Esta lógica incluye la ejecución del script con el nombre `autobackup.sh` de manera automática a través del archivo `.profile`.

# Conclusiones.

El script proporciona una solución integral para el administrador de sistemas en entornos Linux, con una interfaz interactiva que facilita la gestión de copias de seguridad de los usuarios del sistema. El uso adecuado de este script puede mejorar la eficiencia y la confiabilidad de las operaciones de copia de seguridad.

# Recomendaciones.

* Revisar y entender el script completamente antes de su uso.
* Revisar las configuraciones predeterminadas para adaptarlas a las necesidades específicas de cada sistema.
* Modificar el archivo `sudoers` para excluir al script y/o al usuario de las peticiones de contraseña añadiendo:
```
usuario    ALL=(ALL) NOPASSWD: /ruta/al/script/backup.sh
usuario    ALL=(ALL) NOPASSWD: /ruta/al/script/autobackup.sh
usuario    ALL=(ALL) NOPASSWD:usuario
```
La utilización de la ejecución automática sin estas modificaciones puede provocar problemas de inicio de sesión.

> Este documento proporciona una visión general del script y sus características clave. Se recomienda revisar el código fuente directamente para obtener detalles más específicos.
