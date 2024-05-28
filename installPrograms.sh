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
    xorg \
    xorg-xinit \
    picom \
    feh \
    xrandr \
    arandr \
    chromium \
    alacritty \
    lightdm \
    lightdm-gtk-greeter \
    pulseaudio \
    trayer \
    pavucontrol \
    rofi \
    libnotify \
    notification-daemon \
    udiskie \
    ntfs-3g \
    libreoffice \
    git \
    unzip \
    zip \
    scrot \
    vlc \
    base-devel

# intalacion automatica de aur
git clone https://aur.archlinux.org/yay-git.git /opt/yay
cd /opt/yay
sudo chown -R $USER:$USER . # Cambia la propiedad del directorio a tu usuario actual
makepkg -si

# Limpiar el sistema
sudo pacman -Rns $(pacman -Qdtq)
sudo pacman -Sc --noconfirm

echo "¡Instalación y configuración completadas!"
