#!/bin/bash

#Verification du fichier cartes.dot sur le repertoire courant
verifStr=$(ls -l .* | awk '{ printf $9 "\n" }' | grep cartes.dot)

if [[ "$verifStr" == "cartes.dot" ]] #Debut du premier if
then #Then du premier if
echo "$verifStr"
echo "Le fichier carte.dot est déjà présent"
echo "Voulez vous le supprimer ?"
read rep1?"N / Y :"
if [[ "$rep1" == "Y"]] #début du second
then #Then du second if 
echo "La suppression va commencer."
echo -n "--3"
sleep 1
echo -n "--2"
sleep 1
echo  "--1--"
sleep 1
rm -rf cartes.dot
echo "Fichier supprimé";
else if [[ "rep1" == "N"]]  #else du second if début du troisieme
then #then du troisieme
echo "Le fichier va changer de nom"
echo "cartes.dot -> cartes1.dot"
mv cartes.dot cartes1.dot
fi #fin du troisieme 
fi #fin du deuxieme
echo "Initalisation du traceroute";
sleep 1
echo "Script lancé";
echo " ";
else #else du premier if
echo "Le fichier cartes.dot n'est pas existant";
echo "Lancement du script dans quelques secondes"
echo -n "--3";
sleep 1
echo -n "--2";
sleep 1
echo  "--1--";
sleep 1
echo "Script lancé";
echo " ";
fi #fin du premier if 

routes=("$@")
			#liste des cibles utilisé pour construire la carte
list=("-T -p 80" "-I" "-U -p 33434 " "-T -p 443" "-T -p 22" "-U -p 5060" "-U -p 1194" "fin")
			#liste des protocoles les plus susceptibles de renvoyer une réponse
			#utilise les options de traceroute, -T pour TCP, -U pout UDP, -I pour ICMP, -p pour définir le port
echo "graph G { node [shape=box];" >> cartes.dot
			#initialisation du fichier .dot
			#première boucle qui fera un tour pour chaque éléments dans routes
for rts in "${routes[@]}"
do  ipcible=$(host "$rts" | sed -n '1p' | awk '{ printf $4 }')
			#transformation de l’adresse symbolique en adresse I
echo -n "Départ" >> cartes.dot
echo "---------------------------------------------------------"
echo "----------------Name : $rts-------------------------"
echo "----------------Ip $ipcible-------------------------"
echo "---------------------------------------------------------"
			#boucle qui fera un tour pour chaque TTL de 1 à 36
for (( TTL=1; TTL<=36; TTL++ ))
do
			#boucle qui fera un tour pour chaque éléments dans list
	for proto in "${list[@]}"
	do
			#condition if pour vérifier si la liste des protocole est terminé et avoir un affichage spécial
	 	if [ "$proto" = "fin" ]
		then
		echo "$TTL : * * *"
		echo -n " -- \" $TTL : * * * \n $rts\"" >> cartes.dot
		break
		fi
			#commande traceroute, options :
			# -N -> nombres de sondes
			# -n -> ne cherche pas à résoudre l'@ IP en nom
			# -f -> définit le TTL de départ
			# -m -> max ttl
			# -w -> temps d'attente pour réponse entre 2 sondes (en secondes)
			# $proto -> protocole dans la liste des protocoles
			# $rts -> adresse dans liste routes
	tr="traceroute -N 1 -n -f $TTL -m $TTL -w 2 -A $proto $rts"
	res=$($tr | sed -n '2p' | awk '{ printf $2 " " $3}')
	res2=$($tr | sed -n '2p' | awk '{ printf $2}')
			#renvoie le résultat quand un résultat est trouvé.
	if [ "$res2" != "*" ]
        then
	echo "$TTL : $res"
	echo -n " -- \"$res\"" >> cartes.dot
	break
	fi
	done
			#renvoie le dernier résultat sous une autre forme pour signifier la fin
	if [ "$ipcible" == "$res2" ]
        then
        echo "Fin : $rts"
			#hache le nom de la cible en md5 pour avoir un résultat en hexadécimal
			#on récupère les 6 premiers octets pour créer un couleur dans xdot sous la forme de 3 octets en hexadécimal
color=$(echo -n "$rts" | md5sum | cut -c 1-6)
echo "-- \"$rts\" [color=\"#$color\"];" >> cartes.dot
break
fi
done
done
			#finalisation du fichier .dot
echo " }" >> cartes.dot
chmod 666 ./cartes.dot
