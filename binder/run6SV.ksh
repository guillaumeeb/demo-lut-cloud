#!/bin/bash
#
# Xavier Lenot, ???-2018, maintenance
# Luc Hermitte, Mars 2018, Optimisations
# - Préparation de l'appel de 6SV non pas dans un fichier, mais en mémoire!

#parametres
REP_in6SV=$1
satellite=$2
capteur=$3
bande=$4
AER_NOM=$5
AER_TYPE=$6
thetav=$7
phi=$8
thetas=$9
ep_opt=${10}
uw=${11}
uO3=${12}
psurf=${13}
alti=${14}
FICBANDE=${15}
REP_out6SV=${16}
REP_CODE_TR=${17}
REP_WORK=${18}


########################################
######## Generation du fichier d'entree
########################################

#Nom du fichier d'entree
#FILEIN_6SV=${REP_in6SV}/IN6S_${satellite}_${capteur}_${bande}_${AER_NOM}_${thetav}_${phi}_${thetas}_${ep_opt}_${uw}_${uO3}_${psurf}_${alti}
FILEIN_6SV=IN6S_${satellite}_${capteur}_${bande}_${AER_NOM}_${thetav}_${phi}_${thetas}_${ep_opt}_${uw}_${uO3}_${psurf}_${alti}
input=()

#Definition des conditions geometriques.
#---------------------------------------
# IGEOM = 0 : Choix de saisie conditions geometriques et date par l'utilisateur.
# DATA : Directions d'incidence solaire et de visee
# DATA : Date de prise de vue (mois et jour).
#---------------------------------------------------------------
phis=0 #phi est l'azimut relatif
# cat > ${FILEIN_6SV} << EOF
# 0
# ${thetav} ${phi} ${thetas} ${phis} 1 1
# EOF
input+=(0)
input+=("${thetav} ${phi} ${thetas} ${phis} 1 1")

#Definition du profil atmospherique (quantit‰ de gaz absorbants).
#---------------------------------------------------------------
# IDATM = 7 : Ajustement du profil en fonction de la pression,
#           et de la quantite de vapeur d'eau (g/cm2) et d'ozone (cm.atm).
# DATA : Profil ajuste
#---------------------------------------------------------------
##profil=${REP_in6SV}/profil_${psurf}_${uw}_${uO3}.txt
#profil=profil_${psurf}_${uw}_${uO3}.txt
##${REP_WORK}/profil.exe ${psurf} ${uw} ${uO3} > ${profil}
#./profil.exe ${psurf} ${uw} ${uO3} > ${profil}
#cat >> ${FILEIN_6SV} << EOF
#7
#EOF
#
#cat ${profil} >> ${FILEIN_6SV}

input+=(7)
input+=("$(./profil.exe ${psurf} ${uw} ${uO3})")

#Definition du modele d'aerosols.
#--------------------------------
# (IAER = 5 : Modeles d'aerosols desertiques)
#---------------------------------------------------------------
#cat >> ${FILEIN_6SV} << EOF
#${AER_TYPE}
#EOF
input+=("${AER_TYPE}")

#Definition de la concentration des aerosols.
#-------------------------------------------
# V = 0 : Choix de saisie d'une epaisseur optique.
# DATA : Epaisseur optique des aerosols a 550 nm.
#---------------------------------------------------------------
#cat >> ${FILEIN_6SV} << EOF
#0
#${ep_opt}
#EOF
input+=(0)
input+=("${ep_opt}")

# XPS = -${alti} : cible a une altitude donnee en km
# XPP = -1000. : capteur spatial.
#---------------------------------------------------------------
#cat >> ${FILEIN_6SV} << EOF
#-${alti}
#-1000.
#EOF
input+=("-${alti}")
input+=("-1000.")

#Definition des bandes spectrales.
#---------------------------------
# IWAVE = 1 : introduction de bande spectrale par l'utilisateur.
#---------------------------------------------------------------
#cat >> ${FILEIN_6SV} << EOF
#1
#EOF
input+=("1")

#Definition de la r‰ponse spectrale du capteur
#---------------------------------------------
# cat ${FICBANDE} >> ${FILEIN_4SV} << EOF
# EOF
input+=("$(cat "${FICBANDE}")")

#Definition de la gamme de reflectance de surface.
#-------------------------------------------------
# INHOMO=0 : surface homogˆne
# IDIREC=0 : surface lambertienne
# IGROUN=0 : Reflectance de surface constante
# DATA : Reflectance de surface fixe.
#---------------------------------------------------------------
rho_surf=0.3  #reflectance (obligatoire mais pas d'impact sur nos simu)
# cat >> ${FILEIN_6SV} << EOF
# 0
# 0
# 0
# ${rho_surf}
# EOF
input+=(0)
input+=(0)
input+=(0)
input+=("${rho_surf} ")

# cat >> ${FILEIN_6SV} << EOF
# -1
# EOF
input+=(-1)

########################################
######## Execution de 6S
########################################

#Copie de 6S dans le TMPDIR
#test ! -f ${TMPCI}/sixsV1.1 && cp ${REP_CODE_TR}/sixsV1.1 ${TMPCI}/sixsV1.1

#Nom du fichier d'entree
#FILE_TMPOUT_6SV=${REP_out6SV}/TMPOUT6S_${satellite}_${capteur}_${bande}_${AER_NOM}_${thetav}_${phi}_${thetas}_${ep_opt}_${uw}_${uO3}_${psurf}_${alti}
FILE_TMPOUT_6SV=TMP6S_${satellite}_${capteur}_${bande}_${AER_NOM}_${thetav}_${phi}_${thetas}_${ep_opt}_${uw}_${uO3}_${psurf}_${alti}

FILEOUT_6SV=OUT6S_${satellite}_${capteur}_${bande}_${AER_NOM}_${thetav}_${phi}_${thetas}_${ep_opt}_${uw}_${uO3}_${psurf}_${alti}
# echo $FILEOUT_6SV

# if [ ! -f ${FILEOUT_6SV} ] ; then

        #Lancement de 6S

        # IFS=$'\n' output=($(printf "%s\n" "${input[@]}" | ./sixsV1.1))
        readarray -t output < <(printf "%s\n" "${input[@]}" | ./sixsV1.1)
        # printf "%s\n" "${output[@]}" > fic-out-LH

        ######## Lecture du fichier de sortie de 6S si il n est pas vide
        if [ ${#output[@]} -gt 0 ]
        then
                # Lecture de la Reflectance atmospherique
                # rhoATM=`sed -n -e '122p' ${FILE_TMPOUT_6SV} | awk '{print $2}'`
                rhoATM=$(echo "${output[121]}" | awk '{print $2}')

                # Lecture de l'albedo atmospherique
                # SATM=`sed -n -e '167p' ${FILE_TMPOUT_6SV} | awk '{print $7}'`
                SATM=$(echo "${output[166]}" | awk '{print $7}')

                # Lecture des transmissions gazeuses
                # Tdesc_gas=`sed -n -e '149p' ${FILE_TMPOUT_6SV} | awk '{print $6}'`
                # Tmont_gas=`sed -n -e '149p' ${FILE_TMPOUT_6SV} | awk '{print $7}'`
                # Ttot_gas=`sed -n -e '149p' ${FILE_TMPOUT_6SV} | awk '{print $8}'`
                read Tdesc_gas Tmont_gas Ttot_gas < <(echo "${output[148]}" | awk '{printf ("%s %s %s", $6, $7, $8)}')

                # Lecture des transmissions atmospheriques (molecules + aerosols)
                # Tdesc_sca=`sed -n -e '161p' ${FILE_TMPOUT_6SV} | awk '{print $6}'`
                # Tmont_sca=`sed -n -e '161p' ${FILE_TMPOUT_6SV} | awk '{print $7}'`
                # Ttot_sca=`sed -n -e '161p' ${FILE_TMPOUT_6SV} | awk '{print $8}'`
                read Tdesc_sca Tmont_sca Ttot_sca < <(echo "${output[160]}" | awk '{printf ("%s %s %s", $6, $7, $8)}')

                # Produits des transmissions ( gazeuse * mol/aer)
                Tdesc=$( echo "${Tdesc_gas}*${Tdesc_sca}" | bc)
                Tmont=$( echo "${Tmont_gas}*${Tmont_sca}" | bc)
                Ttot=$( echo "${Ttot_gas}*${Ttot_sca}" | bc)

                ######### Ecriture des resultats dans un fichier texte (une ligne au format de la LUT qui sera generee)
                # echo $thetav $thetas $phi $alti $psurf $ep_opt $uw $uO3 ${Tdesc} ${Tmont} ${Ttot} ${rhoATM} ${SATM} >> ${FILEOUT_6SV}
                echo $thetav $thetas $phi $alti $psurf $ep_opt $uw $uO3 ${Tdesc} ${Tmont} ${Ttot} ${rhoATM} ${SATM}
        else
                echo "$thetav $thetas $phi $alti $psurf $ep_opt $uw $uO3 sixs error!"
        fi

        ######### Destruction des fichiers d'entree et de sortie de 6S
        #rm ${profil} ${FILEIN_6SV} ${FILE_TMPOUT_6SV}
# fi

