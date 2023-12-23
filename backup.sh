#! /bin/bash

# Creación del archivo de configuración.
# Estructura del archivo: usuario:grupo:número_copias_guardadas:días_entre_copias
if [ ! -d $HOME/backup ]; then
    mkdir $HOME/backup
    touch $HOME/backup/.backup.conf
else
    if [ ! -f $HOME/backup/.backup.conf ]; then
        touch $HOME/backup/.backup.conf
    fi
fi

# Ruta donde estarán las copias de seguridad.
BACKUP=$HOME/backup

# Usuarios y grupos del sistema
USUARIOS=" "
while IFS=: read etc_nom etc_pas etc_uid etc_gui etc_gru etc_hom
do
    if [ $etc_uid -ge 1000 -a $etc_uid -lt 65000 ]; then
        USUARIOS=$USUARIOS" "$etc_nom
    fi
done</etc/passwd
GRUPOS=" "
while IFS=: read etc_nom etc_pass etc_gid etc_usu
do
    if [ $etc_gid -ge 1000 -a $etc_gid -lt 65000 ]; then
        GRUPOS=$GRUPOS" "$etc_nom
    fi
done</etc/group

# Fecha actual, formato dd-mm-yy
FECHA=`date +%d-%m-%y`

# Salida del menú principal.
SALIDA=0

# Funciones.

# Menú estándar de dos columnas.
mostrar_menu () {
    titulo="$1"
    shift
    zenity --title "$titulo" \
           --width="500" \
           --height="500" \
           --list \
           --column "Opción" \
           --column "Menú" \
           "$@"
}
# Menú estándar de selección.
menu_selec () {
    titulo="$1"
    shift
    columna="$1"
    shift
    zenity --title "$titulo" \
        --width="500" \
        --height="500" \
        --list \
        --column "$columna" \
        "$@"
}
# Menú estándar de selección múltiple.
menu_selec_multi () {
    titulo="$1"
    shift
    columna="$1"
    shift
    zenity --title "$titulo" \
        --width="500" \
        --height="500" \
        --multiple \
        --list \
        --separator=" " \
        --column "$columna" \
        "$@"
}
zen_forms () {
    zenity --title "$1" \
        --width="500" \
        --forms \
        --text="$2" \
        --add-entry="$3"
}
zen_calendar () {
    zenity --title "$1" \
        --width="500" \
        --height="400" \
        --calendar
}
zen_error () {
    zenity --error --text="$error" --width="400"
}
zen_question () {
    zenity --question --text="$question" --width="400"
}
zen_info () {
    zenity --info --text="$info" --width="400"
}
zen_notification () {
    zenity --notification --text="$notification"
}
generar_log () {
    # Archivo log, estructura: acción:usuario:fecha:copia
    case $1 in
    copiar)
        echo $1":"$usuario":"$FECHA":"$DESTINO>>$BACKUP/.backup.log
    ;;
    restaurar)
        echo $1":"$REST_USU":"$FECHA":"$ORIGEN>>$BACKUP/.backup.log
    ;;
    borrar)
    ;;
    esac
}
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
sobreescribir () {
    zenity --title "La copia con fecha $FECHA para $usuario ya existe" \
        --width="500" \
        --question \
        --text "¿Desea sobreescribirla?"
}
directorio () {
    if [ ! -d $BACKUP/$usuario ]; then
        mkdir $BACKUP/$usuario
    fi
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
devolver_propiedad () {
    # Devuelvo la propiedad de los archivos descomprimidos al usuario o grupo.
    case $1 in
    usuario)
        sudo chown -R $REST_USU:$REST_USU $REST_RUT
    ;;
    grupo)
        sudo chown -R $REST_USU:$REST_GRU $REST_RUT
    ;;
    esac
}


# Ejecución manual del script.
if [ $0 = "$HOME/bin/backup.sh" ]; then

    while [ $SALIDA -eq 0 ] 
    do
        # Menú principal.
        MENU=$(mostrar_menu "Backup.sh" \
            1 "Crear copia de seguridad." \
            2 "Restaurar copia de seguridad." \
            3 "Borrar copia de seguridad." \
            4 "Visualizar copias de seguridad." \
            5 "Congigurar ejecución automática." \
            6 "Salir.")

        # Chequear el botón cancelar y X para salir.
        if [ $? -eq 1 ]; then
            exit
        fi 

        # Submenus.
        case $MENU in
        1)
            # Submenu1 para crear copias.
            SUBMENU1=$(mostrar_menu "Crear copia de seguridad." \
                1 "Seleccionar un usuario o varios." \
                2 "Seleccionar un grupo de usuarios o varios.")

            case $SUBMENU1 in
            1)
                # Seleccionar un usuario o varios.
                SELECCION=$(menu_selec_multi "Lista de usuarios." \
                    "Usuarios del sistema." \
                    `echo $USUARIOS`)

                # Recorro los usuarios seleccionados para hacer sus copias.
                for usuario in $SELECCION
                do
                    # Comprobar que cada usuario tenga su directorio de copias.
                    directorio
                    # Comprobar que la copia no existe.
                    if [ ! -d $BACKUP/$usuario/copia_${usuario}_${FECHA} ]; then
                        crear_copia
                        notification="Copia de seguridad para $usuario finalizada."
                        zen_notification
                    else
                        sobreescribir
                        if [ $? -eq 0 ]; then
                            crear_copia
                            notification="Copia de seguridad para $usuario finalizada."
                            zen_notification
                        fi
                    fi
                done
            ;;
            2)
                # Seleccionar un grupo de usuarios o varios.
                SELECCION=$(menu_selec_multi "Lista de grupos." \
                    "Grupos del sistema." \
                    `echo $GRUPOS`)

                # Recorro los grupos seleccionados.
                for grupo in $SELECCION
                do
                    # Saco la lista de usuarios perteneciente a cada grupo y los recorro para hacer sus copias.
                    while IFS=: read etc_nom etc_pass etc_gid etc_usu
                    do
                        if [ "$grupo" = "$etc_nom" ]; then
                            # Si el grupo no tiene usuarios, el usuario tendrá el nombre del grupo.
                            if [ "$etc_usu" = "" ]; then
                                SEL_USU=$etc_nom
                            else
                                SEL_USU=$(echo $etc_usu|tr "," " ")
                            fi
                            for usuario in $SEL_USU
                            do
                                # Compruebo que el usuario tenga su directorio de copias.
                                directorio
                                # Compruebo si la copia existe.
                                if [ ! -d $BACKUP/$usuario/copia_${usuario}_${FECHA} ]; then
                                    crear_copia
                                    notification="Copia de seguridad para $usuario finalizada."
                                    zen_notification
                                else
                                    sobreescribir
                                    if [ $? -eq 0 ]; then
                                        crear_copia
                                        notification="Copia de seguridad para $usuario finalizada."
                                        zen_notification
                                    fi
                                fi
                            done
                        fi
                    done</etc/group
                done
            ;;
            esac
        ;;
        2)
            # Submenu2 para restaurar copias.
            SUBMENU2=$(mostrar_menu "Restaurar copia de seguridad." \
                1 "Restaurar copia de un usuario." \
                2 "Restaurar copia de un grupo." \
                3 "Restaurar copia de una fecha.")

            case $SUBMENU2 in 
            1)
                # Restaurar copia de un usuario.
                REST_USU=$(menu_selec "Restaurar copia de seguridad de un usuario." \
                    "Nombre de usuario." \
                    `for usuario in $BACKUP/*
                    do
                        echo $usuario|cut -d"/" -f5
                    done`)
# Comprobar el boton de aceptar
# Comprobar cadenas vacias
                REST_COP=$(menu_selec "Restaurar copia de seguridad de $REST_USU." \
                    "Copias almacenadas." \
                    `for archivo in $BACKUP/$REST_USU/*
                    do
                        echo $archivo|cut -d"/" -f6
                    done`)
# Comprobar el botón de aceptar
# Comprobar cadenas vacias
                # Bucle para pedir la ruta.
                SALIDA_RUT=0
                while [ $SALIDA_RUT -eq 0 ]
                do
                    
                    REST_RUT=$(zen_forms "Restaurar copia de seguridad de $REST_USU." \
                        "Introduce la ruta absoluta." \
                        "Ruta")
                    
                    # Chequear el botón cancelar y X 
                    if [ $? -eq 1 ]; then
                        break
                    fi 

                    # Verifico que la ruta de destino sea absoluta.
                    if [ `echo $REST_RUT|cut -c1` != "/" ]; then
                        error="La ruta introducida no es absoluta."
                        zen_error
                    else
                        # Compruebo que el directorio de destino exista.
                        if [ ! -d $REST_RUT ]; then
                            question="La ruta elegida no existe. ¿Desea crearla?"
                            zen_question
                            if [ $? -eq 0 ]; then
                                sudo mkdir -p $REST_RUT
                                if [ $? -eq 0 ]; then
                                    restaurar_copia
                                    devolver_propiedad usuario
                                    notification="Copia de seguridad de $REST_USU restaurada."
                                    zen_notification
                                fi
                                SALIDA_RUT=1
                            else
                                question="¿Quiere introducir otra ruta?"
                                zen_question
                                if [ $? -eq 1 ]; then
                                    SALIDA_RUT=1
                                fi
                            fi
                        else
                            restaurar_copia
                            devolver_propiedad usuario
                            notification="Copia de seguridad de $REST_USU restaurada."
                            zen_notification
                            SALIDA_RUT=1
                        fi
                    fi
                done
            ;;
            2)
                # Restaurar copia de un grupo.
                REST_GRU=$(menu_selec "Restaurar copia de seguridad de un grupo." \
                    "Grupo" \
                    `echo $GRUPOS`)

                # Saco la lista de usuarios perteneciente al grupo.
                while IFS=: read etc_nom etc_pass etc_gid etc_usu
                do
                    if [ "$REST_GRU" = "$etc_nom" ]; then
                        if [ "$etc_usu" = "" ]; then
                            USU_GRU=$etc_nom
                        else
                            USU_GRU=$(echo $etc_usu|tr "," " ")
                        fi

                        # Recorro los usuarios para restaurar sus copias.
                        for REST_USU in $USU_GRU
                        do
                            # Pido la copia que se quiere restarurar.
                            info=`echo "Restaurando copia para" $REST_USU". Seleccione la copia."`
                            zen_info
                            REST_COP=$(menu_selec "Restaurar copia de seguridad de $REST_USU." \
                                "Copias almacenadas." \
                                `for archivo in $BACKUP/$REST_USU/*
                                do 
                                    echo $archivo|cut -d"/" -f6
                                done`)
# Comprobar botones de aceptar
# Comprobar cadenas vacias 
                            # Bucle para pedir la ruta.
                            SALIDA_RUT=0
                            while [ $SALIDA_RUT -eq 0 ]
                            do
                    
                                REST_RUT=$(zen_forms "Restaurar copia de seguridad de $REST_USU." \
                                    "Introduce la ruta absoluta." \
                                    "Ruta")
                    
                                if [ $? -eq 1 ]; then
                                    break
                                fi 

                                # Verifico que la ruta de destino sea absoluta.
                                if [ `echo $REST_RUT|cut -c1` != "/" ]; then
                                    error="La ruta introducida no es absoluta."
                                    zen_error
                                else
                                    # Compruebo que el directorio de destino exista.
                                    if [ ! -d $REST_RUT ]; then
                                        question="La ruta elegida no existe. ¿Desea crearla?"
                                        zen_question
                                        if [ $? -eq 0 ]; then
                                            sudo mkdir -p $REST_RUT
                                            if [ $? -eq 0 ]; then
                                                restaurar_copia
                                                devolver_propiedad grupo
                                                notification="Copia de seguridad de $REST_USU restaurada."
                                                zen_notification
                                            fi
                                            SALIDA_RUT=1
                                        else
                                            question="¿Quiere introducir otra ruta?"
                                            zen_question
                                            if [ $? -eq 1 ]; then
                                                SALIDA_RUT=1
                                            fi
                                        fi
                                    else
                                        restaurar_copia
                                        devolver_propiedad grupo
                                        notification="Copia de seguridad de $REST_USU restaurada."
                                        zen_notification
                                        SALIDA_RUT=1
                                    fi
                                fi
                            done                              
                        done
                    fi
                done</etc/group 
            ;;
            3)
                # Restaurar copia de una fecha.
                # Pido la fecha y le doy mi formato.
                REST_FEC=$(zen_calendar "Restaurar copia de seguridad.")
                REST_FEC=`echo $REST_FEC|tr "/" "-"`
# Comprobar botón de aceptar
# Comprobar cadenas vacias 
                # Recorro las carpetas de almacenamiento de cada usuario.
                for usuario in $BACKUP/*
                do
                    # Busco para cada usuario una copia con la fecha seleccionada.
                    for copia in $usuario/*
                    do
                        # Almaceno las copias encontradas.
                        lista="$lista `echo $copia|grep $REST_FEC|cut -d"/" -f6`"
                    done
                done

                # Muestro las copias para elegir cuáles se quieren restaurar
                SELECCION=$(menu_selec_multi "Restaurar copia de seguridad." \
                    "Copia." \
                    `echo $lista`)

                # Restauro las copias seleccionadas.
                for REST_COP in $SELECCION
                do
                    REST_USU=`echo $REST_COP|cut -d"_" -f2`
                    
                    # Bucle para pedir la ruta.
                    SALIDA_RUT=0
                    while [ $SALIDA_RUT -eq 0 ]
                    do
                    
                        REST_RUT=$(zen_forms "Restaurar copia de seguridad de $REST_USU." \
                            "Introduce la ruta absoluta." \
                            "Ruta")
                    
                        # Chequear el botón cancelar y X 
                        if [ $? -eq 1 ]; then
                            break
                        fi 

                        # Verifico que la ruta de destino sea absoluta.
                        if [ `echo $REST_RUT|cut -c1` != "/" ]; then
                            error="La ruta introducida no es absoluta."
                            zen_error
                        else
                            # Compruebo que el directorio de destino exista.
                            if [ ! -d $REST_RUT ]; then
                                question="La ruta elegida no existe. ¿Desea crearla?"
                                zen_question
                                if [ $? -eq 0 ]; then
                                    sudo mkdir -p $REST_RUT
                                    if [ $? -eq 0 ]; then
                                        restaurar_copia
                                        devolver_propiedad usuario
                                        notification="Copia de seguridad de $REST_USU restaurada."
                                        zen_notification
                                    fi
                                    SALIDA_RUT=1
                                else
                                    question="¿Quiere introducir otra ruta?"
                                    zen_question
                                    if [ $? -eq 1 ]; then
                                        SALIDA_RUT=1
                                    fi
                                fi
                            else
                                restaurar_copia
                                devolver_propiedad usuario
                                notification="Copia de seguridad de $REST_USU restaurada."
                                zen_notification
                                SALIDA_RUT=1
                            fi
                        fi
                    done
                done
            ;;
            esac
        ;;
        3)
            # Submenu3 para borrar copias de seguridad
            SUBMENU3=$(mostrar_menu "Borrar copia de seguridad." \
                1 "Borrar copia de seguridad de uno o varios usuarios." \
                2 "Borrar copia de seguridad de un grupo." \
                3 "Borrar copia de segudidad de una fecha.")
            
            case $SUBMENU3 in
            1)
                # Muestro los usuarios con copias.
                SELECCION=$(menu_selec_multi "Usuarios con copias almacenadas." \
                    "Usuarios." \
                    `for usuario in $BACKUP/*
                    do
                        echo $usuario|cut -d"/" -f5
                    done`)
                echo $SELECCION
            ;;
            2)
                echo "borrar de grupo"
            ;;
            3)
                echo "borrar de fecha"
            ;;
            esac
        ;;
        4)
            echo "Visualizar copias"
        ;;
        5)
            echo "Configuración automática"
        ;;
        6)
            echo "Salir"
            SALIDA=1
        ;;
        esac

    done

fi

# Ejecución automática del script.
if [ $0 = "$HOME/bin/autobackup.sh" ]; then

    echo "Estoy dentro de .profile."

fi

if [ -f temporal ]; then
    rm temporal
fi