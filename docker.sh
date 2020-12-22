#! /bin/bash

getGpuNums() {
  gpunums="nothing"
  if ! command -v nvidia-smi $> /dev/null ; then
    echo "Nvidia-smi is not available."
    exit 1
  fi
  while read row; do
    gpunums=${row}
  done <<<$(nvidia-smi --query-gpu=index --format=csv)
  if ! [[ $gpunums =~ ^[0-9]+$ ]] ; then
    echo "No gpu available."
    exit 1
  fi
  return $gpunums
}

getGpuNums
gpunums=$?
gpunums=$((gpunums + 1))
echo $gpunums
declare -a res_argument=()
state=0
for a in $@; do
  if [[ $a = "--gpus" ]] ; then
    if [[ $state -eq 1 ]] ; then
      echo "Invalid --gpus --gpus."
      exit 1
    fi
    state=1
  elif [[ $state -eq 1 ]] ; then
    if [[ $a == "all" ]] ; then
      res_argument=(${res_argument[@]} "--gpus" "$gpunums")
    elif [[ "$a" =~ ^[1-9][0-9]* ]] ; then
      b=a
      if [[ ${BASH_REMATCH[0]} -gt $gpunums ]] ; then
        length_num=${#BASH_REMATCH[0]}
        length_a=${#a}
        length=$(($length_a - $length_num))
        c=${a:$length_num:$length}
        b="${gpunums}${c}"
      fi
      res_argument=(${res_argument[@]} "--gpus" $b)
    else
      echo "Invalid --gpus format"
    fi
    state=0
  else
    res_argument=(${res_argument[@]} $a)
  fi
done

docker "${res_argument[@]}"
