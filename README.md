# Description
        Ater, explore baseband AT command interfaces

# Requirements
        adb
        an android system that exposes an AT command interface at some serial device
        AT_serial set in your configuration file, ater.conf

# Synopsis
		 --at|at-command=s
		 --s|adb-shell-command=s
		 --serial|adb-serial-device=s
		 --stats|statistics
		 --atdev|at-device=s
		 --help|?
		 --verbose
		 --lv|learn-verbs
		 --lso|learn-set-objects
		 --lao|learn-all-objects|set-objects-and-options
		 --laocff|learn-all-objects-commands-from-file=s
		 --who
		 --was|who-android-system
		 --wsr|who-android-service=s
		 --wpn|who-android-pid-by-name=s
		 --wpi|who-android-pid=i
		 --debug|debug-ater
		 --time
		 --doc|documentation
		 --rate|throttle-factor=i
		 --grol|get-rid-of-lock
		 --printmd|print-md
		 --tc|test-commands-from-file-or-pipe=s
		 --rc|run-commands-from-file-or-pipe=s
		 --rwt|run-rc-with-chk-trap
		 --rwp|run-rc-with-ping
		 --findresets|rc-find-commands-that-reset-trap
		 --testping|test-ping-command
		 --ping
		 --chk|check-trap
		 --settrap
		 --su|su-instead-of-adb-root
		 --mcc=s
		 --mccmnc=s
		 --mccgrep=s
		 --ops

        that is; ater -h

# Options, Examples
      --help|h|?
        list implemented options
        list configuration files

      --at=s
        send an AT+COM command
        s:<+COM>
        e.g. ater -at +CGMI
        special characters in commands should be escaped
        e.g. for AT$QCPWRDN       ater -at \$QCPWRDN
        e.g. for AT+CLCK="SC",2   ater -at +CLCK=\"SC\",2

      --serial=s
        select Android device
        s:adb_android_device_serial_number

      --at-serial|as=s
        select AT char device
        s:<AT CLI serial device>
        not implemented, change it in config

      --stat|statistics
        print per run statistics for
          executed AT commands
          received OKs,
          errors, trap_triggers, ...

      --learn-verbs|lv
        try to learn CLI verbs
        log effort to files
        it learns through AT commands used to list AT commands
        the list of commands that list commands could be set at LEARN_VERBS_SEED in the configuration file

      --learn-set-objects|lso
        implies, input from learn-verbs|lv
        try to learn AT CLI set objects
        log effort to files

      --learn-all-objects|lao
        implies, input from learn-verbs|lv
        try to learn all listed AT CLI objects
        log effort to files

      --laocff|learn-all-objects-commands-from-file=s
        try to learn all listed AT CLI objects
        log effort to files

      --verbose

      --rate|throttle-factor=i
        set in milliseconds the wait time in between AT commands,
        and set in milliseconds the wait time in between an AT command and an AT response read.
        The default wait time in between commands is 25 milliseconds,
        the default wait time in between commands and responses is 25 milliseconds,
        therefore, the default throttle-factor is 50 milliseconds.
        Throttle factor less than 1ms will be set 1ms..

      --documentation
        print Ater POD

      --printMD
        print Ater Readme.MD

      --wait-for-device|w=s
        wait for android device, s:android_device_serial_number
        not implemented, for now you can wait using the wait-for-device.sh wrapper

      --grol|get-rid-of-lock
        remove soft lock and kill adb fetcher
        that or ah_get_rid_of_lock

      --who
        who android_device,
        who baseband_processor
        who rild

      --debug
        print Ater debug information

      --time
        time Ater run

      --chk|check-trap
        exits with 0 if the trap value is not changed
        configure TRAP_SET_COMMAND, TRAP_QUERY_COMMAND, TRAP_VALUE in the config file

      --ping
        exits with 0 if PONG_RESPONSE is seen after a PING_COMMAND command
        configure PONG_RESPONSE, PING_COMMAND in the config file

      --tc|test-commands-from-file-or-pipe=s
        test (ATCOM, ATCOM?, ATCOM=?) a list of commands
        e.g. ater -tc=./at-commands/totry --throttle-factor 300
        blacklisted commands set in the configuration file are excluded

      --rc|run-commands-from-file-or-pipe=s
        run a list of commands
        or drive fuzzing campaigns from files against the AT CLI itself
        e.g. ater -rc=./at-commands/torun
        blacklisted commands set in the configuration file are not excluded,
        just comment out with '#' the commands you don't want to run

        --rwp|run-rc-with-ping
            send the ping command set at your config
            in between commands

        --rwt|run-rc-with-chk-trap
            check the trap set at your config
            in between commands
            exit on trigger unless --findresets

        --findresets|rc-find-commands-that-reset-trap
            find at commands that reset the trap
            it does not exit on trap trigger

        Examples

        run an AT command
        ./ater -at \$CCLK?

        scan for cellular networks
        ./ater -at +COPS=? --throttle-factor=20000

        run a list of commands
        ./ater -rc=./at-commands/read-messages

        run the same command and print AT command statistics
        ./ater -rc=./at-commands/read-messages -stats

        run a list of AT commands  with a ping in between commands, exit badly, 3, if the AT device does not pong
        ./ater -rc=./at-commands/test -rwp  -stats

        however, if you don't add a large enough throttle-factor (default throttle-factor is 25ms) on
        ./ater -rc=./at-commands/tofail -rwp -stats
        $ echo $?
        0

        the ping command will pong before the device shutdown ($QCPWRDN)

        so, add a large throttle-factor ie wait time in between commands
        ./ater -rc=./at-commands/tofail -rwp -stats -throttle-factor=5000
        Ater:main::atadb shell "echo 'AT+CGMI\r' > /dev/smd8" 256
        Ater: main::test_commands: __dev__smd8 did not pong after $QCPWRDN
        $ echo $?
        3

        if you know of a good trap, you could try
        ./ater -rc=./at-commands/verbs.MSM8917C00B191.ater -rwt -stats

        find AT commands that trigger the trap ie change the trap value
        ./ater -rc=./at-commands/verbs.MSM8917C00B191.ater -rwt -findresets -stats

        test a list of commands from a file, that is run AT_COMMAND, AT_COMMAND?, AT_COMMMAND=? for each AT_COMMAND
        ./ater -tc=./at-commands/verbs.MSM8917C00B191.ater -stats

        test a list of commands from a pipe, that is run AT_COMMAND, AT_COMMAND?, AT_COMMMAND=? for each AT_COMMAND
        ./ater -tc './helpers.sh ah_look_for_HiSi_AT_commands|' -stats

        robust AT device ping
        source ./helpers.sh
        ah_wait -at -ping

        attempt to learn set objects/values for commands learned with LEARN_VERBS_SEED
       ./ater -lso -stats

        run AT_COMMAND, AT_COMMAND?, AT_COMMMAND=? for ~ commands learnded with LEARN_VERBS_SEED
        ./ater -lao -stats

        run AT_COMMAND, AT_COMMAND?, AT_COMMMAND=? for all commands from file
        ./ater -laocff=./at-commands/verbs.MSM8917C00B191.ater -stats

        run AT_COMMAND, AT_COMMAND?, AT_COMMMAND=? for all commands from pipe
        ./ater -laocff './helpers ah_look_for_HiSi_AT_commands|' -stats

        see the MS-SIM IMSI number
        /ater -at=+CIMI

        look up an mccmnc number
        ./ater -mccmnc 20201

        look up mobile operators in China
        ./ater -mccgrep china

        explore android system with serial device KVXBB17C01210608 ($ adb devices)
        ./ater -serial KVXBB17C01210608 -wa

# Origin
      g0, 2018

