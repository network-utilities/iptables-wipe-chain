#!/usr/bin/env bash


## This function is intended to clean up rules between IP or interface changes
iptables_wipe_chain(){    ## iptables_wipe_chain <chain>
    local _chain_name="${1:?Parameter_Error: ${FUNCNAME[0]} not provided a chain name}"

    local _broken='0'
    local _msg=''

    while read -r _rule; do
        case "${_rule}" in
            '-N'*|'-A'*)
                local _new_rule=($(sed 's@-N @-X @; s@-A @-D @' <<<"${_rule}"))
                iptables "${_new_rule[@]}" 2>/dev/null || _broken="${?}"
                if ((_broken)); then
                    _msg="cannot apply ${_new_rule[*]}"
                    break
                fi
            ;;
            *)
                _msg="did not understand ${_rule}"
                _broken='1'
                break
            ;;
        esac
    done <<<"$(iptables -S | grep -E -- "-N ${_chain_name}$|-A ${_chain_name} |-j ${_chain_name}$" | tac)"

    if [ -n "${_msg}" ]; then
        printf '%s %s\n' "${FUNCNAME[0]}" "${_msg}" >&2
    fi

    if ((_broken)); then
        return "${_broken}"
    fi
}
