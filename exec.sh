#!/bin/bash
set -eu
# Set work directory
readonly work_dir=$(pwd)

# Set output, temporary file full path
readonly default_read_only_access_policy="${work_dir}"/ReadOnlyAccess.json
readonly complement_read_only_access="${work_dir}"/ComplementReadOnlyAccess.json
readonly action_list_file="${work_dir}"/action_list_file.txt
readonly read_only_list="${work_dir}"/read_only_list.txt

# Determine and set python commands
if command -v python3 &>/dev/null; then
  python_cmd="python3"
elif command -v python &>/dev/null; then
  python_cmd="python"
else
  echo "Error: Python is not installed." >&2
  exit 1
fi

execute(){
  # Get ReadOnlyAccess policy arn
  read_only_access_policy_arn=$(aws iam list-policies --scope AWS --query 'Policies[?PolicyName==`ReadOnlyAccess`].Arn' --output text)
  # Get default ReadOnlyAccess version
  read_only_access_policy_version=$(aws iam list-policies --scope AWS --query 'Policies[?PolicyName==`ReadOnlyAccess`].DefaultVersionId' --output text)
  # Get default ReadOnlyAccess document
  aws iam get-policy-version --policy-arn ${read_only_access_policy_arn} --version-id ${read_only_access_policy_version} --query 'PolicyVersion.Document' > ${default_read_only_access_policy}
  # Get each aws service servicereference url from https://servicereference.us-east-1.amazonaws.com/
  service_reference_list=$(curl https://servicereference.us-east-1.amazonaws.com/ | jq '.[].url' | sed 's/"//g')

  # Get service prefix, aws api action name from each aws service servicereference url 
  for service_reference in $(echo $service_reference_list) ; do
    service_prefix=$(curl ${service_reference} | jq '.Name' | sed 's/"//g')
    actions=$(curl ${service_reference} | jq '.Actions[].Name' | sed 's/"//g')
    
    # Match the obtained AWS API action name with the default ReadOnlyAccess policy, and write the missing actions to a temporary file.
    for action in $(echo $actions) ; do
      action_first_verb=$(echo "${action}" | sed 's/\([A-Z][a-z]*\).*/\1/')

      if ! grep "${service_prefix}:${action_first_verb}*" ${default_read_only_access_policy} 1>/dev/null 2>&1 ; then
          echo "${service_prefix}:${action_first_verb}" >> ${action_list_file}
      fi
    done
  done

  # Extract only the read actions beginning with "Get", "List", "Describe" and "View" from the temporary file you created.
  grep -e "Get" -e "List" -e "Describe" -e "View" action_list_file.txt | uniq | sed 's/$/*",/g' | sed 's/^/"/g' > ${read_only_list}
  read_only_actions=$(cat ${read_only_list})

# Format the extracted AWS API actions into an IAM policy document and save it locally.
cat << EOF | ${python_cmd} -m json.tool > ${complement_read_only_access}
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Sid" : "ComplementReadOnlyAccess",
      "Effect" : "Allow",
      "Action" : [
$(echo ${read_only_actions/%?/})
      ],
      "Resource" : "*"
    }
  ]
}
EOF

  # Clean up by deleting temporary files
  rm -rf  ${action_list_file} ${read_only_list} ${default_read_only_access_policy}
  exit 0
}

usage() {
  cat <<_EOT_

Usage:
  ./$(basename ${0}) <options>

Description:
  en)
  Create a customer-managed policy to cover read-only actions of AWS APIs 
  that are not covered by the default version of ReadOnlyAccess.

  ja)
  デフォルトバージョンの ReadOnlyAccess で網羅されていない
  AWS API の読み取り系アクションを補うカスタマーマネージドポリシーを作成します。

Require:
  - AWS CLI (It doesn't matter if it's version 1 or 2)
  - curl, jq, sed
  - list-policies get-policy-version
  
Options:
  -v  print $(basename ${0}) version
  -h  print this
  -e  Create complement "ReadOnlyAccess" policy

_EOT_
  exit 1
}

version() {
  echo "$(basename ${0}) version 0.0.1"
  exit 1
}  

while getopts :hve opt
do
  case $opt in
    h)
      usage
    ;;
    v)
      version
    ;;
    e)
      execute
    ;;
    *)
      echo "[ERROR] Invalid option '${1}'"
      usage
      exit 1
    ;;
  esac      
done
