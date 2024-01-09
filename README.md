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
```
crear_copia () {
    mkdir -p $BACKUP/$usuario/copia_${usuario}_${FECHA}
    DESTINO=$BACKUP/$usuario/copia_${usuario}_${FECHA}/copia_${usuario}_${FECHA}.tar.gz
    ORIGEN=/home/$usuario
    sudo tar -czf "$DESTINO" "$ORIGEN"|zenity --title "Creando copia de seguridad." \
        --width="400" \
        --text="Copia para $usuario" \
        --progress \
        --pulsate \
        --auto-close \
        --no-cancel
    generar_log copiar
}

restaurar_copia () {
    ORIGEN=$BACKUP/$REST_USU/$REST_COP/$REST_COP.tar.gz
    sudo tar -xf $ORIGEN -C $REST_RUT|zenity --title "Restaurando copia de seguridad." \
        --width="400" \
        --text="Restaurando $REST_COP" \
        --progress \
        --pulsate \
        --auto-close \
        --no-cancel
    generar_log restaurar
}

borrar_copia () { 
    sudo rm -r $BACKUP/$usuario/$BORR_COP
    generar_log borrar
    CANT_COP=`ls $BACKUP/$usuario|wc -l`
    if [ $CANT_COP -eq 0 ]; then
        sudo rm -r $BACKUP/$usuario
    fi
}
```

Estas funciones hacen una llamada a la función de generar_log, la cual genera un log en función del parámetro que se le haya pasado.
```
generar_log () {
    # Estructura del archivo log: acción:usuario:fecha:ruta_copia
    case $1 in
    copiar)
        echo $1":"$usuario":"$FECHA":"$DESTINO>>$BACKUP/.backup.log
    ;;
    restaurar)
        echo $1":"$REST_USU":"$FECHA":"$ORIGEN>>$BACKUP/.backup.log
    ;;
    borrar)
        echo $1":"$USER":"$FECHA":"$BORR_COP".tar.gz">>$BACKUP/.backup.log
    ;;
    esac
}
```

## Interacción con el Usuario.

El script emplea varias funciones para interactuar con el usuario, todas ellas basadas en el comando `zenity`. Estas funciones facilitan la presentación de información y la selección de opciones.  
Las funciones con zenity funcionan en función de los parámetros que se pasen. Siendo los primeros parámetros los títulos de las ventanas, columnas u otras opciones de la ventana zenity. Y la cadena de parámetros restantes serán los datos que se presenten en la ventana. Por ejemplo la función zenity, y su llamada, para la ventana de menú estándar del script sería así.
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
