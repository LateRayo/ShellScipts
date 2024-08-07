#!/bin/bash

#CODIGO DEL ANTIGUO PROGREMA: 

# función para verificar la conectividad a internet
# check_internet_connection() {
#    ping -c 1 google.com > /dev/null 2>&1
#    return $?
# }

# verificar la conexión a internet
# if check_internet_connection; then
#     echo "estás conectado a internet."
#     rclone mount gdrive: /home/nikito/google-drive/ --allow-non-empty --vfs-cache-mode full --daemon
# else
#    echo "no estás conectado a internet."
# fi

#-------------------------------------------------------------------------
#CODIGO DEL NUEVO PROGREMA: 

#!/bin/bash

# Variables de configuración
REMOTE_NAME="gdrive"                          # Nombre del remoto configurado en rclone
REMOTE_PATH="/"                               # Carpeta en el remoto
LOCAL_PATH="/home/nikito/local-google-drive"  # Carpeta local dedicada a la sincronización
MOUNT_PATH="/home/nikito/google-drive"        # Punto de montaje para rclone
LOG_FILE="/home/nikito/rclone_mount.log"

# Función para verificar la conectividad a Internet
check_internet_connection() {
    curl -s --head http://www.google.com | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null
    return $?
}

# Función para verificar si rclone está instalado
check_rclone_installed() {
    command -v rclone > /dev/null 2>&1
    return $?
}

# Función para desmontar cualquier montaje previo de rclone
unmount_rclone() {
    fusermount -u $MOUNT_PATH > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$(date) - Desmontaje previo exitoso." >> $LOG_FILE
    else
        echo "$(date) - No se encontró un montaje previo o el desmontaje falló." >> $LOG_FILE
    fi
}

# Función para medir la velocidad de la conexión
check_connection_speed() {
    local url="http://speedtest.tele2.net/1MB.zip"
    local start_time=$(date +%s)
    curl -s -o /dev/null $url
    local end_time=$(date +%s)

    local duration=$((end_time - start_time))
    echo "$(date) - Tiempo de descarga $duration segundos." >> $LOG_FILE

    if [ $duration -le 10 ]; then
        return 0  # Conexión rápida
    else
        return 1  # Conexión lenta
    fi
}

# Función para montar rclone con parámetros optimizados
mount_rclone() {
    rclone mount $REMOTE_NAME:$REMOTE_PATH $MOUNT_PATH \
        --allow-non-empty \
        --vfs-cache-mode full \
        --vfs-cache-max-size 10G \
        --vfs-cache-max-age 72h \
        --buffer-size 128M \
        --dir-cache-time 168h \
        --poll-interval 30s \
        --transfers 4 \
        --checkers 8 \
        --attr-timeout 1s \
        --low-level-retries 20 \
        --timeout 10m \
        --daemon

    if [ $? -eq 0 ]; then
        echo "rclone montado exitosamente."
        echo "$(date) - rclone montado exitosamente." >> $LOG_FILE
    else
        echo "Error al montar rclone."
        echo "$(date) - Error al montar rclone." >> $LOG_FILE
        exit 1
    fi
}

# Función para copiar archivos con notificaciones
copy_files() {
    start_time=$(date +%s)

    # Variables para rastrear notificaciones enviadas
    notified_25=false
    notified_50=false
    notified_75=false
    notified_100=false

    # Variable para rastrear el estado de la copia
    copy_error=false
    nothing_to_transfer=false

    # Notificación de inicio de la copia
    notify-send "Copia iniciada" "La copia de archivos ha comenzado"
    echo "$(date) - Copia iniciada. La copia de archivos ha comenzado."

    # Comienza la copia con rclone y procesa la salida
    while IFS= read -r line; do
        echo "$(date) - $line" >> $LOG_FILE

        # Extracción de porcentaje de "Transferred"
        if [[ $line =~ Transferred:\ +([0-9]+)\ / ]]; then
            percentage=${BASH_REMATCH[1]}
        fi

        # Notificación en caso de error
        if [[ $line =~ "Error 403" ]]; then
            notify-send "Error 403" "Quota exceeded for quota metric 'Queries' and limit 'Queries per minute' of service 'drive.googleapis.com"
            echo "$(date) - Error en la copia. $line"
            echo "$(date) - Erro 403." >> $LOG_FILE
            copy_error=true
            break
        fi

        # Notificación cuando no hay nada para transferir
        if [[ $line =~ "nothing to transfer" ]]; then
            notify-send "Copia no necesaria" "No hay archivos para copiar"
            echo "$(date) - Copia no necesaria. No hay archivos para copiar."
            echo "$(date) - Copia no necesaria." >> $LOG_FILE
            nothing_to_transfer=true
            break
        fi

        # Verificar si hay un error
        if [[ $line =~ "ERROR" ]]; then
            notify-send "Error en la copia" "Ocurrió un error durante la copia"
            echo "$(date) - Error en la copia. Ocurrió un error durante la copia."
            copy_error=true
            break
        fi

        # Comprobación de cada 10 segundos
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        if (( elapsed_time % 10 == 0 )); then
            if [[ $percentage -ge 25 && $notified_25 == false ]]; then
                notify-send "Copia en progreso" "25% completado"
                echo "$(date) - Copia en progreso. 25% completado."
                notified_25=true
            elif [[ $percentage -ge 50 && $notified_50 == false ]]; then
                notify-send "Copia en progreso" "50% completado"
                echo "$(date) - Copia en progreso. 50% completado."
                notified_50=true
            elif [[ $percentage -ge 75 && $notified_75 == false ]]; then
                notify-send "Copia en progreso" "75% completado"
                echo "$(date) - Copia en progreso. 75% completado."
                notified_75=true
            elif [[ $percentage -ge 100 && $notified_100 == false ]]; then
                notify-send "Copia completa" "100% completado"
                echo "$(date) - Copia completa. 100% completado."
                notified_100=true
            fi
        fi
    #process substitution
    done < <(rclone copy $LOCAL_PATH $REMOTE_NAME:$REMOTE_PATH --progress --verbose 2>&1)

    if [ "$copy_error" = true ]; then
        exit 1
    elif [ "$nothing_to_transfer" = true ]; then
        exit 0
    else
        if [ $notified_100 == false ]; then
            notify-send "Copia completa" "100% completado"
            echo "$(date) - Copia completa. 100% completado."
        fi

        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "$(date) - Copia exitosa. Duración: $duration segundos." >> $LOG_FILE
        notify-send "Copia completa" "Duración: $duration segundos"
        echo "$(date) - Copia completa. Duración: $duration segundos."
        exit 0
    fi
}


# Función principal
main() {
    # Verificar si rclone está instalado
    if ! check_rclone_installed; then
        echo "rclone no está instalado. Por favor, instálalo y vuelve a intentarlo."
        echo "$(date) - rclone no está instalado." >> $LOG_FILE
        notify-send "Error" "rclone no está instalado"
        exit 1
    fi

    # Verificar la conexión a Internet
    if check_internet_connection; then
        echo "Estás conectado a Internet."

        # Verificar la velocidad de la conexión
        if check_connection_speed; then
            echo "La velocidad de la conexión es adecuada."

            # Desmontar cualquier montaje previo
            unmount_rclone

            # Iniciar rclone y montar el drive con parámetros optimizados
            mount_rclone

            # Copiar archivos
            copy_files
        else
            echo "La conexión es demasiado lenta. rclone no se iniciará."
            echo "$(date) - La conexión es demasiado lenta." >> $LOG_FILE
            notify-send "Copia pendiente" "La conexión es demasiado lenta"
            exit 1
        fi
    else
        echo "No estás conectado a Internet."
        echo "$(date) - No estás conectado a Internet." >> $LOG_FILE
        notify-send "Copia pendiente" "No estás conectado a Internet"
        exit 1
    fi

    # Registrar la operación en un archivo de log
    echo "$(date) - Script ejecutado exitosamente." >> $LOG_FILE
}

# Llamar a la función principal
main



