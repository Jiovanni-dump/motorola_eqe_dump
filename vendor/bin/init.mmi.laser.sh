#!/vendor/bin/sh
scriptname=${0##*/}
dbg_on=1
debug()
{
	[ $dbg_on ] && echo "Debug: $*"
}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

error_and_leave()
{
	local err_msg
	local err_code=$1
	case $err_code in
		1)  err_msg="Error: No response";;
		2)  err_msg="Error: Skip to overwrite xtalk and offset data in factory mode";;
		3)  err_msg="Error: Calibration data file $2 does not exist";;
		4)  err_msg="Error: Calibration sysfs path $2 does not show up";;
	esac
	notice "$err_msg"
	exit $err_code
}

# Change laser sysfs file ownership
laser_class_path=/sys/devices/virtual/laser
laser_product_string=$(ls $laser_class_path)
laser_product_path=$laser_class_path/$laser_product_string
for laser_file in $laser_product_path/*; do
	if [ -f "$laser_file" ]; then
		chown root:root $laser_file
	fi
done

if [ ! -d $laser_product_path ]; then
	error_and_leave 4 "'$laser_product_path'"
fi

# Change laser input sysfs file ownership
laser_input_root=/sys/devices/virtual/input
laser_input_list=$(ls $laser_input_root)
for laser_input_dir in $laser_input_list; do
	if [ -f "$laser_input_root/$laser_input_dir/calibration_data" ]; then
		laser_calib_file=$laser_input_root/$laser_input_dir/calibration_data
	fi
	if [ -f "$laser_input_root/$laser_input_dir/xtalk" ]; then
		laser_xtalk_file=$laser_input_root/$laser_input_dir/xtalk
	fi
	if [ -f "$laser_input_root/$laser_input_dir/offset" ]; then
		laser_offset_file=$laser_input_root/$laser_input_dir/offset
	fi
done

if [ -z "$laser_calib_file" ]; then
	laser_calib_file=$laser_product_path/calibration_data
fi
if [ -z "$laser_xtalk_file" ]; then
	laser_xtalk_file=$laser_product_path/xtalk
fi
if [ -z "$laser_offset_file" ]; then
	laser_offset_file=$laser_product_path/offset
fi

# Load calibration data
calib_data_file=/mnt/vendor/persist/camera/vl53l1_cali.bin
if [ -f $calib_data_file ]; then
	if [ -z "$laser_calib_file" ]; then
		error_and_leave 4 "'$laser_calib_file'"
	else
		cat $calib_data_file > $laser_calib_file
		notice "laser calibration data updating complete"
	fi
else
	notice "laser calib_data_file '$calib_data_file' does not exist"
fi

bootmode=$(getprop ro.bootmode 2> /dev/null)
if [ $bootmode != "mot-factory" ]; then
	# Enable smudge mode
	echo 1 > $laser_product_path/smudge_correction_mode
	notice "laser smudge mode enabled"
else
	# Disable smudge mode
	echo 0 > $laser_product_path/smudge_correction_mode
	notice "factory-mode boot, disable laser smudge mode"
fi
