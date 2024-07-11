REMOTE_NAME="gdrive"                          # Nombre del remoto configurado en rclone
REMOTE_PATH="/"                               # Carpeta en el remoto
LOCAL_PATH="/home/nikito/local-google-drive"  # Carpeta local dedicada a la sincronización
MOUNT_PATH="/home/nikito/google-drive"        # Punto de montaje para rclone
LOG_FILE="/home/nikito/rclone_mount.log"


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
    #antes no me funcioonaba la decteccion de errores por me falataba 2>&1
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


copy_files