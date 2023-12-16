#! /bin/bash

# Creación del archivo de configuración
if [ ! -d $HOME/backup ]; then
    mkdir $HOME/backup
    touch $HOME/backup/backup.conf
else
    if [ ! -f $HOME/backup/backup.conf ]; then
        # Estructura del archivo: 
        # usuario:grupo:número_copias_guardadas:días_entre_copias
        touch $HOME/backup/backup.conf
    fi
fi

backup=$HOME/backup
salida=0

if [ $0 = "$HOME/bin/backup.sh" ]; then

    while [ $salida -eq 0 ] 
    do
        #Menú principal
        menu=$(zenity --title "Backup.sh" \
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

        #Chequear el boton cancelar y X para salir
        if [ $? -eq 1 ]; then
            exit
        fi

        #Submenus
        case $menu in
        1)
            #Submenu1 para crear copias
            submenu1=$(zenity --title "Crear copia de seguridad." \
                --width="500" \
                --height="500" \
                --list \
                --column "Opción" \
                --column "Menú" \
                1 "Seleccionar un usuario o varios." \
                2 "Seleccionar un grupo de usuarios o varios.")

            case $submenu1 in
            1)
                #Selección de usuarios
                #El comando cat muestra solo los usuarios con 1000 o más de UID
                list_usuarios=$(zenity --title "Lista de usuarios." \
                    --width="500" \
                    --height="500" \
                    --multiple \
                    --list \
                    --column "Usuarios del sistema" \
                    `cat /etc/passwd|cut -d":" -f1-3|grep -E ":[1-9][0-9]{3}"|cut -d":" -f1|grep -v nobody`)

                #Recorro los usuarios seleccionados y hago su copia de seguridad
                usuarios=$(echo $list_usuarios|tr "|" " ")
                for user in $usuarios
                do
                    echo $user
                done
            ;;
            2)
                #Selección de grupos
                #Uso el mismo comando cat para visualizar los grupos con 1000 o más de GUID
                list_grupo=$(zenity --title "Lista de grupos." \
                    --width="500" \
                    --height="500" \
                    --multiple \
                    --list \
                    --column "Grupos del sistema" \
                    --colu
                    `cat /etc/group|grep -E ":[1-9][0-9]{3}"|cut -d":" -f1|grep -v nogroup`)

                #Recorro los grupos seleccionados
                grupos=$(echo $list_grupo|tr "|" " ")
                for group in $grupos
                do
                    #Saco la lista de usuarios perteneciente a cada grupo y los recorro para crear su copia de seguridad
                    list_usuarios=$(cat /etc/group|grep $group|cut -d":" -f4)
                    usuarios=$(echo $list_usuarios|tr "," " ")
                    for user in $usuarios
                    do
                        echo $user
                    done
                done
            ;;
            esac
        ;;
        2)
            echo "Recuperar copia"
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
            salida=1
        ;;
        esac

    done

fi

if [ $0 = "$HOME/bin/autobackup.sh" ]; then

    echo "Estoy dentro de .profile."

fi