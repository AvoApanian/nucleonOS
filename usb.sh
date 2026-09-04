#!/bin/bash

set -e

USB="$1"
MODE="$2"

# ============================================================
# Vérification des arguments
# ============================================================

if [ -z "$USB" ] || [ -z "$MODE" ]; then
    echo
    echo "Usage :"
    echo "  $0 /dev/sdX BIOS"
    echo "  $0 /dev/sdX UEFI"
    echo
    exit 1
fi

# ============================================================
# Vérification du périphérique
# ============================================================

if [ ! -b "$USB" ]; then
    echo
    echo "Erreur : $USB n'est pas un périphérique valide."
    echo
    echo "Périphériques disponibles :"
    lsblk
    echo
    exit 1
fi

# ============================================================
# Sélection de l'image
# ============================================================

case "$MODE" in

    BIOS)
        IMAGE="runable/BIOSRun/os.img"
        TITLE="NucleonOS BIOS 32-bit"
        ;;

    UEFI)
        IMAGE="runable/UEFIRun/esp.img"
        TITLE="NucleonOS UEFI x86_64"
        ;;

    *)
        echo
        echo "Erreur : mode invalide : $MODE"
        echo
        echo "Utilise :"
        echo "  BIOS"
        echo "  UEFI"
        echo
        exit 1
        ;;
esac

# ============================================================
# Vérification de l'image
# ============================================================

if [ ! -f "$IMAGE" ]; then
    echo
    echo "Erreur :"
    echo "$IMAGE introuvable."
    echo
    exit 1
fi

# ============================================================
# Informations
# ============================================================

echo
echo "=============================================="
echo "              NUCLEONOS USB"
echo "=============================================="
echo
echo "Version : $TITLE"
echo "Source  : $IMAGE"
echo "Cible   : $USB"
echo

echo "Image :"
ls -lh "$IMAGE"
echo

echo "Périphérique :"
lsblk "$USB"
echo

# ============================================================
# Confirmation
# ============================================================

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo " ATTENTION : LE CONTENU DE $USB SERA EFFACÉ"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo

read -r -p "Écrire $TITLE sur $USB ? [yes/NO] : " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo
    echo "Annulé."
    exit 0
fi

# ============================================================
# Démonter les partitions
# ============================================================

echo
echo "[1/3] Démontage des partitions..."

sudo umount "${USB}"* 2>/dev/null || true

# ============================================================
# Écriture
# ============================================================

echo
echo "[2/3] Écriture de $TITLE..."
echo

sudo dd \
    if="$IMAGE" \
    of="$USB" \
    bs=4M \
    status=progress \
    conv=fsync

# ============================================================
# Synchronisation
# ============================================================

echo
echo "[3/3] Synchronisation..."

sync

# ============================================================
# Terminé
# ============================================================

echo
echo "=============================================="
echo "                 TERMINÉ"
echo "=============================================="
echo
echo "Version : $TITLE"
echo "Image   : $IMAGE"
echo "USB     : $USB"
echo
echo "NucleonOS est maintenant écrit sur la clé."
echo

