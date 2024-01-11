# Pregunta si se está utilizando un portátil o un PC de escritorio
echo "¿Estás utilizando un [1] portátil o [2] PC de escritorio?"
read numero

# Validación de la entrada
if [ "$numero" != 1 ] && [ "$numero" != 2 ]; then
    echo "Número incorrecto. Por favor, introduce 1 para portátil o 2 para PC de escritorio."
    exit 1
fi

# modifico el archivo de configuracion de pacman
archivo_config="/etc/pacman.conf"
linea_a_buscar="#ParallelDownloads = 5"
nueva_linea="ILoveCandy"
archivo_temporal=$(mktemp)

while read -r linea; do
    echo "$linea" >> "$archivo_temporal"
    if [[ $linea == *"$linea_a_buscar"* ]]; then
        echo "$nueva_linea" >> "$archivo_temporal"
        echo "" >> "$archivo_temporal"
    fi
done < "$archivo_config"
mv "$archivo_temporal" "$archivo_config"

# Actualiza los repositorios y el sistema
sudo pacman -Syu --noconfirm

# Instala herramientas específicas para portátiles
if [ "$numero" == 1 ]; then
    sudo pacman -S --noconfirm cbatticon brightnessctl
fi

# Instala programas generales con comentarios explicativos
sudo pacman -S --noconfirm \
    xorg \                   # Servidor gráfico X
    xorg-xinit \
    picom \                  # Compositor para efectos visuales
    feh \                    # Visor de imágenes y fondo de pantalla
    xrandr \                 # Utilidad para configurar la disposición de pantalla
    arandr \                 # Interfaz gráfica para xrandr
    chromium \               # Navegador web Chromium
    alacritty \              # Emulador de terminal Alacritty
    lightdm \                # Gestor de pantalla ligero
    lightdm-gtk-greeter \    # Tema GTK para LightDM
    pulseaudio \             # Servidor de sonido PulseAudio
    trayer \                 # Administrador de bandeja del sistema
    pavucontrol \            # Controlador de volumen para PulseAudio
    rofi \                   # Lanzador de aplicaciones y buscador
    libnotify \              # Librería para mostrar notificaciones
    notification-daemon \    # Demonio para mostrar notificaciones
    udiskie \                # Montador automático de dispositivos de almacenamiento extraíbles
    ntfs-3g \                # Controlador NTFS para Linux
    libreoffice \            # Suite de oficina LibreOffice
    git \                    # Sistema de control de versiones
    unzip \                  # Herramienta para descomprimir archivos ZIP
    zip \                    # Herramienta para comprimir archivos ZIP
    scrot \                  # Herramienta para captura de pantalla
    vlc                      # Reproductor multimedia VLC
    base-devel

# intalacion automatica de aur
git clone https://aur.archlinux.org/yay-git.git /opt/yay
cd /opt/yay
sudo chown -R $USER:$USER .
makepkg -si
