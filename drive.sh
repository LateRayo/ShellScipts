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

#CODIGO DEL NUEVO PROGREMA: 


# Función para verificar la conectividad a Internet
check_internet_connection() {
    # Usa curl para enviar una solicitud HTTP a Google y verificar si la respuesta es un código 200 o 300.
    curl -s --head http://www.google.com | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null
    return $?
}

# Función para verificar si rclone está instalado
check_rclone_installed() {
    # Comprueba si el comando rclone está disponible en el PATH del sistema.
    command -v rclone > /dev/null 2>&1
    return $?
}

# Función para desmontar cualquier montaje previo de rclone
unmount_rclone() {
    # Usa fusermount para desmontar el directorio /home/nikito/google-drive si está montado.
    fusermount -u /home/nikito/google-drive > /dev/null 2>&1
}

# Función para medir la velocidad de la conexión
check_connection_speed() {
    local url="http://speedtest.tele2.net/1MB.zip"
    local start_time=$(date +%s)

    # Descarga un archivo de 1MB y mide el tiempo que tarda en completarse.
    # el menos o redirige la salida de la url a /dev/null
    curl -s -o /dev/null $url
    local end_time=$(date +%s)

    local duration=$((end_time - start_time))
    echo "$(date) - tiempo de descarga $duration segundos." >> /home/nikito/rclone_mount.log

    # Si tarda más de 10 segundos en descargar 1 MB, se considera la conexión como lenta.
    if [ $duration -le 10 ]; then
        return 0  # Conexión rápida
    else
        return 1  # Conexión lenta
    fi
}

# Función principal
main() {
    # Verificar si rclone está instalado
    if ! check_rclone_installed; then
        echo "rclone no está instalado. Por favor, instálalo y vuelve a intentarlo."
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
            rclone mount gdrive: /home/nikito/google-drive/ \
                --allow-non-empty \
                --vfs-cache-mode full \
                --vfs-cache-max-size 10G \
                --vfs-cache-max-age 24h \
                --buffer-size 64M \
                --dir-cache-time 72h \
                --poll-interval 15s \
                --transfers 8 \
                --checkers 8 \
                --attr-timeout 1s \
                --low-level-retries 20 \
                --timeout 10m \
                --daemon

            # Verifica si el montaje fue exitoso
            if [ $? -eq 0 ]; then
                echo "rclone montado exitosamente."
            else
                echo "Error al montar rclone."
                echo "$(date) - Error al montar rclone." >> /home/nikito/rclone_mount.log
                exit 1
            fi
        else
            echo "La conexión es demasiado lenta. rclone no se iniciará."
            echo "$(date) - La conexión es demasiado lenta." >> /home/nikito/rclone_mount.log
            exit 1
        fi
    else
        echo "No estás conectado a Internet."
        echo "$(date) - No estás conectado a Internet." >> /home/nikito/rclone_mount.log
        exit 1
    fi

    # Registrar la operación en un archivo de log
    echo "$(date) - Script ejecutado" >> /home/nikito/rclone_mount.log
}

# Llamar a la función principal
main

# si quisiera desmontar rclone: 
# fusermount -u /home/nikito/google-drive
