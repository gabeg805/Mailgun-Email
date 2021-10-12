#!/bin/bash

##
# Name of the project.
##
PROJECT=$(basename "${0}")

##
# File containing the key for the email API.
##
EMAIL_API_KEY_FILE="${HOME}/.api/mailgun/key"

##
# File containing the domain name for the email API.
##
EMAIL_API_DOMAIN_FILE="${HOME}/.api/mailgun/domain"

##
# Email API key.
##
EMAIL_API_KEY=

##
# Email API domain.
##
EMAIL_API_DOMAIN=

##
# Body of the message.
##
MSG_BODY=

##
# Name of the person the email is sent from.
##
MSG_FROM=

##
# Subject of the message.
##
MSG_SUBJECT=

##
# Email address to send the message to.
##
MSG_TO=

##
# Exit status when an email API file was not found.
##
EXIT_EMAIL_FILE_NOT_FOUND=10

##
# Exit status when a TO email address was not specified.
##
EXIT_EMAIL_INVALID_TO_ADDR=11

##
# Send an email
##
main()
{
	# No arguments. Print usage
	if [ $# -eq 0 ]
	then
		usage
		return 0
	fi

	# Options
	local short="hf:t:s:b:"
	local long="help,from:,to:,subject:,body:"
	local args=

	# Parse options
	args=$(getopt -o "${short}" --long "${long}" --name "${PROJECT}" -- "${@}")
	if [ $? -ne 0 ]
	then
		usage
		return 1
	fi
	eval set -- "${args}"

	while true
	do
		case "${1}" in
			-h|--help)
				usage
				return 0
				;;

			-b|--body)
				shift
				MSG_BODY="${1}"
				;;

			-f|--from)
				shift
				MSG_FROM="${1}"
				;;

			-s|--subject)
				shift
				MSG_SUBJECT="${1}"
				;;

			-t|--to)
				shift
				MSG_TO="${1}"
				;;

			*)
				break
				;;
		esac
		shift
	done

	# Make sure that a TO email address was specified
	if [ -z "${MSG_TO}" ]
	then
		echo "Error: No email address was specified to send a message to." 1>&2
		return ${EXIT_EMAIL_INVALID_TO_ADDR}
	fi

	# Send an email
	check_email_api_files
	set_email_api
	send_email
	return $?
}

##
# Print program usage.
##
usage()
{
	echo "Usage: ${PROJECT} [options]"
	echo 
	echo "Options:"
	echo "	  -h, --help"
	echo "		  Print program usage."
	echo 
	echo "	  -b, --body=<text>"
	echo "		  Body of the message."
	echo 
	echo "	  -f, --from=<name>"
	echo "		  Name of the person the email is sent from."
	echo 
	echo "	  -s, --subject=<text>"
	echo "		  Subject of the message."
	echo 
	echo "	  -t, --to=<email>"
	echo "		  Email address to send the message to."
}

##
# Check email API files.
##
check_email_api_files()
{
	# Email key file does not exist
	if [ ! -f "${EMAIL_API_KEY_FILE}" ]
	then
		echo "Error: Email API key file does not exist : ${EMAIL_API_KEY_FILE}" 1>&2
		exit ${EXIT_EMAIL_FILE_NOT_FOUND}
	fi

	# Email domain file does not exist
	if [ ! -f "${EMAIL_API_DOMAIN_FILE}" ]
	then
		echo "Error: Email API domain file does not exist : ${EMAIL_API_DOMAIN_FILE}" 1>&2
		exit ${EXIT_EMAIL_FILE_NOT_FOUND}
	fi
}

##
# Send an email.
##
send_email()
{
	# Set the FROM line if not specified
	if [ -z "${MSG_FROM}" ]
	then
		MSG_FROM="Gabe G <gabe@${EMAIL_API_DOMAIN}>"
	fi

	# Send an email
	curl -s \
		--user "api:${EMAIL_API_KEY}" \
		"https://api.mailgun.net/v3/${EMAIL_API_DOMAIN}/messages" \
		-F from="${MSG_FROM}" \
		-F to="${MSG_TO}" \
		-F subject="${MSG_SUBJECT}" \
		-F text="${MSG_BODY}"
}

##
# Set the email API data.
##
set_email_api()
{
	# Get the API key to email
	EMAIL_API_KEY=$(cat "${EMAIL_API_KEY_FILE}")

	# Get the API domain for the email
	EMAIL_API_DOMAIN=$(cat "${EMAIL_API_DOMAIN_FILE}")
}

##
# Run script.
##
main "${@}"
