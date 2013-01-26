#!/bin/bash

########################################################################
# USAGE
########################################################################

# Functions starting with 'test' will be automatically evaluated.
#
# 1. Write test cases
#
#     :
#     testEcho() {
#         assertEqual "$(echo foo)" "foo"
#         assertReturn "$(echo foo)" 0
#     }
#     :
#
# 2. Include this script at the end of your test script
#
#    :
#    source $(dirname $0)/bashunit.bash
#    # eof
#
# 3. Run test suite
#
#    $ ./test_example
#    testEcho:4:Passed
#    testEcho:5:Passed
#    Done. 2 passed. 0 failed. 0 skipped.
#
# The return code is equal to the amount of failed testcases.
#
# Options can be given to the test script:
#
# $ bash ./bashunit.bash
# Usage: <testscript> [options...]
#
# Options:
#   -v, --verbose  Print exptected and provided values
#   -s, --summary  Only print summary omitting individual test results
#   -q, --quiet    Do not print anything to standard output
#   -h, --help     Show usage screen

########################################################################
# DEPENDENCIES
########################################################################

# * Bash (BASH_LINENO)
# * Shell colours

########################################################################
# API
########################################################################

# * assertEqual($1, $2)
#     $1: Output
#     $2: Expected
#
#     Assert that a given output string is equal to an expected string.

# * assertNotEqual($1, $2)
#     $1: Output
#     $2: Expected
#
#     Assert that a given output string is not equal to an expected
#     string.

# * assertStartsWith($1, $2)
#     $1: Output
#     $2: Expected
#
#     Assert that a given output string starts with an expected string.

# * assertReturn($1, $2)
#     $1: Output
#     $2: Expected
#     $?: Provided
#
#     Assert that the last command's return code is equal to an expected
#     integer.

# * assertNotReturn($1, $2)
#     $1: Output
#     $2: Expected
#     $?: Provided
#
#     Assert that the last command's return code is not equal to an
#     expected integer.

# * skip()
#
#     Skip the current test case.

########################################################################
# GLOBALS
########################################################################

verbose=2

bashunit_passed=0
bashunit_failed=0
bashunit_skipped=0

########################################################################
# ASSERT FUNCTIONS
########################################################################

# $1: Output
# $2: Expected
assertEqual() {
    echo $1 | grep -E "^$2$" > /dev/null
    if [ $? -eq 0 ] ; then _passed ; else _failed "$1" "$2" ; fi
}

# $1: Output
# $2: Expected
assertNotEqual() {
    echo $1 | grep -E "^$2$" > /dev/null
    if [ $? -ne 0 ] ; then _passed ; else _failed "$1" "$2" ; fi
}

# $1: Output
# $2: Expected
assertStartsWith() {
    echo $1 | grep -E "^$2" > /dev/null
    if [ $? -eq 0 ] ; then _passed ; else _failed "$1" "$2" ; fi
}

# $1: Output
# $2: Expected
# $?: Provided
assertReturn() {
    local code=$?
    if [ $code -eq $2 ] ; then _passed ; else _failed "$code" "$2" ; fi
}

# $1: Output
# $2: Expected
# $?: Provided
assertNotReturn() {
    local code=$?
    if [ $code -ne $2 ] ; then _passed ; else _failed "$code" "$2" ; fi
}

skip() {
    _skipped
}

_failed() {
    bashunit_failed=$((bashunit_failed+1))

    local tc=${FUNCNAME[2]}
    local line=${BASH_LINENO[1]}
    if [ $verbose -ge 2 ] ; then
        echo -e "\033[37;1m$tc\033[0m:$line:\033[31mFailed\033[0m"
    fi
    if [ $verbose -eq 3 ] ; then
        echo -e "\033[31mExpected\033[0m: $2"
        echo -e "\033[31mProvided\033[0m: $1"
    fi
}

_passed() {
    bashunit_passed=$((bashunit_passed+1))

    local tc=${FUNCNAME[2]}
    local line=${BASH_LINENO[1]}
    if [ $verbose -ge 2 ] ; then
        echo -e "\033[37;1m$tc\033[0m:$line:\033[32mPassed\033[0m"
    fi
}

_skipped() {
    bashunit_skipped=$((bashunit_skipped+1))

    local tc=${FUNCNAME[2]}
    local line=${BASH_LINENO[1]}
    if [ $verbose -ge 2 ] ; then
        echo -e "\033[37;1m$tc\033[0m:$line:\033[33mSkipped\033[0m"
    fi
}

########################################################################
# RUN
########################################################################

usage() {
    echo "Usage: <testscript> [options...]"
    echo
    echo "Options:"
    echo "  -v, --verbose  Print exptected and provided values"
    echo "  -s, --summary  Only print summary omitting individual test results"
    echo "  -q, --quiet    Do not print anything to standard output"
    echo "  -h, --help     Show usage screen"
}

runTests() {
    local test_pattern="test[a-zA-Z0-9_]\+"
    local testcases=$(grep "^ *\(function \)*$test_pattern *\\(\\)" $0 | \
        grep -o $test_pattern)

    if [ ! "${testcases[*]}" ] ; then
        usage
        exit 0
    fi

    for tc in $testcases ; do $tc ; done

    if [ $verbose -ge 1 ] ; then
        echo "Done. $bashunit_passed passed." \
             "$bashunit_failed failed." \
             "$bashunit_skipped skipped."
    fi
    exit $bashunit_failed
}

# Arguments
while [ $# -gt 0 ]; do
    arg=$1; shift
    case $arg in
        "-v"|"--verbose") verbose=3;;
        "-s"|"--summary") verbose=1;;
        "-q"|"--quiet")   verbose=0;;
        "-h"|"--help")    usage; exit 0;;
        *) shift;;
    esac
done

runTests
