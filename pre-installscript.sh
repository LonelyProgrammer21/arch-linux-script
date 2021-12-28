#!/bin/sh

SELECTEDSTORAGE=""
PARTCOUNT=1
PARTITIONLABEL=""
PARTITIONSIZE=0
repeat="true"
MAXINDEX=0
ERRORREPEAT="true"
PARTCODE=("EF00" "8200" "8300")
if [[ ! -e "/usr/bin/gdisk" ]]; then
    pacman -S gdisk --noconfirm
fi
lsblk
echo -e "Enter secondary storage location to specify the installation\n Ex. /dev/sda, /dev/nvme0n1"
read SELECTEDSTORAGE

echo $SELECTEDSTORAGE

if [[ -e "$SELECTEDSTORAGE" ]]; then

    sgdisk -o $SELECTEDSTORAGE
    while [[ $repeat == "true" ]]; do
        echo -n "Enter Partition name:"
        read PARTITIONLABEL

        echo -e "Enter Partition Size (Enter nothing to consumes all the remaining memory)\n Ex. +1GB, +20GB, +512MB:"
        read PARTITIONSIZE

        echo -e "Partitioning Partition number:$PARTCOUNT\n"
        sgdisk -n "${PARTCOUNT-1}"::$PARTITIONSIZE -t "${PARTCOUNT-1}":${PARTCODE[$MAXINDEX]} -c "${PARTCOUNT-1}":$PARTITIONLABEL $SELECTEDSTORAGE
        PARTCOUNT=$(( $PARTCOUNT + 1 ))
        if [[ $PARTCOUNT -lt 4 ]]; then
        MAXINDEX=$PARTCOUNT-1
        fi
        if [[ "${#PARTITIONSIZE}" -ne 0 ]]; then
            echo -e "Do you want to add more partition?\n[Y][N]:"
            read repeat
        
            case $repeat in
                y|Y|Yes|YES)
                repeat="true";;
                n|N|No|NO)
                repeat="false";;
                *)
                    while [[ $ERRORREPEAT == "true" ]]; do
                    echo -e "Invalid input\n Do you want to add more partition?\n[Y][N]:"
                    read repeat
                
                    case $repeat in
                        y|Y|Yes|YES)
                        repeat="true"
                        ERRORREPEAT="false"
                        ;;
                        n|N|No|NO)
                        repeat="false"
                        ERRORREPEAT="false"
                        ;;
                        *)
                        ERRORREPEAT="true"
                        ;;
                    esac

                done
                ;;
            esac
        else
            repeat="false"
        fi
    done

    echo "Making filesystems..."

    mkfs.fat -F32 "${SELECTEDSTORAGE}1"
    mkswap "${SELECTEDSTORAGE}2"
    swapon "${SELECTEDSTORAGE}2"
    mkfs.ext4 "${SELECTEDSTORAGE}3"
   
    repeat="true"
    while [[ $repeat == "true" ]]; do
        echo -e "Do you want to encrypt your home partition?\n[Y][N]:"
        read repeat

        case $repeat in
            y|Y|Yes|YES)
             echo "Initializing encryption..."
             sleep 2
             cryptsetup luksFormat ${SELECTEDSTORAGE}4
             echo "Wait for the prompt and enter your password..."
             cryptsetup open ${SELECTEDSTORAGE}4 crypthome
                while [[ ! -e "/dev/mapper/crypthome" ]]; do
                    echo "Invalid password, try again."
                    cryptsetup open "${SELECTEDSTORAGE}"4 crypthome
                done
             repeat="false"
             mkfs.ext4 /dev/mapper/crypthome
             ;;
            n|N|No|NO)
            repeat="false"
            mkfs.ext4 "${SELECTEDSTORAGE}4"
            ;;
            *)
            repeat="true"
            ;;
        esac
    done

mount ${SELECTEDSTORAGE}3 /mnt
mkdir -p /mnt/boot
mount ${SELECTEDSTORAGE}1 /mnt/boot
mkdir -p /mnt/home
mount ${SELECTEDSTORAGE}4 /mnt/boot
pacstrap /mnt base base-devel linux-zen linux-zen-headers vim amd-ucode

genfstab -U /mnt >> /mnt/etc/fstab
echo "DONE!"
else 
    echo -e "Block device is not found Enter a correct device block to continue"
fi