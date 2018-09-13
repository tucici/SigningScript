#!/bin/bash

#
#echo -e "password: \c";read password
#security unlock-keychain -p "${password}" /Users/skyline/Library/Keychains/login.keychain
#
#echo -e "p12 :\c";read p12
#echo -e "p12mima :\c";read mima
#security import "${p12}" -k /Users/skyline/Library/Keychains/login.keychain -P "${mima}" -T /usr/bin/codesign
#

#判断ipa路径是否存在，不存在则输入ipa路径
func_setPath_ipa()
{
echo -e "警告: 未发现ipa，请设置ipa路径: \c";read IPA_PATH
if [[ ! -f "${IPA_PATH}" || ! "${IPA_PATH##*/}" =~ ".ipa" ]];then
func_setPath_ipa
else
cd "${IPA_PATH%/*}"
pwd
fi

}
func_setPath_ipa

#判断描述路径是否存在,不存在则输入描述路径
func_setPath_pro()
{
echo -e "警告: 未发现mobileprovision，请设置mobileprovision路径: \c"; read PRO_PATH
if [[ ! -f "${PRO_PATH}" || ! "${PRO_PATH##*/}" =~ ".mobileprovision" ]];then
func_setPath_pro
fi
}
func_setPath_pro

#判断证书路径是否存在,不存在则输入证书路径
funC_setPath_cer()
{
echo -e "警告: 未发现cer，请设置cer路径: \c"; read CER_PATH
if [[ ! -f "${CER_PATH}" || ! "${CER_PATH##*/}" =~ ".cer" ]];then
funC_setPath_cer
fi
}

#选择证书安装方式
funC_setchooseNum()
{
echo -e "选择:1 自动安装证书\n     2 手动安装证书"; read chooseNum
if [[ ! "${chooseNum}" == "1" && ! "${chooseNum}" == "2" ]];then
funC_setchooseNum
elif [ "${chooseNum}" == "1" ];then
funC_setPath_cer
fi
}
funC_setchooseNum


#设置重签名后的ipa名称
echo -e "注意: 请设置重签名后的ipa文件名称: \c"; read NEW_IPA_NAME


#echo -e 对转义字符进行替换
#echo -E 禁止转义(默认禁止转义)
echo -e "\n${IPA_PATH}\n"
echo -e "\n${PRO_PATH}\n"
echo -e "\n${CER_PATH}\n"


#倒入证书
echo -e "\n************************************导入证书${CER_PATH##*/}************************************\n"
if [ "${chooseNum}" == "1" ];then
security import "${CER_PATH}" -k /Users/skyline/Library/Keychains/login.keychain -P -T /usr/bin/codesign
fi
echo -e "请输入证书全名称，如果证书全名不对，重签名后的ipa不能正常使用 \n (example:iPhone Distribution: users name (xxxxxxxxx)):\c";read CER_NAME
echo -e "\n************************************导入证书完成************************************\n"

#解压ipa
echo -e "\n************************************解压${IPA_PATH##*/}************************************\n"
unzip "${IPA_PATH##*/}"
echo -e "\n************************************解压完成************************************\n"


#重命名
echo -e "\n**********************************重命名${PRO_PATH##*/}**********************************\n"
mv "${PRO_PATH##*/}" embedded.mobileprovision

for file in `ls Payload`
do
APP_NAME=$file
echo "copy   embedded.mobileprovision    ---->   $file"
cp embedded.mobileprovision /Payload/$file
done
echo -e "\n**********************************重命名完成**********************************\n"


#提取描述文件中关键键值对，并生成plist，保存
echo -e "\n************************************生成Entitlements.plist************************************\n"
security cms -D -i embedded.mobileprovision -o Entitlements.plist #从描述文件中提取健值对，生成Entitlements.plist
plutil -extract Entitlements xml1 Entitlements.plist -o Entitlements.plist #从Entitlements.plist提取关键键值Entitlements，其余的键值对删除，保存
echo -e "\n************************************完成Entitlements.plist************************************\n"

#重签名
echo -e "\n************************************重签名解压${IPA_PATH##*/}************************************\n"
/usr/bin/codesign -f -s "${CER_NAME}" --entitlements=Entitlements.plist ／Payload/$APP_NAME
echo -e "\n************************************重签名完成************************************\n"

echo -e "\n************************************压缩文件************************************\n"
zip -r ${NEW_IPA_NAME} Payload
echo -e "\n************************************压缩完成************************************\n"

echo  "${IPA_PATH%/8}/${NEW_IPA_NAME}"
echo -e "\n************************************重签名完成************************************\n"

#echo -e "解压"

