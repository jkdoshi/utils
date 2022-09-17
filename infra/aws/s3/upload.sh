#!/usr/bin/env bash

#script inspired by http://tmont.com/blargh/2014/1/uploading-to-s3-in-bash

if [ $# -lt 3 ]; then
  echo "Usage: $0 <filepath> <content-type> <bucket> [<optional-target-filepath>] [public]"
  echo "Example: ./upload.sh ../../foo.html text/html test1.s3.spinspire.com bar/lum.html public"
  exit 1
fi

file="$1"
contentType="$2"
bucket="$3"
filename="${4-$(basename $file)}"
resource="/${bucket}/${filename}"
dateValue=`date -R`
if [ "x$5" = "xpublic" ]; then
  stringToSign="PUT\n\n${contentType}\n${dateValue}\nx-amz-acl:public-read\n${resource}"
else
  stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
fi
#the ~/.aws/key.csv should have the key-id and key in the following format
#AWSAccessKeyId=...
#AWSSecretKey=...
source ~/.aws/key.csv
signature=$(echo -en ${stringToSign} | openssl sha1 -hmac ${AWSSecretKey} -binary | base64)
if [ "x$5" = "xpublic" ]; then
  curl -k -X PUT -T "${file}" \
    -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${dateValue}" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${AWSAccessKeyId}:${signature}" \
    -H "x-amz-acl: public-read" \
    https://${bucket}.s3.amazonaws.com/${filename}
else
  curl -k -X PUT -T "${file}" \
    -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${dateValue}" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${AWSAccessKeyId}:${signature}" \
    https://${bucket}.s3.amazonaws.com/${filename}
fi