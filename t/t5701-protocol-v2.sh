#!/bin/sh

test_description='test git wire-protocol version 2'

TEST_NO_CREATE_REPO=1

. ./test-lib.sh

# Test protocol v2 with 'file://' transport
#
test_expect_success 'create repo to be served by file:// transport' '
	git init file_parent &&
	test_commit -C file_parent one
'

test_expect_success 'list refs with file:// using protocol v2' '
	GIT_TRACE_PACKET=1 git -c protocol.version=2 \
		ls-remote --symref "file://$(pwd)/file_parent" >actual 2>log &&

	# Server responded using protocol v2
	cat log &&
	grep "git< version 2" log &&

	git ls-remote --symref "file://$(pwd)/file_parent" >expect &&
	test_cmp actual expect
'

test_done
