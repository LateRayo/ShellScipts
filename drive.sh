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
LOG_FILE="/home/nikito/rclone_mount.log"      # archivo de logs

folders_to_sync=(
    "universidad/Analisis de Sistemas y Señales"
    "universidad/Informatica 2"
    "universidad/Fisica 2"
)

# Función para verificar la conectividad a Internet
check_internet_connection() 
{
    curl -s --head http://www.google.com | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null
    return $?
}

# Función para verificar si rclone está instalado
check_rclone_installed() 
{
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
mount_rclone() 
{
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
        notify-send "Fallo el montaje" "Error rclone mount"
        exit 1
    fi
}

#----------- hasta aca el motaje de la unidad remota -----------

# Función para enviar notificaciones según el progreso de la copia
send_progress_notification() 
{
    local progress=$1
    local message=$2
    local log_message=$3

    notify-send "$message" "$progress% completado"
    echo "$(date) - $log_message" >> $LOG_FILE
}


# Función para manejar errores durante la copia
handle_error() 
{
    local error_message=$1
    notify-send "Error en la copia" "$error_message"
    echo "$(date) - Error en la copia: $error_message" >> $LOG_FILE
}

# Función principal para copiar archivos con notificaciones
copy_files_to_cloud() 
{
    start_time=$(date +%s)
    
    # Variables para seguimiento del progreso y errores
    notified_progress=(false false false false)
    progress_levels=(25 50 75 100)
    
    copy_error=false
    nothing_to_transfer=false

    # Notificación de inicio
    notify-send "Copia iniciada" "La copia de archivos ha comenzado"
    echo "$(date) - Copia iniciada. La copia de archivos ha comenzado." >> $LOG_FILE

    # Iniciar la copia con rclone y procesar la salida
    # Este bucle while procesa la salida del comando rclone línea por línea en tiempo real.
    # El comando rclone se ejecuta para copiar archivos y su salida es pasada al bucle while mediante sustitución de procesos.
    # Cada línea generada por rclone se lee y almacena en la variable 'line'.
    while IFS= read -r line; do
        echo "$(date) - $line" >> $LOG_FILE

        # Extraer porcentaje de "Transferred"
        if [[ $line =~ Transferred:\ +([0-9]+)\ / ]]; then
            percentage=${BASH_REMATCH[1]}
        fi

        # Verificar si ocurrió un error específico
        if [[ $line =~ "Error 403" ]]; then
            handle_error "Quota exceeded for quota metric 'Queries' and limit 'Queries per minute' of service 'drive.googleapis.com'"
            copy_error=true
            break
        fi

        # Verificar si no hay nada para transferir
        if [[ $line =~ "nothing to transfer" ]]; then
            notify-send "Copia no necesaria" "No hay archivos para copiar"
            echo "$(date) - Copia no necesaria. No hay archivos para copiar." >> $LOG_FILE
            nothing_to_transfer=true
            break
        fi

        # Verificar cualquier otro error general
        if [[ $line =~ "ERROR" ]]; then
            handle_error "Ocurrió un error durante la copia"
            copy_error=true
            break
        fi

        # Enviar notificaciones según el progreso
        for i in "${!progress_levels[@]}"; do
            if [[ $percentage -ge ${progress_levels[i]} && ${notified_progress[i]} == false ]]; then
                send_progress_notification "${progress_levels[i]}" "Copia en progreso" "Copia en progreso. ${progress_levels[i]}% completado."
                notified_progress[i]=true
            fi
        done
    done < <(rclone copy "$LOCAL_PATH" "$REMOTE_NAME:$REMOTE_PATH" --update --progress --verbose 2>&1)

    # Finalización del proceso según el resultado
    if [ "$copy_error" = true ]; then
        exit 1
    elif [ "$nothing_to_transfer" = true ]; then
        return 0
    else
        if [ "${notified_progress[3]}" = false ]; then
            send_progress_notification "100" "Copia completa" "Copia completa. 100% completado."
        fi

        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "$(date) - Copia exitosa. Duración: $duration segundos." >> $LOG_FILE
        notify-send "Copia completa" "Duración: $duration segundos"
        return 0
    fi
}

# Función para sincronizar las carpetas desde Google Drive a local
# Las capetas vacas no se copian.
copy_files_to_local() 
{
    start_time=$(date +%s)
    
    # Variables para seguimiento del progreso y errores
    notified_progress=(false false false false)
    progress_levels=(25 50 75 100)
    
    sync_error=false
    nothing_to_sync=false

    # Iterar sobre las carpetas a sincronizar
    for folder in "${folders_to_sync[@]}"; do
        local_folder="$LOCAL_PATH/$folder"
        remote_folder="$REMOTE_NAME:$REMOTE_PATH/$folder"
        
        echo "Sincronizando $remote_folder a $local_folder..."
        notify-send "Sincronizando $remote_folder a $local_folder..."
        
        # Sincronizar archivos usando rclone y procesar la salida
        while IFS= read -r line; do
            echo "$(date) - $line" >> $LOG_FILE

            # Extraer porcentaje de "Transferred"
            if [[ $line =~ Transferred:\ +([0-9]+)\ / ]]; then
                percentage=${BASH_REMATCH[1]}
            fi

            # Verificar si ocurrió un error específico
            if [[ $line =~ "Error 403" ]]; then
                handle_error "Quota exceeded for quota metric 'Queries' and limit 'Queries per minute' of service 'drive.googleapis.com'"
                sync_error=true
                break
            fi

            # Verificar si no hay nada para transferir
            if [[ $line =~ "nothing to transfer" ]]; then
                notify-send "Sincronización no necesaria" "No hay archivos para sincronizar en $folder"
                echo "$(date) - Sincronización no necesaria para $folder. No hay archivos para sincronizar." >> $LOG_FILE
                nothing_to_sync=true
                break
            fi

            # Verificar cualquier otro error general
            if [[ $line =~ "ERROR" ]]; then
                handle_error "Ocurrió un error durante la sincronización de $folder"
                sync_error=true
                break
            fi

            # Enviar notificaciones según el progreso
            for i in "${!progress_levels[@]}"; do
                if [[ $percentage -ge ${progress_levels[i]} && ${notified_progress[i]} == false ]]; then
                    send_progress_notification "${progress_levels[i]}" "Sincronización en progreso" "Sincronización en progreso de $folder. ${progress_levels[i]}% completado."
                    notified_progress[i]=true
                fi
            done
        done < <(rclone copy "$remote_folder" "$local_folder" --update --progress --verbose 2>&1)

        # Finalización del proceso según el resultado de la carpeta actual
        if [ "$sync_error" = true ]; then
            exit 1
        elif [ "$nothing_to_sync" = true ]; then
            continue
        else
            if [ "${notified_progress[3]}" = false ]; then
                send_progress_notification "100" "Sincronización completa" "Sincronización completa de $folder. 100% completado."
            fi

            end_time=$(date +%s)
            duration=$((end_time - start_time))
            echo "$(date) - Sincronización exitosa de $folder. Duración: $duration segundos." >> $LOG_FILE
            notify-send "Sincronización completa" "Duración: $duration segundos para $folder"
        fi
    done
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

            #-----------hasta aca el motaje de la unidad remota -----------
            #-----------aqui empieza un copia local de archivos -----------

            # Copiar archivos de local a la nube
            copy_files_to_cloud

            # Copiar archivos de la nube a local
            copy_files_to_local


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
    echo "--------------------------------------------------------------------" >> $LOG_FILE
}

# Llamar a la función principal
main



