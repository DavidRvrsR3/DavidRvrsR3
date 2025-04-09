#!/bin/zsh --no-rcs

# Run locally stored script
#
#
# Copyright 2024 Root3 B.V. All rights reserved.
#
# This script is created to run scripts that are stored locally on the device in
# a secure manner.
#
# REQUIREMENTS: A locally stored script
#
# THE SOFTWARE IS PROVIDED BY ROOT3 B.V. "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL ROOT3 B.V. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# ------------------    edit the variables below this line    ------------------

# Enable debugging
#set -x

# Exit on errorß
set -e


# Major macOS version Assigned to this script? (required)
# Checks if assignment matches current OS Version to make sure 
# Device has up to date information in Intune before running CIS
# e.g. "15"
assignment="15"

# Shell script cis_parameters (optional) Default "--reset-all --check"
#cis_parameters="--reset-all --cfc" 

# Path to folder of script. Naming convention of script should be: 
# macos_MAJORVERSION_lvl2_cis_compliance Optional: 
# Default "/Library/Application Support/mSCP"
custom_script_path=""

# File Hash (Get the file hash using "shasum -a 256 /path/to/file") (optional)
# This prevents the script from running incase it has been tempered with.
sha256="dd2fb2e008d06148e2cf8b06a5e837cd1054a91193d034104ca2777e5864b03d" 

# ---------------------    do not edit below this line    ----------------------

# Discover OS version
major_version=$(sw_vers -productVersion | cut -d '.' -f 1)

# check if assignment matches current major version
if [[ ${assignment} != ${major_version} ]]; then
  echo "Mismatched assigment to current macOS version, exitting ..."
  exit 1
fi

# check if sha256 variable has been given
if [[ -z "${sha256}" ]]; then
  echo "No file hash given, continueing..."
  hash=0
else
  echo "file hash given, will verify authenticity..." 
  hash=1
fi

# check if script_path variable has been given
if [[ -z "${custom_script_path}" ]]; then
  echo "No custom script path given, using default"
  script_path="/Library/Application Support/mSCP/"$(ls /Library/Application\ Support/mSCP | grep "macos_${major_version}")
else
  script_path="$(ls -d ${custom_script_path} | grep "macos_${major_version}")"
fi

if [[ -z ${cis_parameters} ]]; then
  echo "no cis_parameters given using Audit"
  cis_parameters="--check --reset-all"
else
  echo running script with cis_parameters ${cis_parameters}
fi 

if [[ -f "${script_path}" ]]; then
  echo "Found script on device, continuing..."
  # Get the local file hash
  check=$(shasum -a 256 ${script_path} | awk '{print $1}')
else 
  echo "Script not found on device, exiting..."
  # Exit with error  
  exit 1
fi

# Check if correct Audit file is present on Device. 


#if hash is provided verify the script authenticity
if [[ ${hash} != 0 ]]; then
  # check local hash versus known hash to verify authenticity
  if [[ "${check}" == "${sha256}" ]]; then
    echo "Script is verified, running script..."
    verified=1
  fi
fi

# check if script can be run by checking prerequesites
if [[ ${hash} == 0 || ${verified} == 1 ]]; then   
  # ensure the script is excecutable.
  chmod a+x "${script_path}"
  # run script with paramaters.
  "${script_path}" "${=cis_parameters}"
  # Capture exit code
  exit_code=$?
  # Exit the script
  exit ${exit_code}
else
  echo "Script hashes do not match, exiting..." 
  # Exit with error
  exit 1
fi




