### load.sh 
for count in {1..3}; do 
echo -n "####################### Test IDPS Scan #######################"
sudo nmap -v -sS sp2-vm-a --osscan-guess -p U:53,111,137,T:21-25,80,139,8080,S:9
sudo nmap -v -sS sp2-vm-b --osscan-guess -p U:53,111,137,T:21-25,80,139,8080,S:9
sudo nmap -v -sS op-vm-a --osscan-guess -p U:53,111,137,T:21-25,80,139,8080,S:9
done

for count in {1..3}; do 
clear
echo "####################### Test IDPS #######################"
curl -A "BlackSun" www.microsoft.com -v

echo "####################### Test Threat Intel#######################"
curl securepubads.g.doubleclick.net 
curl testmaliciousdomain.eastus.cloudapp.azure.com

done

#for count in {1..3}; do 
echo "####################### Test Proxy - Blocked #######################"
curl uol.com.br
curl terra.com.br
curl estadao.com.br
curl folha.com.br
curl bb.com.br
curl amazon.com
#done

#for count in {1..2}; do 
echo "####################### Test Proxy - Allowed #######################"
curl microsoft.com -v
curl ibm.com -v
curl oracle.com -v
curl aws.amazon.com -v 
curl caixa.gov.br -v
#done

echo -n "####################### Test Neighboard Reachability #######################"
fping -c 1 sp1-vm-b -a
fping -c 1 sp2-vm-a -a
fping -c 1 sp2-vm-b -a
fping -c 1 op-vm-a -a

### scan.sh 
sudo nmap -v -sV --script=vulscan/vulscan.nse sp2-vm-a --osscan-guess -p T:22,80,S:9
sudo nmap -v -sV --script=vulscan/vulscan.nse sp2-vm-b --osscan-guess -p T:22,80,S:9
sudo nmap -v -sV --script=vulscan/vulscan.nse op-vm-a --osscan-guess -p T:22,80,S:9