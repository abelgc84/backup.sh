#! /bin/bash

# Creación de la carpeta de almacenamiento.
if [ ! -d $HOME/backup ]; then
    mkdir $HOME/backup
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

# Menú estándar de dos columnas.
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
# Menú estándar de selección.
menu_selec () {
    titulo="$1"
    shift
    columna1="$1"
    shift
    zenity --title "$titulo" \
        --width="500" \
        --height="500" \
        --list \
        --column "$columna1" \
        "$@"
}
# Menú estándar de selección múltiple.
menu_selec_multi () {
    titulo="$1"
    shift
    columna1="$1"
    shift
    zenity --title "$titulo" \
        --width="500" \
        --height="500" \
        --multiple \
        --list \
        --separator=" " \
        --column "$columna1" \
        "$@"
}
menu_confi () {
    zenity --title "$1" \
        --width="500" \
        --forms \
        --separator=":" \
        --text="Introduzca los datos para $SEL_USU:$SEL_GRU" \
        --add-entry="Nº copias guardadas" \
        --add-entry="Días entre copias"
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
    # Estructura del archivo log: acción:usuario:fecha:ruta_copia
    case $1 in
    copiar)
        echo $1":"$usuario":"$FECHA":"$DESTINO>>$BACKUP/.backup.log
    ;;
    restaurar)
        echo $1":"$REST_USU":"$FECHA":"$ORIGEN>>$BACKUP/.backup.log
    ;;
    borrar)
        echo $1":"$USER":"$FECHA":"$BACKUP/$usuario/$BORR_COP/$BORR_COP.tar.gz>>$BACKUP/.backup.log
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
    case $1 in
    usuario)
        sudo chown -R $REST_USU:$REST_USU $REST_RUT
    ;;
    grupo)
        sudo chown -R $REST_USU:$REST_GRU $REST_RUT
    ;;
    esac
}
visualizar_confi () {
    zenity --title "Configuraciones existentes" \
        --width="500" \
        --height="500" \
        --list \
        --multiple \
        --separator=" " \
        --column "Usuario" \
        --column "Grupo" \
        --column "Nº Copias" \
        --column "Nº Días" \
        `while IFS=: read SEL_USU SEL_GRU NUM_COP DIAS_COP
        do
            echo $SEL_USU
            echo $SEL_GRU
            echo $NUM_COP
            echo $DIAS_COP
        done<$BACKUP/.backup.conf`
}
crear_confi () { 
    DATOS=$(menu_confi "Configuración automática")
    NUM_COP=`echo $DATOS|cut -d":" -f1`
    DIAS_COP=`echo $DATOS|cut -d":" -f2`
    if [ "$NUM_COP" = "" ]; then
        error="No ha introducido el número de copias."
        zen_error
    else
        if [ "$DIAS_COP" = "" ]; then
            error="No ha introducido el número de días."
            zen_error
        else
            CONF_NUEVA=`echo $SEL_USU":"$SEL_GRU":"$NUM_COP":"$DIAS_COP`
            echo $CONF_NUEVA>>$BACKUP/.backup.conf
        fi
    fi
}
modificar_confi () {
    CONF_ACTUAL=$(cat $BACKUP/.backup.conf|grep $SEL_USU)
    DATOS=$(menu_confi "Modificar configuración")
    NUM_COP=`echo $DATOS|cut -d":" -f1`
    DIAS_COP=`echo $DATOS|cut -d":" -f2`
    if [ "$NUM_COP" = "" ]; then
        error="No ha introducido el número de copias."
        zen_error
    else
        if [ "$DIAS_COP" = "" ]; then
            error="No ha introducido el número de días."
            zen_error
        else
            CONF_NUEVA=`echo $SEL_USU":"$SEL_GRU":"$NUM_COP":"$DIAS_COP`
            sed -i "s/$CONF_ACTUAL/$CONF_NUEVA/" $BACKUP/.backup.conf
        fi
    fi
}


# Ejecución manual del script.
if [ $0 = "$HOME/bin/backup.sh" ]; then

    while [ $SALIDA -eq 0 ] 
    do
        # Menú principal.
        MENU=$(mostrar_menu "Backup.sh" "Opción" "Menú" \
            1 "Crear copia de seguridad." \
            2 "Restaurar copia de seguridad." \
            3 "Borrar copia de seguridad." \
            4 "Visualizar copias de seguridad." \
            5 "Configurar ejecución automática." \
            6 "Salir.")

# Pendiente por hacer para todo zenity.
# Comprobar botones de aceptar para no continuar la ejecución si no se ha pulsado aceptar.
# Comprobar cadenas vacias, para no continuar la ejecución si no se ha seleccionado nada. 

        # Chequear el botón cancelar y X para salir.
        if [ $? -eq 1 ]; then
            exit
        fi 

        # Submenus.
        case $MENU in
        1)
            # Submenu1 para crear copias.
            SUBMENU1=$(mostrar_menu "Crear copia de seguridad" "Opción" "Menú" \
                1 "Seleccionar un usuario o varios." \
                2 "Seleccionar un grupo de usuarios o varios.")

            case $SUBMENU1 in
            1)
                # Seleccionar un usuario o varios.
                SELECCION=$(menu_selec_multi "Lista de usuarios" "Usuarios del sistema" \
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
                SELECCION=$(menu_selec_multi "Lista de grupos" "Grupos del sistema" \
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
            SUBMENU2=$(mostrar_menu "Restaurar copia de seguridad" "Opción" "Menú" \
                1 "Restaurar copia de un usuario." \
                2 "Restaurar copia de un grupo." \
                3 "Restaurar copia de una fecha.")

            case $SUBMENU2 in 
            1)
                # Restaurar copia de un usuario.
                REST_USU=$(menu_selec "Restaurar copia de seguridad de un usuario" "Nombre de usuario" \
                    `for usuario in $BACKUP/*
                    do
                        echo $usuario|cut -d"/" -f5
                    done`)

                REST_COP=$(menu_selec "Restaurar copia de seguridad de $REST_USU" "Copias almacenadas" \
                    `for archivo in $BACKUP/$REST_USU/*
                    do
                        echo $archivo|cut -d"/" -f6
                    done`)

                # Bucle para pedir la ruta.
                SALIDA_RUT=0
                while [ $SALIDA_RUT -eq 0 ]
                do
                    REST_RUT=$(zen_forms "Restaurar copia de seguridad de $REST_USU" "Introduce la ruta absoluta." "Ruta")
                    
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
                REST_GRU=$(menu_selec "Restaurar copia de seguridad de un grupo" "Grupo" \
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
                            REST_COP=$(menu_selec "Restaurar copia de seguridad de $REST_USU" "Copias almacenadas" \
                                `for archivo in $BACKUP/$REST_USU/*
                                do 
                                    echo $archivo|cut -d"/" -f6
                                done`)

                            # Bucle para pedir la ruta.
                            SALIDA_RUT=0
                            while [ $SALIDA_RUT -eq 0 ]
                            do
                                REST_RUT=$(zen_forms "Restaurar copia de seguridad de $REST_USU" "Introduce la ruta absoluta." "Ruta")
                    
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
                REST_FEC=$(zen_calendar "Restaurar copia de seguridad")
                REST_FEC=`echo $REST_FEC|tr "/" "-"`
 
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
                SELECCION=$(menu_selec_multi "Restaurar copia de seguridad" "Copia" \
                    `echo $lista`)

                # Restauro las copias seleccionadas.
                for REST_COP in $SELECCION
                do
                    REST_USU=`echo $REST_COP|cut -d"_" -f2`
                    
                    # Bucle para pedir la ruta.
                    SALIDA_RUT=0
                    while [ $SALIDA_RUT -eq 0 ]
                    do
                        REST_RUT=$(zen_forms "Restaurar copia de seguridad de $REST_USU" "Introduce la ruta absoluta." "Ruta")
                    
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
            # Submenu3 para borrar copias de seguridad.
            SUBMENU3=$(mostrar_menu "Borrar copia de seguridad" "Opción" "Menú" \
                1 "Borrar copia de seguridad de uno o varios usuarios." \
                2 "Borrar copia de seguridad de uno o varios grupos." \
                3 "Borrar copia de seguridad de una fecha.")
            
            case $SUBMENU3 in
            1)
                # Borrar copia de seguridad de uno o varios usuarios.
                # Muestro los usuarios con copias.
                SELECCION=$(menu_selec_multi "Usuarios con copias almacenadas" "Usuarios" \
                    `for usuario in $BACKUP/*
                    do
                        echo $usuario|cut -d"/" -f5
                    done`)
                
                # Recorro los usuarios seleccionados
                for usuario in $SELECCION
                do
                    # Pido las copias que se quieran borrar.
                    SEL_COP=$(menu_selec_multi "Copias almacenadas para $usuario" "Copias" \
                    `for copia in $BACKUP/$usuario/*
                    do
                        echo $copia|cut -d"/" -f6
                    done`)
                    # Recorro las copias para borrarlas.
                    for BORR_COP in $SEL_COP
                    do
                        question="¿Esta seguro que quiere borrar $BORR_COP?"
                        zen_question
                        if [ $? -eq 0 ]; then
                            sudo rm -r $BACKUP/$usuario/$BORR_COP
                            generar_log borrar
                            notification=`echo "Copia" $BORR_COP "borrada."`
                            zen_notification
                        fi
                    done
                done
            ;;
            2)
                # Borrar copia de seguridad de uno o varios grupos.
                # Muestro los grupos.
                SELECCION=$(menu_selec_multi "Grupos del sistema" "Grupos" \
                `echo $GRUPOS`)

                # Recorro los grupos seleccionados.
                for grupo in $SELECCION
                do
                    # Saco la lista de usuarios perteneciente a cada grupo y los recorro para borrar las copias.
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
                                # Compruebo que el usuario tenga copias almacenadas.
                                cop_alm=`ls $BACKUP/$usuario/|wc -l`
                                if [ $cop_alm -gt 0 ]; then
                                    # Pido las copias que se quieran borrar.
                                    SEL_COP=$(menu_selec_multi "Copias almacenadas para $usuario" "Copias" \
                                    `for copia in $BACKUP/$usuario/*
                                    do
                                       echo $copia|cut -d"/" -f6
                                    done`)
                                    # Recorro las copias para borrarlas.
                                    for BORR_COP in $SEL_COP
                                    do
                                        question="¿Esta seguro que quiere borrar $BORR_COP?"
                                        zen_question
                                        if [ $? -eq 0 ]; then
                                            sudo rm -r $BACKUP/$usuario/$BORR_COP
                                            generar_log borrar
                                            notification=`echo "Copia" $BORR_COP "borrada."`
                                            zen_notification
                                        fi
                                    done
                                else
                                    notification=`echo -e "El usuario" $usuario "del grupo" $grupo "\nno tiene ninguna copia almacenada."`
                                    zen_notification
                                fi
                            done
                        fi
                    done</etc/group
                done
            ;;
            3)
                # Borrar copia de seguridad de una fecha.
                # Pido la fecha y le doy mi formato.
                BORR_FEC=$(zen_calendar "Restaurar copia de seguridad.")
                BORR_FEC=`echo $BORR_FEC|tr "/" "-"`

                # Recorro las carpetas de almacenamiento de cada usuario.
                for usuario in $BACKUP/*
                do
                    # Busco para cada usuario una copia con la fecha seleccionada y la borro.
                    for BORR_COP in $usuario/*
                    do
                        if [ `echo $BORR_COP|grep $BORR_FEC` ]; then
                            question="¿Esta seguro que quiere borrar `echo $BORR_COP|cut -d"/" -f6`?"
                            zen_question
                            if [ $? -eq 0 ]; then
                                sudo rm -r $BORR_COP
                                generar_log borrar
                                notificacion="Copia `echo $BORR_COP|grep $BORR_FEC` borrada."
                                zen_notification
                            fi
                        fi
                    done
                done
            ;;
            esac
        ;;
        4)
            # Submenu4 para visualizar copias.
            SUBMENU4=$(mostrar_menu "Visualizar copias de seguridad" "Opción" "Menú" \
                1 "Visualizar copias de uno o varios usuarios." \
                2 "Visualizar copias de uno o varios grupos." \
                3 "Visualizar copias de una fecha.")

            case $SUBMENU4 in 
            1)
                # Visualizar copias usuarios.
                # Muestro los usuarios con copias.
                SEL_USU=$(menu_selec_multi "Usuarios con copias almacenadas" "Usuario" \
                    `for usuario in $BACKUP/*
                    do
                        echo $usuario|cut -d"/" -f5
                    done`)

                # Recorro cada usuario seleccionado y sus copias para mostrarlas.
                mostrar_menu "Visualizar copias de uno o varios usuarios" "Usuario" "Copia" \
                    `echo $SEL_USU|tr " " "\n"|while read -r usuario
                    do
                        for copia in $BACKUP/$usuario/*
                        do
                            echo $usuario 
                            echo $copia|cut -d"/" -f6
                        done
                    done` 
            ;;
            2)
                # Visualizar copias grupos.
                # Muestro los grupos del sistema.
                SEL_GRU=$(menu_selec_multi "Grupos del sistema" "Grupo" \
                `echo $GRUPOS`)

#### A REVISAR. Puede que pase lo mismo en otras partes, vaciar la variable por si arrastra algo almacenado
                SEL_USU=""
                # Saco la lista de usuarios de los grupos seleccionados.
                for grupo in $SEL_GRU
                do
                    while IFS=: read etc_nom etc_pass etc_gid etc_usu
                    do
                        if [ "$grupo" = "$etc_nom" ]; then
                            if [ "$etc_usu" = "" ]; then
                                SEL_USU=$etc_nom
                            else
                                TEMP=$(echo $etc_usu|tr "," " ")
                                for usuario in $TEMP
                                do
                                    SEL_USU="$SEL_USU $usuario"
                                done
                            fi
                        fi
                    done</etc/group
                done

                # Recorro los usuarios y muestro sus copias.
                mostrar_menu "Visualizar copias de uno o varios grupos" "Usuario" "Copia" \
                `echo $SEL_USU|tr " " "\n"|while read -r usuario
                do
                    for copia in $BACKUP/$usuario/*
                    do
                        # Compruebo si tiene copias el usuario
                        if [ -d $copia ]; then 
                            echo $usuario
                            echo $copia|cut -d"/" -f6
                        fi
                    done
                done` 

            ;;
            3)
                # Visualizar copias de una fecha.
                VISU_FEC=$(zen_calendar "Visualizar copias de seguridad.")
                VISU_FEC=`echo $VISU_FEC|tr "/" "-"`

                # Muestro los usuarios y sus copias con la fecha seleccionada.
                mostrar_menu "Copias con fecha $VISU_FEC" "Usuarios" "Copias" \
                `for usuario in $BACKUP/*
                do
                    ls $usuario|grep $VISU_FEC|cut -d"_" -f2
                    ls $usuario|grep $VISU_FEC
                done`
            ;;
            esac
        ;;
        5)
            # Congigurar ejecución automática.

            # Creación del archivo de configuración.
            # Estructura del archivo: usuario:grupo:número_copias_guardadas:días_entre_copias
            if [ ! -f $BACKUP/.backup.conf ]; then
                touch $BACKUP/.backup.conf
            fi

            # Creación del enlace que ejecutará la parte automática.
            if [ ! -f $HOME/bin/autobackup.sh ]; then
                ln -s $HOME/bin/backup.sh $HOME/bin/autobackup.sh
            fi
            cat $HOME/.profile|grep autobackup.sh>temporal
            if [ $? -eq 1 ]; then
                echo "/home/abel/bin/autobackup.sh">>$HOME/.profile
            fi

            SUBMENU5=$(mostrar_menu "Configurar ejecución automática" "Opción" "Menú" \
            1 "Visualizar configuraciones existentes." \
            2 "Crear configuración para uno o varios usuarios." \
            3 "Crear configuración para uno o varios grupos." \
            4 "Modificar configuración para uno o varios usuarios." \
            5 "Modificar configuración para uno o varios grupos." \
            6 "Borrar configuraciones.")

            case $SUBMENU5 in
            1)
                # Visualizar configuraciones existentes.
                visualizar_confi
            ;;
            2)
                # Crear configuración para uno o varios usuarios.
                # Pido los usuarios.
                SELECCION=$(menu_selec_multi "Crear configuración para uno o varios usuarios" "Usuario" \
                    `echo $USUARIOS`)
                
                # Recorro los usuarios seleccionados.
                for SEL_USU in $SELECCION
                do
                    SEL_GRU=$SEL_USU  
                    # Compruebo si el usuario tiene una configuración.
                    if [ `cat $BACKUP/.backup.conf|grep $SEL_USU` ]; then
                        question=`echo -e "Ya existe una configuración para $SEL_USU.\n¿Desea modificarla?"`
                        zen_question
                        if [ $? -eq 0 ]; then
                            modificar_confi
                        fi
                    else                
                        crear_confi
                    fi
                done
            ;;
            3)
                # Crear configuración para uno o varios grupos.
                # Pido los grupos.
                SELECCION=$(menu_selec_multi "Crear configuración para uno o varios grupos" "Grupo" \
                    `echo $GRUPOS`)

                # Recorro los grupos seleccionados.
                for SEL_GRU in $SELECCION
                do
                    # Saco los usuarios del grupo.
                    while IFS=: read etc_nom etc_pass etc_gid etc_usu
                    do
                        if [ "$SEL_GRU" = "$etc_nom" ]; then
                            if [ "$etc_usu" = "" ]; then
                                LISTA_USU=$etc_nom
                            else
                                LISTA_USU=$(echo $etc_usu|tr "," " ")
                            fi
                        fi
                    done</etc/group
                    # Recorro los usuarios para crear sus configuraciones.
                    for SEL_USU in $LISTA_USU
                    do
                        # Compruebo si el usuario tiene una configuración.
                        if [ `cat $BACKUP/.backup.conf|grep $SEL_USU` ]; then
                            question=`echo -e "Ya existe una configuración para $SEL_USU.\n¿Desea modificarla?"`
                            zen_question
                            if [ $? -eq 0 ]; then
                                modificar_confi
                            fi
                        else
                            crear_confi
                        fi
                    done
                done
            ;;
            4)
                # Modificar configuración para uno o varios usuarios.
                # Muestro los usuarios que ya tienen configuración.
                SELECCION=$(menu_selec_multi "Modificar configuración para uno o varios usuarios" "Usuario" \
                    `while IFS=: read ARCH_USU ARCH_GRU ARCH_COP ARCH_DIA
                    do
                        echo $ARCH_USU
                    done<$BACKUP/.backup.conf`)

                # Recorro los usuarios seleccionados.
                for SEL_USU in $SELECCION
                do
                    SEL_GRU=$SEL_USU  
                    modificar_confi
                done
            ;;
            5)
                # Modificar configuración para uno o varios grupos.
                # Muestro los grupos que ya tienen configuración.
                SELECCION=$(menu_selec_multi "Modificar configuración para uno o varios grupos" "Grupo" \
                    `while IFS=: read ARCH_USU ARCH_GRU ARCH_COP ARCH_DIA
                    do
                        echo $ARCH_GRU
                    done<$BACKUP/.backup.conf`)

                #Recorro los grupos seleccionados
                for SEL_GRU in $SELECCION
                do
                    # Saco los usuarios del grupo.
                    while IFS=: read etc_nom etc_pass etc_gid etc_usu
                    do
                        if [ "$SEL_GRU" = "$etc_nom" ]; then
                            if [ "$etc_usu" = "" ]; then
                                LISTA_USU=$etc_nom
                            else
                                LISTA_USU=$(echo $etc_usu|tr "," " ")
                            fi
                        fi
                    done</etc/group
                    # Recorro los usuarios para modificar sus configuraciones.
                    for SEL_USU in $LISTA_USU
                    do
                        modificar_confi
                    done
                done
            ;;
            6)
                # Borrar configuraciones.
                SUBMENU5_6=$(mostrar_menu "Borrar configuración" "Opción" "Menú" \
                1 "Seleccionar una o varias configuraciones." \
                2 "Introducir nombre de usuario." \
                3 "Introducir nombre de grupo.")

                case $SUBMENU5_6 in
                1)
                    # Seleccionar configuraciones.
                    SELECCION=$(visualizar_confi)
                    
                    # Recorro las configuraciones seleccionadas para borrarlas.
                    for CONF in $SELECCION
                    do
                        CONF_ACTUAL=`cat $BACKUP/.backup.conf|grep $CONF`
                        sed -i "/$CONF_ACTUAL/d" $BACKUP/.backup.conf
                    done
                ;;
                2)
                    # Introducir nombre de usuario.
                    SEL_USU=$(zen_forms "Borrar configuración" "Rellena el campo" "Usuario")
                    
                    # Recorro el archivo para borrar el usuario introducido.
                    while IFS=: read ARCH_USU ARCH_GRU ARCH_COP ARCH_DIA
                    do
                        if [ "$ARCH_USU" = "$SEL_USU" ]; then 
                            CONF_ACTUAL=`cat $BACKUP/.backup.conf|grep $ARCH_USU`
                            sed -i "/$CONF_ACTUAL/d" $BACKUP/.backup.conf
                        fi
                    done<$BACKUP/.backup.conf
                ;;
                3)
                    # Introducir nombre de grupo.
                    SEL_GRU=$(zen_forms "Borrar configuración" "Rellena el campo" "Grupo")

                    # Recorro el archivo para borrar el grupo introducido.
                    while IFS=: read ARCH_USU ARCH_GRU ARCH_COP ARCH_DIA
                    do
                        if [ "$ARCH_GRU" = "$SEL_GRU" ]; then 
                            CONF_ACTUAL=`cat $BACKUP/.backup.conf|grep $ARCH_USU`
                            sed -i "/$CONF_ACTUAL/d" $BACKUP/.backup.conf
                        fi
                    done<$BACKUP/.backup.conf   
                ;;
                esac
            ;;
            esac
        ;;
        6)
            notification="Hasta otra $USER"
            zen_notification
            SALIDA=1
        ;;
        esac
    done
fi

# Ejecución automática del script.
if [ $0 = "$HOME/bin/autobackup.sh" ]; then

    typeset -i DD
    typeset -i MM
    typeset -i YY
    typeset -i NUM_DIAS_COP
    typeset -i NUM_DIAS_ACT
    typeset -i DIF
    DD=0
    MM=0
    YY=0
    NUM_DIAS_COP=0
    NUM_DIAS_ACT=0
    DIF=0
    # Recorro el archivo de configuración.
    while IFS=: read ARCH_USU ARCH_GRU ARCH_COP ARCH_DIA
    do
        echo "ARCH_USU: $ARCH_USU ARCH_GRU: $ARCH_GRU ARCH_COP: $ARCH_COP ARCH_DIA: $ARCH_DIA"
        usuario=$ARCH_USU
        if [ !-d "$BACKUP/$usuario" ]; then
            mkdir $BACKUP/$usuario
        fi
        ALMACENADAS=`ls -1 $BACKUP/$usuario|wc -l`
        if [ $ALMACENADAS -eq 0 ]; then
            crear_copia
        fi
        ULT_COP=`ls -1t $BACKUP/$usuario|head -1`
        
        # Días de la última copia.
        FEC_COP=`echo $ULT_COP|cut -d"_" -f3`
        DD=`echo $FEC_COP|cut -d"-" -f1`
        MM=(`echo $FEC_COP|cut -d"-" -f2`-1)*30
        YY=`echo $FEC_COP|cut -d"-" -f3`*365
        NUM_DIAS_COP=$DD+$MM+$YY

        # Días de la fecha actual.
        DD=`echo $FECHA|cut -d"-" -f1`
        MM=(`echo $FECHA|cut -d"-" -f2`-1)*30
        YY=`echo $FECHA|cut -d"-" -f3`*365
        NUM_DIAS_ACT=$DD+$MM+$YY

        # Días transcurridos desde la última copia.
        DIF=$NUM_DIAS_ACT-$NUM_DIAS_COP

        # Compruebo que la diferencia de días concuerde con la configuración del usuario.
        if [ $DIF -ge $ARCH_DIA ]; then
            crear_copia
        else
            if [ $ALMACENADAS -lt $ARCH_COP ]; then 
                crear_copia
            fi
        fi

        # Compruebo que el número de copias almacenadas concuerde con la configuración del usuario.
        if [ $ALMACENADAS -gt $ARCH_COP ]; then
            # Saco la copia más antigua para borrarla.
            BORR_COP=`ls -1t $BACKUP/$usuario|tail -1`
            sudo rm -r $BACKUP/$usuario/$BORR_COP
            generar_log borrar
        fi
    done<$BACKUP/.backup.conf

fi

if [ -f temporal ]; then
    rm temporal
fi