#!/bin/bash
 
#自定义根目录端口
xy2401_local_listen=2401
##获取 当前路径 和 父路径  
xy2401_local=`pwd`
xy2401_local_root=$(dirname `pwd`)
#echo $xy2401_local_root

## 获取ip地址
xy2401_local_ip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
xy2401_local_ip=( $xy2401_local_ip )
xy2401_local_ip=${xy2401_local_ip[0]} ## 获取第一个ip
#echo  $xy2401_local_ip

##拷贝 其他目录说明文件到此目录
while read line
do 
    ##如果是空行则跳过
    [[ -z "${line// }" ]] && continue 
    #echo $line
    stringarray=( $line ) #空格切割字符串 bash 的方法
    #echo ${stringarray[0]}${stringarray[1]}
    ##获取相关项目路径 将 / 替换为 空格 然后 获取 第二个字符串即 目录
    context=($(echo $line | tr "/" " "))
    #echo context${context[1]} 
    #echo ${stringarray[0]},${context[1]},${stringarray[1]} 
    ## 加上相对路径 [text](url) --> 替换为 [text](../context/url)  但是不要替换 https: 完整单词后面需要紧跟空格或者斜杠或者点
   cat  ${stringarray[0]} | sed -r "s#\]\((\w*)([ /.]+)#\]\(\.\.\/${context[1]}\/\1\2#g" >  "${stringarray[1]}" 
done < _file_list.txt

## 将 markdown 文件 转换成 html 文件
find ./ -iname "*.md" -type f -exec sh -c 'pandoc "${0}"  -s  --from markdown --to html5 -o "${0%.md}.html"' {} \; 

#  nginx配置文件
cat _xy2401_local.conf >  xy2401_local.conf 
sed -i "s#xy2401_local_listen#$xy2401_local_listen#g" xy2401_local.conf 
sed -i "s#xy2401_local_root#$xy2401_local_root/#g" xy2401_local.conf 
##创建独立域名的端口配置ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'
while read line
do 
    ##如果是空行则跳过
    [[ -z "${line// }" ]] && continue 
    #echo $line
    stringarray=( $line ) #空格切割字符串 bash 的方法
    #echo ${stringarray[0]},${stringarray[1]} 
    ##追加独立端口配置
    cat _xy2401_server.conf | \
    sed  "s#xy2401_local_server_listen#${stringarray[1]}#g" | \
    sed  "s#xy2401_local_server_root#${xy2401_local_root}/${stringarray[0]}/#g" \
    >> xy2401_local.conf 

   #生成的html将域名替换为本地ip
   sed -i "s#${stringarray[2]}#http://${xy2401_local_ip}:${stringarray[1]}#g"  *.html

done < _domain_list.txt

  
 
 
cp xy2401_local.conf /etc/nginx/xy2401_local.conf

## 停止并且启动 没有启动的时候不能 reload 
nginx -s stop
nginx


