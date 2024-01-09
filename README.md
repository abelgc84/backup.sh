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

![image](https://github.com/abelgc84/backup.sh/assets/146434908/1de33dfc-ad17-4cc6-b4ad-fa8465136581)

![image](https://github.com/abelgc84/backup.sh/assets/146434908/24a8b047-6053-4697-9f27-f427b1de559b)

![image](https://github.com/abelgc84/backup.sh/assets/146434908/89e7b2c4-8c7a-4353-a9da-a99b6efea51a)

Estas funciones hacen una llamada a la función de generar_log, la cual genera un log en función del parámetro que se le haya pasado.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/6486d4ae-2853-444b-953e-fa065f786f93)

## Interacción con el Usuario.

El script emplea varias funciones para interactuar con el usuario, todas ellas basadas en el comando `zenity`. Estas funciones facilitan la presentación de información y la selección de opciones.  
Las funciones con zenity funcionan en relación a los parámetros que se pasen. Siendo los primeros parámetros los títulos de las ventanas, columnas u otras opciones de la ventana zenity. Y la cadena de parámetros restantes serán los datos que se presenten en la ventana. Por ejemplo la función zenity, y su llamada, para la ventana de menú estándar del script sería así.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/aed99975-a9d6-4a9f-abb8-10529b5561fa)

![image](https://github.com/abelgc84/backup.sh/assets/146434908/d830d19e-55ad-4281-8ca7-bb7ec6155634)

Hay muchas más funciones para la creación de ventanas con zenity. Todas tienen un funcionamiento similar, se recomienda revisar la sección inicial del script donde se declaran las funciones para profundizar en ellas.

## Gestión de Configuraciones.

La gestión de configuraciones automáticas se realiza a través de un archivo de configuración `.backup.conf`. Este archivo es utilizado para la ejecución automática de copias de seguridad y almacena información sobre usuarios, grupos, número de copias y días entre copias.  
El archivo de configuración se crea al entrar por primera vez en el menú de configuración. Así mismo se crea un enlace simbólico del script y es añadido al archivo .profile, siendo la ejecución del script a través del nombre del enlace lo que desencadenará la ejecución automática.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/6c70a532-3f5d-4eca-8667-419200b876ab)

Las funciones para crear, o modificar, configuraciones simplemente recogen los datos necesarios a través de formularios zenity y los almacena en el archivo. Teniendo en cuenta que se hayan introducido datos, dando un mensaje de error en caso de haberse saltado alguno de los datos necesarios.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/63356e36-5239-4169-936c-397441e8b39b)

# Ejecución Automática.

El script incluye una lógica para gestionar de manera automática las copias de seguridad. Esta lógica incluye la ejecución del script con el nombre `autobackup.sh` de manera automática a través del archivo `.profile`.  
Se recorre el archivo de configuración y se realizan básicamente dos operaciones, calcular la diferencia de días entre la última copia y la fecha actual y contar cuantas copias almacenadas hay. Si los resultados concuerdan con las configuraciones se realizarán las operaciones pertinentes en cada caso.

![image](https://github.com/abelgc84/backup.sh/assets/146434908/bf857e1c-e37b-4870-b2ce-ff7cd251f65c)


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
