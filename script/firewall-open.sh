## 开启防火墙 


while read line
do 
 stringarray=( $line )
    #添加防火墙
    semanage port -a -t http_port_t -p tcp ${stringarray[1]}
    semanage port -m -t http_port_t -p tcp ${stringarray[1]}
    firewall-cmd --permanent --add-port=${stringarray[1]}/tcp
done < domain_list.txt
firewall-cmd --reload


