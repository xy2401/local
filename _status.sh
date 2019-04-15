#!/bin/bash

echo -e "Generated on `date`\n\n\n\n" > status.md


## 生成同级目录列表和大小
#[../3](../3) 
#size:49K  
#git repo size:41K  
#last commit:2019-04-15 18:49:11 +0800 82f5696 1
#遍历所有都同级目录/文件
for entry in ../*
do
	if [ -d "$entry" ];then #判断目录
		echo -n "[$entry]($entry) size:" >>  status.md
		du -sh $entry  | cut -f1  | tr '\n' ' ' >>  status.md 
    echo "    " >>  status.md
		if [ -d "$entry/.git" ];then
			echo -n "git repo size:" >>  status.md
			du -sh  $entry/.git   | cut -f1     >>  status.md
      echo -n "" >>  status.md
      echo -n "last commit:" >>  status.md
			git -C $entry log --format="%ci %h %B"  -n 1  >>  status.md
		fi
    echo -e "\n" >> status.md
	fi
done

