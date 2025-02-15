set -e

train_file=${train_file:-""}
validation_file=${validation_file:-""}
model_name_or_path=${model_name_or_path:-""}
tokenizer_path=${tokenizer_path:-""}
batch_size=${batch_size:-""}
update_freq=${update_freq:-""}
output_dir=${output_dir:-""}


master_port=${master_port:-"2224"}

learning_rate=${learning_rate:-"1e-5"}
num_train_epochs=${num_train_epochs:-"3"}
max_train_steps=${max_train_steps:-""}

devices=${devices:-""}

ds_config=${ds_config:-"configs/stage3.json"}
use_peft=${use_peft:-""}

is_seq2seq=${is_seq2seq:-""}

while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        # echo $1 $2 // Optional to see the parameter:value result
    fi
    shift
done

if [[ $use_peft == "1" ]];then
    peft_args="--use_peft"
else
    peft_args=""
fi

if [[ $tokenizer_path == "" ]];
then
    tokenizer_path=$model_name_or_path
fi

echo $train_file
deepspeed --master_port $master_port --include="localhost:${devices}" src/deepspeed_train.py \
    --train_file $train_file \
    --fp16 \
    --do_train --remove_unused_columns False --group_by_length\
    --model_name_or_path $model_name_or_path --tokenizer_path $tokenizer_path\
    --per_device_train_batch_size $batch_size --per_device_eval_batch_size $batch_size \
    --learning_rate $learning_rate --num_train_epochs $num_train_epochs --logging_steps 50\
    --gradient_accumulation_steps $update_freq \
    --lr_scheduler_type "cosine" --warmup_ratio 0.03 \
    --output_dir $output_dir --seed 42 \
    --report_to none \
    --save_strategy epoch $peft_args \
    --weight_decay 0. \
    --deepspeed $ds_config
