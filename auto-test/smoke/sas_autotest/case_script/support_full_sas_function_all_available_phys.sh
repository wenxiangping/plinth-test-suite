#!/bin/bash




# cycle all proximal phy switchec, query whether there is an event.
# IN :N/A
# OUT:N/A
function cycle_devmem_all_switch_phy()
{
    Test_Case_Title="cycle_devmem_all_switch_phy"

    init_disk_num=`fdisk -l | grep /dev/sd | wc -l`
    for i in `seq ${LOOP_PHY_COUNT}`
    do
        # clear the contents of the ring buffer.
        time dmesg -c > /dev/null

        phy_ops close all
        sleep 2
        phydown_count=`dmesg | grep 'phydown' | wc -l`
        if [ ${phydown_count} -eq 0 ]
        then
            MESSAGE="FAIL\tclose all proximal phy, did not produce out event." && echo ${MESSAGE} && return 1
        fi

        phy_ops open all
        sleep 10
        phyup_count=`dmesg | grep 'phyup' | wc -l`
        if [ ${phyup_count} -eq 0 ]
        then
            MESSAGE="FAIL\topen all proximal phy, did not produce in event." && echo ${MESSAGE} && return 1
        fi
        sleep 10
    done

    echo "Sleep 10s to wait for disk recover ...."
    sleep 10
    end_disk_num=`fdisk -l | grep /dev/sd | wc -l`
    if [ ${init_disk_num} -ne ${end_disk_num} ]
    then
        MESSAGE="FAIL\tloop all proximal phy switches, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}

# recycle enable distal phy.
# IN : N/A
# OUT: N/A
function cycle_enable_phy()
{
    Test_Case_Title="cycle_link_reset_phy"

    beg_count=`fdisk -l | grep /dev/sd | wc -l`
    for i in `seq ${RESET_PHY_COUNT}`
    do
        change_sas_phy_file 0 "enable"

        change_sas_phy_file 1 "enable"
    done
    end_count=`fdisk -l | grep /dev/sd | wc -l`

    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\trecycle enable distal phy, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}

# loop hard_reset distal phy.
# IN : N/A
# OUT: N/A
function cycle_hard_reset_phy()
{
    Test_Case_Title="cycle_hard_reset_phy"

    beg_count=`fdisk -l | grep /dev/sd | wc -l`
    for i in `seq ${RESET_PHY_COUNT}`
    do
        change_sas_phy_file 1 "hard_reset"
    done
    end_count=`fdisk -l | grep /dev/sd | wc -l`

    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\tloop hard_reset distal phy, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}

# loop link_reset distal phy.
# IN : N/A
# OUT: N/A
function cycle_link_reset_phy()
{
    Test_Case_Title="cycle_link_reset_phy"

    beg_count=`fdisk -l | grep /dev/sd | wc -l`
    for i in `seq ${RESET_PHY_COUNT}`
    do
        change_sas_phy_file 1 "link_reset"
    done
    end_count=`fdisk -l | grep /dev/sd | wc -l`

    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\tloop link_reset distal phy, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}


# disk running business, switch single proximal phy.
# IN :N/A
# OUT:N/A
function fio_devmem_single_switch_phy()
{
    Test_Case_Title="fio_devmem_single_switch_phy"

        beg_count=`fdisk -l | grep /dev/sd | wc -l`
    judgment_network_env
    if [ $? -eq 1 ]
    then
	sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
        ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &

        phy_ops close 0
        wait
        phy_ops open 0
	echo "sleep for 30s wait for disk recover from fault..."
	sleep 30
    else
        for i in `seq ${LOOP_PHY_COUNT}`
        do
	    sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
    	    ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &

            phy_ops close 0
            wait
            phy_ops open 0
	    echo "sleep for 120s wait for disk recover from fault..."
            sleep 30
        done
    fi

   
    end_count=`fdisk -l | grep /dev/sd | wc -l`
    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\tdisk running business, switch single proximal phy, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}

# disk running business, switch multiple proximal phy.
# IN :N/A
# OUT:N/A
function fio_devmem_multiple_switch_phy()
{
    Test_Case_Title="fio_devmem_multiple_phy_switch"

        beg_count=`fdisk -l | grep /dev/sd | wc -l`
    judgment_network_env
    if [ $? -eq 1 ]
    then
	sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
        ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &
        phy_ops close 0
        phy_ops close 1
        phy_ops close 2
        wait
        phy_ops open 0
        phy_ops open 1
        phy_ops open 2
	
	echo "sleep for 90s wait for disk recover from error..."
	sleep 90
    else
        for i in `seq ${LOOP_PHY_COUNT}`
        do
            sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
    	    ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &

            phy_ops close 0
            phy_ops close 1
            phy_ops close 2
            phy_ops close 3
            phy_ops close 4
            phy_ops close 5
            wait

            phy_ops open 0
            phy_ops open 1
            phy_ops open 2
            phy_ops open 3
            phy_ops open 4
            phy_ops open 5
            echo "sleep for 120s wait for disk recover from error..."
	    sleep 120
        done
    fi
    end_count=`fdisk -l | grep /dev/sd | wc -l`
    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\tdisk running business, switch multiple proximal phy, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}
# when fio runs the business, polls the swtich proximal phy.
# IN :N/A
# OUT:N/A
function fio_devmem_polling_switch_phy()
{
    Test_Case_Title="fio_devmem_polling_switch_phy"

    #Judge the current environment, directly connected environment or expander environment.
    judgment_network_env
    if [ $? -ne 0 ]
    then
        MESSAGE="BLOCK\tthe current environment is direct connection network, do not execute test case."
        echo ${MESSAGE}
        return 0
    fi

    beg_count=`fdisk -l | grep /dev/sd | wc -l`
    for i in `seq ${LOOP_PHY_COUNT}`
    do
        for phy in ${PHY_ADDR_VALUE[@]}
        do
     	    sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
    	    ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &

            ${DEVMEM} ${phy} w 0x6
            wait
            ${DEVMEM} ${phy} w 0x7
            sleep 30

            echo "sleep for 30s wait for disk recover from error..."
        done
    done

    end_count=`fdisk -l | grep /dev/sd | wc -l`
    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\tdisk running business, loop switch proximal phy, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}

# switch all near-end phys while running the business.
# IN :N/A
# OUT:N/A
function fio_devmem_all_switch_phy()
{
    Test_Case_Title="fio_devmem_all_switch_phy"

    beg_count=`fdisk -l | grep /dev/sd | wc -l`
    #Judge the current environment, directly connected environment or expander environment.
    judgment_network_env
    if [ $? -ne 0 ]
    then
        MESSAGE="BLOCK\tthe current environment is direct connection network, do not execute test case."
        echo ${MESSAGE}
        return 0
    fi
    sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
    type=$(echo ${TEST_CASE_TITLE} | awk -F "_" '{print $1}')
    if [ $type == "single" ];then
        count=1
    elif [ $type == "cycle" ];then
        count=${RESET_PHY_COUNT}
    fi
    ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &
    for i in `seq ${count}`
    do
        phy_ops close all
        sleep 5
        phy_ops open all
	sleep 120
        echo "sleep for 120s wait for disk recover from error..."
        end_count=`fdisk -l | grep /dev/sd | wc -l`
        if [ ${beg_count} -ne ${end_count} ]
        then
            MESSAGE="FAIL\tdisk running business, loop off all proximal phy, the number of disks is missing."
            echo ${MESSAGE}
            return 1
        fi
    done
    MESSAGE="PASS"
    echo ${MESSAGE}
}


# cycle all proximal phy switchec, query whether there is an event.
# IN :N/A
# OUT:N/A
function cycle_fio_enable_devmem_all_switch_phy()
{
    Test_Case_Title="cycle_fio_enable_devmem_all_switch_phy"
    beg_count=`fdisk -l | grep /dev/sd | wc -l`

    for i in `seq ${LOOP_PHY_COUNT}`
    do
        # clear the contents of the ring buffer.
        time dmesg -c > /dev/null

        sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
        ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &
        sleep 5
        phy_ops close all
        sleep 2
        phydown_count=`dmesg | grep 'phydown' | wc -l`
        if [ ${phydown_count} -eq 0 ]
        then
            MESSAGE="FAIL\tclose all proximal phy, did not produce out event." && echo ${MESSAGE} && return 1
        fi

        phy_ops open all
        sleep 120
        phyup_count=`dmesg | grep 'phyup' | wc -l`
        if [ ${phyup_count} -eq 0 ]
        then
            MESSAGE="FAIL\topen all proximal phy, did not produce in event." && echo ${MESSAGE} && return 1
        fi
        sleep 5
        change_sas_phy_file 0 "enable"

        change_sas_phy_file 1 "enable"
    done

    sleep 5
    end_count=`fdisk -l | grep /dev/sd | wc -l`
    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\tloop all proximal phy switches, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}


# disk running business, switch multiple proximal phy.
# IN :N/A
# OUT:N/A
function cycle_fio_devmem_multiple_switch_phy()
{
    Test_Case_Title="cycle_fio_devmem_multiple_phy_switch"
    sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
    for i in `seq ${RESET_PHY_COUNT}`
    do
    ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &

    beg_count=`fdisk -l | grep /dev/sd | wc -l`
    judgment_network_env
    if [ $? -eq 1 ]
    then
        phy_ops close 0
        phy_ops close 1
        phy_ops close 2
        sleep 2
        phy_ops open 0
        phy_ops open 1
        phy_ops open 2
	sleep 120
        echo "sleep for 120s wait for disk recover from error..."
    else
        for i in `seq ${LOOP_PHY_COUNT}`
        do
            phy_ops close 0
            phy_ops close 1
            phy_ops close 2
            phy_ops close 3
            phy_ops close 4
            phy_ops close 5
            sleep 2

            phy_ops open 0
            phy_ops open 1
            phy_ops open 2
            phy_ops open 3
            phy_ops open 4
            phy_ops open 5
            sleep 120
	
            echo "sleep for 120s wait for disk recover from error..."
        done
    fi

    wait
    end_count=`fdisk -l | grep /dev/sd | wc -l`
    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\tdisk running business, switch multiple proximal phy, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    done
    MESSAGE="PASS"
    echo ${MESSAGE}
}



# switch all near-end phys while running the business.
# IN :N/A
# OUT:N/A
function devmem_all_switch_phy()
{
    Test_Case_Title="devmem_all_switch_phy"

    #Judge the current environment, directly connected environment or expander environment.
    judgment_network_env
    if [ $? -ne 0 ]
    then
        MESSAGE="BLOCK\tthe current environment is direct connection network, do not execute test case."
        echo ${MESSAGE}
        return 0
    fi

    beg_count=`fdisk -l | grep /dev/sd | wc -l`
    sed -i "{s/^runtime=.*/runtime=${LOOP_PHY_TIME}/g;}" ${FIO_CONFIG_PATH}/fio.conf
    ${SAS_TOP_DIR}/../${COMMON_TOOL_PATH}/fio ${FIO_CONFIG_PATH}/fio.conf &
    change_sas_phy_file 0 "enable"
    sleep 5
    change_sas_phy_file 1 "enable"

    # wait for all disks to be enabled.
    sleep 60
    end_count=`fdisk -l | grep /dev/sd | wc -l`
    if [ ${beg_count} -ne ${end_count} ]
    then
        MESSAGE="FAIL\tdisk running business, loop off all proximal phy, the number of disks is missing."
        echo ${MESSAGE}
        return 1
    fi
    MESSAGE="PASS"
    echo ${MESSAGE}
}

function main()
{
    #Get system disk partition information.
    fio_config

    # call the implementation of the automation use cases
    test_case_function_run
}

main
