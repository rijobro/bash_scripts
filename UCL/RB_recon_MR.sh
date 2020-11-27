#!/bin/zsh

# -------------------------------------------------------- #
# function for converting DICOM to NIfTI
# -------------------------------------------------------- #
function dcm_2_nii {
	folder=$1
	output_filename=$2

	# Check directory contains a sub-directory called dicom
	if [[ ! -d $folder ]]; then
		echo Dicom folder missing
		exit 1
	fi

	echo "Converting all dicoms (*.IMA/*.dcm) in ${folder} to nifti..."

	dicoms=$(find "${folder}" \( -name "*.IMA" -or -name "*.dcm" \))
	if [[ "$dicoms" == "" ]]; then
		echo -e "DICOM to nifti failed. No DICOMs found."
		exit 1
	fi
	OUT=$(dcm2nii -g N -o . $(echo -e "${dicoms}"))
	success=$?
	echo -e "${OUT}"
	if [[ "$success" != 0 ]]; then
		echo -e "\nDicom to nifti failed"
		exit 1
	fi

	# move output file
	filename=${OUT##* }
	echo moving ${filename} to $output_filename
	mv "${filename}" $output_filename
}

# -------------------------------------------------------- #
# function starting Gadgetron if necessary
# -------------------------------------------------------- #
function start_gadgetron {
	if [[ "$(pgrep gadgetron)" == "" ]]; then
		echo Starting a gadgetron server
		open -a Terminal.app $(which gadgetron)
		sleep 3
	fi
}

# -------------------------------------------------------- #
# Vendor recon DICOM to NIfTI
# -------------------------------------------------------- #
dicom_as_nifti_filename="dicom_as_nifti.nii"
if [ -f "$dicom_as_nifti_filename" ]; then
	echo not converting dicom to nifti as file already exists: ${dicom_as_nifti_filename}
else
	dcm_2_nii dicom ${dicom_as_nifti_filename}
fi

# -------------------------------------------------------- #
# Raw MR .dat to .h5
# -------------------------------------------------------- #
raw_mr_dat=$(find . \( -name "meas*.dat" -or -name "2019*.dat" \))
raw_mr_h5=${raw_mr_dat:0:-4}.h5
if [ -f "$raw_mr_h5" ]; then
	echo not running siemens_to_ismrmrd as file already exists: ${raw_mr_h5}
else
	echo "siemens_to_ismrmrd -f ${raw_mr_dat} -o ${raw_mr_h5}"
	siemens_to_ismrmrd -f ${raw_mr_dat} -o ${raw_mr_h5}
fi

# -------------------------------------------------------- #
#                                                          #
#                           SIRF                           #
#                                                          #
# -------------------------------------------------------- #
# 1. Recon with SIRF
# 2. Use SIRF to convert to NIfTI
# 3. Use Gadgetron to write to DICOM
# 4. Convert to NIfTI

SIRF_recon_no_extension=SIRF_recon
SIRF_recon_h5=${SIRF_recon_no_extension}.h5
SIRF_recon_nii=${SIRF_recon_no_extension}.nii
SIRF_recon_dcm_folder=SIRF_dicom
SIRF_recon_nii_via_dicom=${SIRF_recon_no_extension}_via_dicom.nii

if [ -f "${SIRF_recon_nii}" ]; then
	echo not running reconstruction as file already exists: ${SIRF_recon_nii}
else
	# Run gadgetron if not already running
	start_gadgetron
	
	# 1. Recon with SIRF
	path_to_recon="${SIRF_PATH}/examples/Python/MR/Gadgetron/fully_sampled_recon_single_chain.py"
	echo $SIRF_PYTHON_EXECUTABLE "${path_to_recon}" -f ${raw_mr_h5} -p . -o ${SIRF_recon_no_extension} --type_to_save=mag -a GenericReconCartesianFFTGadget
	$SIRF_PYTHON_EXECUTABLE "${path_to_recon}" -f ${raw_mr_h5} -p . -o ${SIRF_recon_no_extension} --type_to_save=mag -a GenericReconCartesianFFTGadget
	if [[ "$?" != "0" ]]; then exit 1; fi

	# 2. Use SIRF to convert to NIfTI
	sirf_convert_image_type ${SIRF_recon_nii} nii ${SIRF_recon_h5} Gadgetron

	# 3. Use Gadgetron to write to DICOM
	# if [ -d "$SIRF_recon_dcm_folder" ]; then rm -Rf $SIRF_recon_dcm_folder; fi
	# mkdir $SIRF_recon_dcm_folder
	# $SIRF_PYTHON_EXECUTABLE -c 'import sys; import sirf.Gadgetron as g; a=g.ImageData(sys.argv[1]); a*=10000000; a.write(sys.argv[2],"dcm")' ${SIRF_recon_h5} ${SIRF_recon_dcm_folder}/sirf_recon
	
	# 4. Convert to NIfTI
	# dcm_2_nii $SIRF_recon_dcm_folder ${SIRF_recon_nii_via_dicom}
fi

# # -------------------------------------------------------- #
# #                                                          #
# #                      Gadgetron to H5                     #
# #                                                          #
# # -------------------------------------------------------- #

# # 1. Recon directly to DICOM
# # 2. Convert to NIfTI
# gadgetron_recon_h5=gadgetron_recon.h5
# if [ -f "${gadgetron_recon_h5}" ]; then
# 	echo not performing gadgetron 2 dicom reconstruction as file already exists: ${gadgetron_recon_h5}
# else
# 	# Run gadgetron if not already running
# 	start_gadgetron

# 	# 1. Recon with Gadgetron to DICOM
# 	gadgetron_ismrmrd_client -f ${raw_mr_h5} -c default.xml -o ${gadgetron_recon_h5}
# fi


# # -------------------------------------------------------- #
# #                                                          #
# #                    Gadgetron via DICOM                   #
# #                                                          #
# # -------------------------------------------------------- #

# # 1. Recon directly to DICOM
# # 2. Convert to NIfTI

# gadgetron_dicom_folder=gadgetron_recon
# gadgetron_recon_nii=gadgetron_recon.nii
# if [ -f "${gadgetron_recon_nii}" ]; then
# 	echo not performing gadgetron 2 dicom reconstruction as file already exists: ${gadgetron_recon_nii}
# else
# 	# Run gadgetron if not already running
# 	start_gadgetron

# 	# 1. Recon with Gadgetron to DICOM
# 	gadgetron_ismrmrd_client -f ${raw_mr_h5} -c dicom_RB.xml -G gadgetron_dcm 

# 	# 2. Convert to NIfTI
# 	if [ -d "$gadgetron_dicom_folder" ]; then rm -Rf $gadgetron_dicom_folder; fi
# 	mkdir $gadgetron_dicom_folder
# 	mv gadgetron_dcm*.dcm "${gadgetron_dicom_folder}"
# 	dcm_2_nii $gadgetron_dicom_folder ${gadgetron_recon_nii}
# fi

# # -------------------------------------------------------- #
# #                                                          #
# #                  Register SIRF to vendor                 #
# #                                                          #
# # -------------------------------------------------------- #
# registered_im="register_SIRF_to_vendor.nii"
# transformation_matrix="register_SIRF_to_vendor.txt"
# # if [ -f "${transformation_matrix}" ]; then
# 	# echo not performing gadgetron 2 dicom reconstruction as file already exists: ${transformation_matrix}
# # else
	# reg_aladin -ref ${dicom_as_nifti_filename} -flo ${SIRF_recon_nii} -rigOnly -aff ${transformation_matrix} -res ${registered_im}
# # fi