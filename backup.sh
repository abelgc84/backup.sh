#! /bin/bash

# Creación del archivo de configuración.
# Estructura del archivo: 
# usuario:grupo:número_copias_guardadas:días_entre_copias
if [ ! -d $HOME/backup ]; then
    mkdir $HOME/backup
    touch $HOME/backup/backup.conf
else
    if [ ! -f $HOME/backup/backup.conf ]; then
        touch $HOME/backup/backup.conf
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

# Fecha actual
FECHA=`date +%d-%m-%y`

# Salida del menú principal.
SALIDA=0

# Funciones
crear_copia () {
    DESTINO=$BACKUP/$usuario/copia_${usuario}_${FECHA}.tar.gz
    ORIGEN=/home/$usuario
    sudo tar -czvf "$DESTINO" "$ORIGEN"
}
sobreescribir () {
    zenity --title "La copia con fecha $FECHA para $usuario ya existe" \
        --width="400" \
        --question \
        --text "¿Desea sobreescribirla?"
}
directorio () {
    if [ ! -d $BACKUP/$usuario ]; then
        mkdir $BACKUP/$usuario
    fi
}

# Ejecución manual del script.
if [ $0 = "$HOME/bin/backup.sh" ]; then

    while [ $SALIDA -eq 0 ] 
    do
        # Menú principal
        MENU=$(zenity --title "Backup.sh" \
            --width="500" \
            --height="500" \
            --list \
            --column "Opción" \
            --column "Menú" \
            1 "Crear copia de seguridad." \
            2 "Recuperar copia de seguridad." \
            3 "Borrar copia de seguridad." \
            4 "Programar copias de seguridad automáticas." \
            5 "Modificar la configuración de las copias automáticas." \
            6 "Visualizar usuarios que tienen copia de seguridad." \
            7 "Visualizar grupos que tienen copia de seguridad. " \
            8 "Salir.")

        # Chequear el botón cancelar y X para salir.
        if [ $? -eq 1 ]; then
            exit
        fi

        # Submenus
        case $MENU in
        1)
            # Submenu1 para crear copias.
            SUBMENU1=$(zenity --title "Crear copia de seguridad." \
                --width="500" \
                --height="500" \
                --list \
                --column "Opción" \
                --column "Menú" \
                1 "Seleccionar un usuario o varios." \
                2 "Seleccionar un grupo de usuarios o varios.")

            case $SUBMENU1 in
            1)
                # Selección de usuarios
                SELECCION=$(zenity --title "Lista de usuarios." \
                    --width="500" \
                    --height="500" \
                    --multiple \
                    --list \
                    --column "Usuarios del sistema" \
                    `echo $USUARIOS`)

                # Recorro los usuarios seleccionados para hacer sus copias de seguridad.
                SEL_USU=$(echo $SELECCION|tr "|" " ")
                for usuario in $SEL_USU
                do
                    # Comprobar que cada usuario tenga su directorio de copias.
                    directorio
                    # Comprobar que la copia no existe.
                    if [ ! -f $BACKUP/$usuario/copia_${usuario}_${FECHA}.tar.gz ]; then
                        crear_copia
                    else
                        sobreescribir
                        if [ $? -eq 0 ]; then
                            crear_copia
                        fi
                    fi
                done
            ;;
            2)
                # Selección de grupos
                SELECCION=$(zenity --title "Lista de grupos." \
                    --width="500" \
                    --height="500" \
                    --multiple \
                    --list \
                    --column "Grupos del sistema" \
                    `echo $GRUPOS`)

                # Recorro los grupos seleccionados para hacer sus copias de seguridad.
                SEL_GRU=$(echo $SELECCION|tr "|" " ")
                for grupo in $SEL_GRU
                do
                    # Saco la lista de usuarios perteneciente a cada grupo y los recorro para hacer sus copias
                    while IFS=: read etc_nom etc_pass etc_gid etc_usu
                    do
                        if [ "$grupo" = "$etc_nom" ]; then
                            if [ "$etc_usu" = "" ]; then
                                SEL_USU=$etc_nom
                            else
                                SEL_USU=$(echo $etc_usu|tr "," " ")
                            fi
                            for usuario in $SEL_USU
                            do
                                directorio
                                if [ ! -f $BACKUP/$usuario/copia_${usuario}_${FECHA}.tar.gz ]; then
                                    crear_copia
                                else
                                    sobreescribir
                                    if [ $? -eq 0 ]; then
                                        crear_copia
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
            SUBMENU2=$(zenity --title "Restaurar copia de seguridad." \
                --width="500" \
                --height="500" \
                --list \
                --column "Opción" \
                --column "Menú" \
                1 "Restaurar copia de un usuario." \
                2 "Restaurar copia de un grupo." \
                3 "Restaurar copia de una fecha.")

            case $SUBMENU2 in 
            1)
                echo "usuario"
            ;;
            2)
                echo "grupo"
            ;;
            3)
                echo "fecha"
            ;;
            esac
        ;;
        3)
            echo "Borrar copia"
        ;;
        4)
            echo "Programar copias"
        ;;
        5)
            echo "Modificar configuración"
        ;;
        6)
            echo "Visualizar usuarios"
        ;;
        7)
            echo "Visualizar grupos"
        ;;
        8)
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