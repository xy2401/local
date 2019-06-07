#!/bin/bash
 
#自定义根目录端口
xy2401_local_listen=1401
##获取 当前路径 和 父路径  
xy2401_local=`pwd`
xy2401_local_local_root=$(dirname `pwd`)  ## local项目根目录
xy2401_local_root=$(dirname $xy2401_local_local_root) ## local系列根目录
 
#echo $xy2401_local_root

## 获取ip地址
xy2401_local_ip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
xy2401_local_ip=( $xy2401_local_ip )
xy2401_local_ip=${xy2401_local_ip[0]} ## 获取第一个ip
#echo  $xy2401_local_ip

#TODO参数处理

##拷贝 其他目录说明文件到此目录
while read line
do 
    ##如果是空行则跳过
    [[ -z "${line// }" ]] && continue 
    #echo $line
    stringarray=( $line ) #空格切割字符串 bash 的方法
    #echo ${stringarray[0]}${stringarray[1]}
    ##获取相关项目路径 将 / 替换为 空格 然后 获取 第一个字符串即 目录
    context=($(echo $line | tr "/" " "))
    #echo context${context[1]} 
    #echo ${stringarray[0]},${context[1]},${stringarray[1]} 


   #拷贝文件到本项目中
   cp ${xy2401_local_root}/${stringarray[0]} ${xy2401_local_local_root}/${stringarray[1]}
   #修改文件相对地址
   sed -r -i "s#\]\((\w*)([ /.]+)#\]\(\.\.\/${context[0]}\/\1\2#g"  ${xy2401_local_local_root}/${stringarray[1]}
    ## 加上相对路径 [text](url) --> 替换为 [text](../context/url)  但是不要替换 https: 完整单词后面需要紧跟空格或者斜杠或者点
    #cat  ${stringarray[0]} | sed -r "s#\]\((\w*)([ /.]+)#\]\(\.\.\/${context[0]}\/\1\2#g" >  "${stringarray[1]}"

done < readme_list.txt

## 将 markdown 文件 转换成 html 文件
find ${xy2401_local_local_root} -iname "*.md" -type f -exec sh -c 'pandoc "${0}"  -s  --from markdown --to html5 -o "${0%.md}.html"' {} \; 
 
##将由其他目录拷贝过来的 md 文件 超链接 替换为本地的html 
while read line
do 
    ##如果是空行则跳过
    [[ -z "${line// }" ]] && continue 
    #echo $line
    stringarray=( $line )
    sed -i "s#${stringarray[0]}#${stringarray[1]%.md}.html#g"  ${xy2401_local_local_root}/*.html
done < readme_list.txt

#href="status.md"
sed -i -r  "s#href=\"(\w*)\.md\"#href=\"\1.html\"#g" ${xy2401_local_local_root}/*.html


##创建独立域名的端口配置ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'
while read line
do 
    ##如果是空行则跳过
    [[ -z "${line// }" ]] && continue 
    [[ $line == \#* ]] && continue 
    #echo $line
    stringarray=( $line ) #空格切割字符串 bash 的方法
    #echo ${stringarray[0]},${stringarray[1]} 
    ##追加独立端口配置

   ## 拷贝文件 方便直接 修改临时文件
   cp default-nginx.conf default-nginx.conf.tmp 
   cp default-apache.conf default-apache.conf.tmp 
   # 如果有原始域名 则替换为本地地址
   #sub_filter '#sub_filter_string' '#sub_filter_replacement';##文本替换
    if [[  ${stringarray[3]} =~ [^[:space:]] ]] ; then
       echo "|${stringarray[3]}|"
       sed -i "s#\#sub_filter_replacement#http://${xy2401_local_ip}:${stringarray[1]}#g" default-nginx.conf.tmp ;
       sed -i "s#\#sub_filter_string#${stringarray[3]}#g" default-nginx.conf.tmp  ;
       sed -i "s#\#sub_filter#sub_filter#g" default-nginx.conf.tmp   ;
    fi
    
    #如果目录中存在 .htaccess 文件 则 启动 htaccess 配置
    #echo "${xy2401_local_root}/${stringarray[0]}/.htaccess"
    #if [ -f "${xy2401_local_root}/${stringarray[0]}/.htaccess" ]; then
    #   sed -i "s#\.htacces#${xy2401_local_root}/${stringarray[0]}/.htaccess#g" default-nginx.conf.tmp  ;
    #   sed -i "s#\#include#include#g" default-nginx.conf.tmp   ;
    #fi

    #添加防火墙
    #semanage port -a -t http_port_t -p tcp ${stringarray[1]}
    #semanage port -m -t http_port_t -p tcp ${stringarray[1]}
    #firewall-cmd --permanent --add-port=${stringarray[1]}/tcp



    cat default-nginx.conf.tmp | \
    sed  "s#xy2401_local_server_listen#${stringarray[1]}#g" | \
    sed  "s#xy2401_local_server_root#${xy2401_local_root}/${stringarray[0]}/#g" \
    >> default-nginx.conf.target

    cat default-apache.conf.tmp  | \
    sed  "s#xy2401_local_server_listen#${stringarray[1]}#g" | \
    sed  "s#xy2401_local_server_root#${xy2401_local_root}/${stringarray[0]}/#g" \
    >> default-apache.conf.target

   #生成的html将域名替换为本地ip
   sed -i "s#${stringarray[2]}#http://${xy2401_local_ip}:${stringarray[1]}#g"  *.html
 

done < domain_list.txt

#删除临时文件
rm default-nginx.conf.tmp 
rm default-apache.conf.tmp 
  

 ##重启防火墙 
 #firewall-cmd --reload
 
#cp default-nginx.conf.target /etc/nginx/local.conf
## 停止并且启动 没有启动的时候不能 reload 
#nginx -s stop
#nginx
#command -v nginx > /dev/null && echo nginx  -s stop && nginx 




## apache 配置
## Ubuntu
[[ -d "/etc/apache2/sites-enabled/" ]] && cp default-apache.conf.target /etc/apache2/sites-enabled/local.conf
## fedora
[[ -d "/etc/httpd/conf.d" ]] && cp default-apache.conf.target /etc/httpd/conf.d/local.conf

#apachectl stop
#apachectl start
#判断命令是否存在 并执行
command -v apachectl > /dev/null &&  apachectl stop && apachectl start


 