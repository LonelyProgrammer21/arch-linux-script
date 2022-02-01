#!/bin/sh

SELECTEDSTORAGE=""
PARTCOUNT=1
PARTITIONLABEL=""
PARTITIONSIZE=0
repeat="true"
HOMEPARTITION=""
ERRORREPEAT="true"
PARTLEGEND=""
PARTCODE=("EF00" "8200" "8300" "8300")
if [[ ! -e "/usr/bin/gdisk" ]]; then
    pacman -S gdisk --noconfirm
fi
sed -i 's/#Para/Para/g' /etc/pacman.conf
lsblk
echo -e "Enter secondary storage location to specify the root installation\n Ex. /dev/sda, /dev/nvme0n1"
read SELECTEDSTORAGE


if [[ -e "$SELECTEDSTORAGE" ]]; then

    read -p "The selected device is $SELECTEDSTORAGE Are you sure to wipe this partition?[Y][N]:" CHOICE

    case $CHOICE in
        y|Yes|YES)

                sgdisk -o $SELECTEDSTORAGE
            while [[ $repeat == "true" ]]; do

                case $PARTCOUNT in
                    1) 
                    PARTLEGEND="BOOT" ;;
                    2) 
                    PARTLEGEND="SWAP" ;;
                    3)
                    PARTLEGEND="ROOT" ;;
                    4)
                    PARTLEGEND="HOME" ;;
                    *)
                    ;;
                esac

                echo "PARTITION TYPE: $PARTLEGEND"
                echo "Enter Partition name:"
                read PARTITIONLABEL

                echo -e "Enter Partition Size in GB (Enter nothing to consumes all the remaining memory):"
                read PARTITIONSIZE

                echo -e "Partitioning Partition number:$PARTCOUNT\n"
                sgdisk -n "${PARTCOUNT}"::+$PARTITIONSIZE -t "${PARTCOUNT}":${PARTCODE[$PARTCOUNT-1]} -c "${PARTCOUNT}":$PARTITIONLABEL $SELECTEDSTORAGE
                PARTCOUNT=$(($PARTCOUNT+1))
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
                        cryptsetup open ${SELECTEDSTORAGE}4 crypthome
                        while [[ ! -e "/dev/mapper/crypthome" ]]; do
                            echo "Invalid password, try again."
                            cryptsetup open "${SELECTEDSTORAGE}"4 crypthome
                        done
                        repeat="false"
                        HOMEPARTITION="/dev/mapper/crypthome"
                        mkfs.ext4 $HOMEPARTITION
                        ;;
                    n|N|No|NO)
                        repeat="false"
                        mkfs.ext4 "${SELECTEDSTORAGE}4"
                        HOMEPARTITION="${SELECTEDSTORAGE}4"
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
            mount $HOMEPARTITION /mnt/home

            pacstrap /mnt base base-devel linux-zen linux-zen-headers vim amd-ucode

            genfstab -U /mnt >> /mnt/etc/fstab
            echo "Base install is now finished.."
            echo "After the script is finished, type arch-chroot /mnt to your command line"
            cp ./postintallscript.sh /mnt
            ;;
            *)
            echo "Exiting now.."
            ;;
    esac
else 
    echo -e "Block device is not found Enter a correct device block to continue"
fi