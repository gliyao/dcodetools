#!/bin/bash

# parameters
prefix=$5
scheme=$1
profile="$prefix"/$2
app_name=$3
build_configuration=$4

function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}

function println()
{
	echo "$(tput setaf 220)\n $1 \n$(tput sgr 0)"
}

function setup_app_data()
{
	println "** $FUNCNAME **";

	project_dir=`pwd`

	archive_file="${scheme}.xcarchive"
	ipa_file="${scheme}.ipa"
	build_path="$prefix"/"build"
	archive_path="${build_path}/${archive_file}"
	export_ipa_path="${build_path}/${ipa_file}"

	build_error_file=build_errors.log

	echo "APP DATA{"
	echo "APP_NAME: ${app_name}"
	echo "SCHEME: ${scheme}"
	echo "BUILD_PATH: ${build_path}"
	echo "ARCHIVE_PATH: ${archive_path}"
	echo "EXPORT_IPA_PATH: ${export_ipa_path}"
	echo "}"
}

function remove_duplicate_code_sign_identity()
{
	println "** $FUNCNAME **";

	current_code_sign_identity=$1
	current_profile_name=$2
	current_dir=`pwd`
	cd ~/Library/MobileDevice/Provisioning\ Profiles/

	for ex_profile in *.mobileprovision 
		do

		ex_profile_data=$(security cms -D -i ${ex_profile})
		ex_profile_code_sign_identity=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<< $ex_profile_data)
	    ex_profile_name=$(/usr/libexec/PlistBuddy -c 'Print :Name' /dev/stdin <<< $ex_profile_data)

		# if code_sign_id && name equal previous
	    if [ $ex_profile_code_sign_identity == $current_code_sign_identity ]  && [ $ex_profile_name == $current_profile_name ]; then
		    echo "Remove previous profile: ${ex_profile}"
		    rm $ex_profile
		else
		   	echo "Not equal"
		fi;
	done

	cd $current_dir
}

function fetch_provisioning_profile()
{
	println "** $FUNCNAME **";

	profile_data=$(security cms -D -i ${profile})
	profile_name=$(/usr/libexec/PlistBuddy -c 'Print :Name' /dev/stdin <<< $profile_data)
	profile_uuid=$(/usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin <<< $profile_data)
	profile_app_id_prefix=$(/usr/libexec/PlistBuddy -c 'Print :ApplicationIdentifierPrefix:0' /dev/stdin <<< $profile_data)
	profile_code_sign_identity=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<< $profile_data)

	echo "PROFILE DATA{"
	echo "PROVISIONING_PROFILE: ${profile}"
	echo "PROFILE_NAME: ${profile_name}"
	echo "UUID: ${profile_uuid}"
	echo "CODE_SIGN_IDENTITY: ${profile_code_sign_identity}"
	echo "APP_ID_PREFIX: ${profile_app_id_prefix}"
	echo "}"

	# Remove current profiles
	remove_duplicate_code_sign_identity $profile_code_sign_identity $profile_name
	# Copy provisioning profile to OS provisioning profile

	echo $profile
	/bin/cp -rf $profile ~/Library/MobileDevice/Provisioning\ Profiles/$profile_uuid.mobileprovision
}

function clean_before_build()
{
	println "** $FUNCNAME **";

	xcodebuild -alltargets clean

	rm -rf ${build_path}
	rm $build_error_file
	mkdir ${build_path}
}

function build_and_archive()
{
	println "** $FUNCNAME **";

	# 可換成xctool
	xcodebuild \
		-configuration "$build_configuration" \
	 	-scheme "$scheme" \
	 	archive \
	 	PROVISIONING_PROFILE="$profile_uuid" \
	 	CODE_SIGN_IDENTITY="$profile_code_sign_identity" \
	 	-archivePath "$archive_path" \
	 	CONFIGURATION_BUILD_DIR="$build_path" \
	 	2>"$build_error_file" \

	# check build error
	errors=`grep -wc "The following build commands failed" ${build_error_file}`
	if [ "$errors" != "0" ]
	then
	    echo "$(tput setaf 1)BUILD FAILED. Error Log:"
	    cat ${build_error_file}
	    echo "$(tput sgr 0)"
	    exit 0
	else
		rm $build_error_file
	fi
}

function export_ipa()
{
	println "** $FUNCNAME **";

	# export ipa
	xcodebuild \
		-configuration "$build_configuration" \
		-exportArchive \
		-exportFormat IPA \
		-exportProvisioningProfile "$profile_name" \
		-archivePath "$archive_path" \
		-exportPath "$export_ipa_path" \

}

function remove_unused_files()
{
	println "** $FUNCNAME **";

	rm "./${build_path}/${scheme}.app"

	# Zip .dSYM to .dSYM.zip
	/usr/bin/zip -r "./${build_path}/${scheme}.app.dSYM.zip" "./${build_path}/${scheme}.app.dSYM"
	rm -rf ${archive_path}
}

# build flow
setup_app_data

fetch_provisioning_profile

clean_before_build

build_and_archive

export_ipa

remove_unused_files

